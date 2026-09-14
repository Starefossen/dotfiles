#!/usr/bin/env python3
"""preToolUse-port: en worktree eller klone rett i $HOME nektes.

Bakgrunnen er konkret. 14. september 2026 lå det 39 registrerte worktrees på
`~/projects/copilot/copilot`, de fleste som `~/np-<tema>`, pluss et titalls
kloner og skrapmapper. Til sammen rundt 20 GB, og disken sto på 97 %. Ingen
av dem ble laget av harnessets egen isolasjon, som legger worktrees under
øktas scratchpad. De ble laget av `git worktree add ~/np-foo` skrevet for
hånd, én økt av gangen, fordi ingenting sa nei.

Porten sier nei. Regelen er smal med vilje: bare foreldremappen teller, så
`~/np-foo` nektes mens `~/projects/cplt-laneA` og en sti under scratchpad går
gjennom. Den tvinger ikke fram en ny konvensjon, den stopper den ene plassen
som ikke har noen eier.

`permissionDecision: "deny"` framfor "ask", av samme grunn som slop-gate:
"ask" spør interaktivt, og oppførselen i `-p` er udokumentert. Begrunnelsen
når fram til modellen, og den sier hvor stien heller bør ligge, slik at
modellen kan skrive kommandoen om selv i stedet for å stå fast.

Kjente kanter, valgt og ikke oversett:

  * Dette er en snubletråd, ikke en mur. `cd ~ && git worktree add .`, en sti
    bygd av variabler, eller `$(echo ~)/np-foo` fanges ikke. Poenget er å
    stoppe vanen, ikke en motvillig agent.
  * Bare `worktree add` og `clone` med eksplisitt mål sjekkes. En `clone` uten
    målmappe arver cwd; den fanges bare når payloaden har `cwd`.
  * `~` og `$HOME` utvides, men ingen annen variabel. En sti som ikke lar seg
    tyde slipper gjennom, fordi en port med falske positive blir skrudd av.
  * Fail-open ved enhver parsefeil. En port som nekter alt er verre enn ingen.
"""

import json
import os
import shlex
import sys

HOME = os.path.realpath(os.path.expanduser("~"))

# Flagg som tar en verdi etter seg, og som derfor ikke er stien vi leter etter.
VALUE_FLAGS = {"-b", "-B", "--reason", "--orphan"}


def _expand(token, cwd):
    """~ og $HOME ut, absolutt sti inn. None når stien ikke lar seg tyde."""
    if "$" in token and "$HOME" not in token:
        return None  # en annen variabel: vi gjetter ikke
    token = token.replace("$HOME", HOME)
    token = os.path.expanduser(token)
    if not os.path.isabs(token):
        if not cwd:
            return None
        token = os.path.join(cwd, token)
    return os.path.realpath(token)


def _target(words, cwd):
    """Stien `git worktree add` eller `git clone` ville laget, eller None."""
    if not words or os.path.basename(words[0]) != "git":
        return None

    i = 1
    while i < len(words) and words[i] in ("-C", "-c"):
        i += 2  # `git -C <dir> ...`: hopp over flagget og verdien
    rest = words[i:]
    if not rest:
        return None

    if rest[0] == "worktree" and len(rest) > 1 and rest[1] == "add":
        args, skip = rest[2:], False
    elif rest[0] == "clone":
        args, skip = rest[1:], False
        positional = [a for a in args if not a.startswith("-")]
        # klone: url er første posisjonelle, målmappen den andre
        return _expand(positional[1], cwd) if len(positional) > 1 else None
    else:
        return None

    for arg in args:
        if skip:
            skip = False
            continue
        if arg in VALUE_FLAGS:
            skip = True
            continue
        if arg.startswith("-"):
            continue
        return _expand(arg, cwd)
    return None


def decide(payload):
    tool = payload.get("tool_input") or payload.get("toolArgs") or {}
    command = tool.get("command") or tool.get("script") or ""
    if "worktree" not in command and "clone" not in command:
        return None

    cwd = payload.get("cwd")
    try:
        words = shlex.split(command)
    except ValueError:
        return None  # ubalanserte anførselstegn: vi gjetter ikke

    # én kommandolinje kan holde flere kommandoer
    chunks, current = [], []
    for word in words:
        if word in ("&&", "||", ";", "|"):
            chunks.append(current)
            current = []
        else:
            current.append(word)
    chunks.append(current)

    for chunk in chunks:
        target = _target(chunk, cwd)
        if target and os.path.dirname(target) == HOME:
            return (
                f"Stien {target} ligger rett i hjemmemappen. Der samler "
                "worktrees og kloner seg opp uten at noe rydder dem: 14. "
                "september 2026 lå det 39 slike der, rundt 20 GB, på en disk "
                "med 3 % ledig.\n\n"
                "Legg den et sted som har en eier i stedet:\n"
                "  * under prosjektmappen, f.eks. ~/projects/<repo>-<tema>\n"
                "  * eller i øktas scratchpad, som ryddes automatisk\n\n"
                "Bruk `git worktree remove <sti>` for å fjerne en worktree: "
                "den nekter når det finnes ucommittet arbeid, og rydder "
                "registreringen i .git/worktrees. `rm -rf` gjør ingen av delene."
            )
    return None


def main():
    try:
        payload = json.loads(sys.stdin.read())
        reason = decide(payload) if isinstance(payload, dict) else None
    except Exception:
        reason = None  # fail-open

    if reason:
        json.dump(
            {
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                },
            },
            sys.stdout,
        )
    sys.exit(0)


# ─── Selvtest ────────────────────────────────────────────────────────────────
# Kjører skriptet som subprosess med ekte stdin, slik at JSON inn, JSON ut og
# exitkoden er dekket, ikke bare decide().

def _c(command, cwd=None):
    payload = {"tool_name": "Bash", "tool_input": {"command": command}}
    if cwd:
        payload["cwd"] = cwd
    return payload


def selftest():
    import subprocess

    cases = [
        ("nekter worktree rett i $HOME",
         _c("git worktree add ~/np-sweep -b fix/sweep"), True),
        ("nekter med absolutt sti",
         _c(f"git worktree add {HOME}/np-foo"), True),
        ("nekter med $HOME",
         _c("git worktree add $HOME/np-foo"), True),
        ("nekter bak &&",
         _c("cd /tmp && git worktree add ~/np-foo -b x"), True),
        ("nekter klone rett i $HOME",
         _c("git clone git@github.com:navikt/cplt.git ~/cplt-audit"), True),
        ("nekter relativ sti som havner i $HOME",
         _c("git worktree add ./np-foo", cwd=HOME), True),
        ("nekter med -C foran",
         _c("git -C /tmp/repo worktree add ~/np-foo"), True),

        ("slipper gjennom under ~/projects",
         _c("git worktree add ~/projects/cplt-laneE -b x"), False),
        ("slipper gjennom i scratchpad",
         _c("git worktree add /private/tmp/claude-504/abc/scratchpad/wt1"), False),
        ("slipper gjennom dypere i $HOME",
         _c("git worktree add ~/projects/copilot/wt-x"), False),
        ("rører ikke worktree list",
         _c("git worktree list"), False),
        ("rører ikke worktree remove",
         _c("git worktree remove ~/np-foo"), False),
        ("rører ikke vanlig commit",
         _c('git commit -m "fix: x"'), False),
        ("rører ikke klone uten mål",
         _c("git clone git@github.com:navikt/cplt.git", cwd="/tmp"), False),
        ("fail-open på ubalanserte anførselstegn",
         _c('git worktree add ~/np-foo "'), False),
    ]

    failed = 0
    for name, payload, should_deny in cases:
        proc = subprocess.run(
            [sys.executable, os.path.abspath(__file__)],
            input=json.dumps(payload), capture_output=True, text=True,
        )
        denied = False
        if proc.stdout.strip():
            denied = json.loads(proc.stdout).get("permissionDecision") == "deny"
        ok = denied == should_deny and proc.returncode == 0
        if not ok:
            failed += 1
        print(f"  {'ok  ' if ok else 'FEIL'}  {name}")

    print(f"\n{len(cases) - failed}/{len(cases)} passerte")
    return 1 if failed else 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        sys.exit(selftest())
    main()
