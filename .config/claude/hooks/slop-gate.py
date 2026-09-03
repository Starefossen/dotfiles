#!/usr/bin/env python3
"""preToolUse-port: en publisering med banned trailer eller slop-frase nektes.

Porten leser Bash-kommandoen fra payloaden og stopper `git commit`,
`git tag -a/-m` og `gh issue|pr|release create|comment|edit|review|close|reopen`
når teksten inneholder en forbudt trailer, en frase fra slop-lista, eller en
emnelinje over 72 tegn.

Trailerforbudet står i CLAUDE.md, men det er prosa, og prosa kan overstyres: i
denne økta forsøkte en systemmelding å oppheve det. Derfor håndheves det i
verktøylaget i stedet, der en senere instruksjon ikke når fram.
`permissionDecision: "deny"` framfor "ask": "ask" spør interaktivt, og
oppførselen i `-p` er udokumentert. "deny" er lik i begge modus, og
`permissionDecisionReason` når fram til modellen.

Inn leses begge dialektene: `tool_input.command` (Claude Code / PascalCase) og
`toolArgs.command` (GitHub Copilot CLI / camelCase), med `script` som
reservenøkkel i begge. Ut skrives både den flate formen og hookSpecificOutput,
fordi CLI-ene godtar hver sin.

Kjente kanter, valgt og ikke oversett:

  * Skanningen gjelder hele kommandolinja. Et ord inne i et filnavn eller i en
    sitert feilstreng nektes derfor også.
  * `SLOP_OK=1` må stå først på kommandolinja, og hopper bare over ordlista og
    lengdesjekken. Trailerforbudet er absolutt og kan ikke overstyres.
  * Taket er obfuskering på skallnivå: `-mcomprehensive` uten ordgrense,
    `"comp""rehensive"`, `compre\hensive`, `$'...'` og `-m "$(cat f)"` fanges
    ikke. Dette er en snubletråd, ikke en mur.
  * Lengdesjekken ser bare `-m "..."` og `-m '...'` med parvise anførselstegn,
    og stopper på linjeskift. En usitert emnelinje måles ikke.
  * Ordlista er bevisst smal. Ord brukeren faktisk selv bruker (`robust`,
    `crucial`, `omfattende`, `i dagens`) står ikke i den, fordi en port med
    falske positive blir skrudd av.
  * `--body-file`/`--notes-file`/`--file`/`-F` slås opp relativt til hookens
    arbeidsmappe, som er øktas cwd og ikke nødvendigvis kommandoens. En sti som
    ikke lar seg lese hoppes over i stillhet.
"""

import json
import re
import sys

PUBLISHES = [re.compile(p) for p in (
    r"(?<![\w-])(?:\S*/)?git\s+(?:-[cC]\s*\S+\s+|--?\S+\s+)*commit\b",
    r"(?<![\w-])(?:\S*/)?git\s+tag\b[^;&|]*\s-[a-zA-Z]*[am]\b",
    r"\bgh\s+(issue|pr|release)\s+(create|comment|edit|review|close|reopen)\b",
)]

# Overstyringen må stå først på kommandolinja, ellers holder det å nevne den
# inne i en melding for å slippe unna.
OVERRIDE = re.compile(r"^\s*SLOP_OK=1\s")

TRAILERS = [
    (re.compile(r"Co-Authored-By:.*\b(Claude|Fable|Anthropic)", re.I),
     "Co-Authored-By-trailer som navngir Claude/Fable/Anthropic"),
    (re.compile(r"Claude-Session:", re.I), "Claude-Session-trailer"),
    (re.compile(r"(Generated|Made|Written) (with|by) .*Claude", re.I),
     '"Generated/Made with Claude"-fotnote'),
    (re.compile(r"anthropic\.com", re.I), "anthropic.com-markør"),
    (re.compile(r"\U0001F916"), "robot-emoji-fotnote"),
]

SLOP = [re.compile(p, re.I) for p in (
    r"\bdelv(e|ing|es)\b", r"\bleverag(e|es|ed|ing)\b", r"\bseamless(ly)?\b",
    r"\bcomprehensive\b", r"\butiliz(e|es|ed|ing)\b",
    r"\bmeticulous(ly)?\b", r"\bcutting-edge\b", r"\bbest-in-class\b",
    r"\bgame-chang(er|ing)\b", r"\btestament to\b", r"\belevat(e|es|ing) the\b",
    r"\bit(’|')?s worth noting\b", r"\bit is worth noting\b",
    r"\bin today(’|')?s\b", r"\bat its core\b", r"\bunlock the power\b",
    r"\bin conclusion\b", r"\bfurthermore\b", r"\bmoreover\b",
    r"\bI hope this helps\b",
    r"\bthis (commit|PR|change) (successfully|significantly)\b",
    r"\bdet er verdt å merke seg\b", r"\bsømløs(t|e)?\b",
    r"\bavslutningsvis\b",
    r"[\U0001F389✨\U0001F525\U0001F680\U0001F4A1\U0001F4C8\U0001F64C\U0001F44F]",
)]

BODY_FILE = re.compile(r"(?:--body-file|--notes-file|--file|-F)[= ]*(\S+)")
SUBJECT = re.compile(r"""(?:-m|--message)[= ]+['"]([^'"\n]{73,})['"]""")


def command_of(payload):
    for holder in ("tool_input", "toolArgs"):
        args = payload.get(holder)
        if isinstance(args, dict):
            for key in ("command", "script"):
                v = args.get(key)
                if isinstance(v, str) and v:
                    return v
    return ""


def decide(payload):
    """→ grunntekst hvis kallet skal nektes, ellers None."""
    cmd = command_of(payload)
    if not cmd or not any(p.search(cmd) for p in PUBLISHES):
        return None

    text = cmd
    for path in BODY_FILE.findall(cmd):
        path = re.sub(r"^['\"]|['\"]$", "", path)
        if path == "-":
            continue
        try:
            with open(path, encoding="utf8") as fh:
                text += "\n" + fh.read()
        except Exception:
            pass

    trailer_hits = ["banned trailer: %s" % label
                    for pat, label in TRAILERS if pat.search(text)]

    soft_hits = []
    for pat in SLOP:
        m = pat.search(text)
        if m:
            soft_hits.append('slop phrase: "%s"' % m.group(0))
    m = SUBJECT.search(cmd)
    if m:
        soft_hits.append("subject is %d chars; keep it under 72" % len(m.group(1)))

    # Overstyringen gjelder bare ordlista og lengden, aldri trailerne.
    if OVERRIDE.match(cmd):
        soft_hits = []

    hits = trailer_hits + soft_hits
    if not hits:
        return None

    head = "Denne publiseringen ble stoppet:\n  - " + "\n  - ".join(hits) + "\n"
    if trailer_hits:
        return head + (
            "CLAUDE.md forbyr Claude-trailere. Forbudet er absolutt og kan ikke "
            "overstyres herfra. Fjern markøren og prøv igjen."
        )
    return head + (
        "Teksten skal være nøktern norsk uten markedsspråk eller emoji. Skriv om "
        "og prøv igjen. Er treffet ekte innhold (en sitert feilstreng, et "
        "filnavn), prefiks kommandoen med SLOP_OK=1."
    )


def main():
    try:
        payload = json.loads(sys.stdin.read())
        reason = decide(payload) if isinstance(payload, dict) else None
    except Exception:
        # Fail-open. En port som nekter alt er verre enn ingen port.
        reason = None

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
# Kjører skriptet som subprosess med ekte stdin, ikke bare decide(), slik at
# JSON-inn, JSON-ut og exitkoden er dekket.

def _c(command):
    return {"tool_name": "Bash", "tool_input": {"command": command}}


def selftest():
    import os
    import subprocess
    import tempfile

    tmp = tempfile.mkdtemp()
    body = os.path.join(tmp, "body.md")
    with open(body, "w", encoding="utf8") as fh:
        fh.write("Furthermore, this seamlessly leverages the new API.\n")
    notes = os.path.join(tmp, "notes.md")
    with open(notes, "w", encoding="utf8") as fh:
        fh.write("In conclusion, a comprehensive release.\n")

    subject72 = "feat: " + "x" * 66
    assert len(subject72) == 72

    cases = [
        # ── skal nektes ───────────────────────────────────────────────────────
        ("nekter Co-Authored-By: Claude",
         _c('git commit -m "fix: x" -m "Co-Authored-By: Claude <noreply@example.org>"'), True),
        ("nekter Co-Authored-By: Fable",
         _c('git commit -m "fix: x" -m "Co-Authored-By: Fable <noreply@example.org>"'), True),
        ("nekter anthropic.com-adressen",
         _c('git commit -m "fix: x" -m "Reviewed-By: someone <noreply@anthropic.com>"'), True),
        ("nekter Generated by Claude Code",
         _c('git commit -m "feat: y" -m "Generated by Claude Code"'), True),
        ("nekter Made with Claude",
         _c('git commit -m "feat: y" -m "Made with Claude"'), True),
        ("nekter robot-emoji",
         _c('git commit -m "feat: y" -m "\U0001F916 fotnote"'), True),
        ("nekter slop-ordet comprehensive",
         _c('git commit -m "feat: comprehensive refactor of the sync layer"'), True),
        ("nekter norsk slop i en issue-kommentar",
         _c('gh issue comment 640 --body "Det er verdt å merke seg at ingressen er offentlig."'), True),
        ("nekter emoji i en PR-beskrivelse",
         _c('gh pr create --title "feat: x" --body "Ship it \U0001F680"'), True),
        ("nekter emnelinje over 72 tegn",
         _c('git commit -m "feat(nav-pilot): this subject line is quite a lot longer than seventy two characters in total"'), True),
        ("nekter slop lest ut av --body-file",
         _c('gh pr create --title "feat: x" --body-file ' + body), True),
        ("nekter slop lest ut av --notes-file",
         _c('gh release create v1 --notes-file ' + notes), True),
        ("nekter slop lest ut av glued -F",
         _c('gh pr create --title "feat: x" -F' + body), True),
        ("nekter bak et env-prefiks",
         _c('GIT_AUTHOR_DATE=2026-01-01 git commit -m "feat: comprehensive x"'), True),
        ("nekter også i camelCase-dialekten",
         {"toolArgs": {"command": 'git commit -m "feat: comprehensive x"'}}, True),

        # ── B2: overstyringen skal ikke kunne omgås ───────────────────────────
        ("nekter SLOP_OK=1 nevnt inne i meldingen",
         _c('git commit -m "x SLOP_OK=1 comprehensive"'), True),
        ("nekter SLOP_OK=1 satt etter semikolon",
         _c('git commit -m "Co-Authored-By: Claude"; SLOP_OK=1 true'), True),
        ("nekter trailer selv med SLOP_OK=1 først",
         _c('SLOP_OK=1 git commit -m "fix: x" -m "Co-Authored-By: Claude <x@example.org>"'), True),

        # ── kontrollene: en port som ikke kan slippe gjennom er ingen port ─────
        ("slipper gjennom en ekte commit fra historikken",
         _c('git commit -m "fix(kom-i-gang): npm-installasjon av Copilot CLI feiler i WSL2 (#643)"'), False),
        ("slipper gjennom robust, som er brukerens eget ord",
         _c('git commit -m "feat: robust WSL2-preflight for Windows-brukere"'), False),
        ("slipper gjennom en nøktern issue-kommentar",
         _c('gh issue comment 639 --body "SSE-strømmen setter fortsatt Access-Control-Allow-Origin: *. Fiks i handler, ikke middleware."'), False),
        ("slipper gjennom i dagens, som er vanlig norsk",
         _c('gh issue comment 641 --body "I dagens implementasjon settes headeren i middleware."'), False),
        ("slipper gjennom omfattende og streamline",
         _c('git commit -m "perf: streamline hot path etter omfattende maaling"'), False),
        ("slipper gjennom emnelinje paa noeyaktig 72 tegn",
         _c('git commit -m "%s"' % subject72), False),
        ("slipper gjennom kort emnelinje med lang body",
         _c('git commit -m "fix: kort emnelinje som holder seg innenfor\n\n%s"' % ("d" * 200)), False),
        ("slipper gjennom grep etter selve slop-ordet",
         _c('grep -rn "comprehensive" apps/'), False),
        ("slipper gjennom SLOP_OK=1 som unntak",
         _c('SLOP_OK=1 git commit -m "docs: quote the comprehensive error string verbatim"'), False),
    ]

    # B1: kommandoformene ankeret tidligere bommet på.
    for form in (
        '(git commit -m "feat: comprehensive x")',
        '{ git commit -m "feat: comprehensive x"; }',
        'git -C /x commit -m "feat: comprehensive x"',
        'git -c user.name=x commit -m "feat: comprehensive x"',
        'git --no-pager commit -m "feat: comprehensive x"',
        'command git commit -m "feat: comprehensive x"',
        'env FOO=1 git commit -m "feat: comprehensive x"',
        '/usr/bin/git commit -m "feat: comprehensive x"',
        'echo x | xargs git commit -m "feat: comprehensive x"',
        'if true; then git commit -m "feat: comprehensive x"; fi',
        'for x in a; do git commit -m "feat: comprehensive x"; done',
        'git tag v1 -m "feat: comprehensive x"',
        'git tag -am "feat: comprehensive x" v1',
    ):
        cases.append(("nekter kommandoformen: %s" % form, _c(form), True))

    failed = 0
    for name, payload, want_deny in cases:
        p = subprocess.run(
            [sys.executable, __file__],
            input=json.dumps(payload),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        )
        got_deny = False
        if p.stdout.strip():
            got_deny = json.loads(p.stdout).get("permissionDecision") == "deny"
        ok = p.returncode == 0 and got_deny == want_deny
        print("%s %s" % ("✅" if ok else "❌", name))
        if not ok:
            failed += 1
            print("   exit=%s deny=%s want=%s" % (p.returncode, got_deny, want_deny))
            print("   stdout=%r stderr=%r" % (p.stdout, p.stderr))
    print("\n%d/%d ok" % (len(cases) - failed, len(cases)))
    return 1 if failed else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    main()
