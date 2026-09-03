#!/usr/bin/env python3
"""Livssyklus for Claude Code-konfigurasjonen: apply, check, capture.

`~/.claude/` er ikke sporet, fordi Claude Code skriver om filene der selv. Den
sporede ønsketilstanden ligger i `.config/claude/`, og dette skriptet er
brua mellom de to: `apply` bringer maskinen til ønsketilstanden, `check`
rapporterer avvik uten å endre noe, `capture` går andre veien og fryser
maskinens nåværende verdier ned i `settings.d/base.json`.

Bare nøklene i MANAGED røres. Verdiene til alt annet i
`~/.claude/settings.json` beholdes verdi for verdi — men fila skrives om i sin
helhet med sorterte nøkler, så byte-bildet er ikke det samme etterpå.
`autoMode` er med vilje utenfor lista: den er maskingenerert miljøkontekst
(rundt 6 kB med repo-stier) som hører til maskinen, ikke repoet.

Kjente kanter, valgt og ikke oversett:

  * Fletting er dyp for dict-er og hel utskifting for lister og skalarer. En
    liste i base.json erstatter altså hele lista i live-fila; det finnes ingen
    måte å legge til ett element i `permissions.allow` uten å eie hele lista.
    `hooks` er unntaket: `hooks.<Event>` flettes på `matcher`, slik at grupper
    Claude Code eller en plugin har lagt til lokalt overlever. Inne i en
    gruppe som treffer på matcher byttes `hooks`-lista ut i sin helhet.
  * Stier i ønskefila lagres med `${HOME}` og utvides på `apply`. `capture`
    kollapser bare et prefiks som er lik maskinens hjemmekatalog; en sti som
    peker et annet sted lagres som den er, og følger ikke med til neste maskin.
    Utvidinga gjelder alle strenger i de styrte verdiene, så en verdi som
    bokstavelig talt skal inneholde `${HOME}` kan ikke uttrykkes.
  * En ønskefil eller live-fil som ikke er gyldig JSON er en feil, ikke et
    tomt objekt: alle tre kommandoene stopper med melding og navnet på fila.
    En live-fil som ikke finnes er derimot greit.
  * `check` kaller `claude plugin list` og leser statuslinja per plugin; en
    plugin som er installert, men slått av, teller som avvik. Formatet er
    udokumentert og kan endre seg. Uten `claude` på PATH, eller hvis kallet
    tidsavbrytes, sies det fra, og det telles ikke som avvik.
  * `check` kjører `--selftest` på hver `hooks/*.py` som faktisk nevner det
    flagget i kildekoden. En hjelpemodul uten selvtest hoppes over.
  * Sikkerhetskopier ryddes til de fem nyeste, sortert på endringstidspunkt.
    Ryddinga ser bare på `settings.json.bak-*`; eldre navnekonvensjoner røres
    ikke.
  * Symlenker sammenliknes på råtekst fra readlink, ikke på resolve(). En
    lenke som peker riktig via en annen sti regnes som avvik. `apply` retter
    den ikke opp: en lenke som peker et annet sted er en konflikt på linje med
    en vanlig fil, den blir stående, og apply avslutter med kode 1.
  * `settings.json` skrives med rettighetene fila alt har; en fil som ikke
    finnes fra før lages med 0600, siden `env` der kan inneholde API-nøkler.
  * Kjøretidsdata (`projects/`, `history.jsonl`, `file-history/`, `sessions/`)
    røres aldri, verken av apply eller av opprydding.
"""

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

MANAGED = (
    "permissions", "model", "enabledPlugins", "extraKnownMarketplaces",
    "feedbackDrafts", "modelSettings", "theme", "preferredNotifChannel",
    "inputNeededNotifEnabled", "agentPushNotifEnabled", "attribution",
    "feedbackSurveyRate", "spinnerTipsEnabled", "hooks",
)

KEEP_BACKUPS = 5


class ConfigError(Exception):
    """Fila finnes, men er ikke lesbar JSON. Da skal ingenting skrives."""


def load(path):
    try:
        with open(str(path), encoding="utf8") as fh:
            return json.load(fh)
    except FileNotFoundError:
        return {}
    except ValueError as exc:
        raise ConfigError("%s er ikke gyldig JSON: %s" % (path, exc))
    except OSError as exc:      # katalog, rettigheter, ødelagt lenke
        raise ConfigError("%s kan ikke leses: %s" % (path, exc))


def dump(obj):
    return json.dumps(obj, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def write_atomic(path, text):
    """Skriv gjennom en temp-fil i samme katalog. Er målet en symlenke, følges
    den, slik at lenka ikke byttes ut med en vanlig fil. Rettighetene til et
    eksisterende mål arves; en ny fil får 0600, ikke det umask gir — fila kan
    inneholde `env` med API-nøkler."""
    target = Path(os.path.realpath(str(path)))
    target.parent.mkdir(parents=True, exist_ok=True)
    tmp = target.with_name("%s.tmp-%d" % (target.name, os.getpid()))
    try:
        tmp.write_text(text, encoding="utf8")
        if target.exists():
            shutil.copymode(str(target), str(tmp))
        else:
            tmp.chmod(0o600)
    except BaseException:
        tmp.unlink(missing_ok=True)
        raise
    os.replace(str(tmp), str(target))


def deep_merge(dst, src):
    """Dict-er flettes rekursivt; lister og skalarer byttes helt ut."""
    for key, val in src.items():
        if isinstance(val, dict) and isinstance(dst.get(key), dict):
            deep_merge(dst[key], val)
        else:
            dst[key] = val
    return dst


def expand(obj, home):
    """${HOME} i ønskeverdier byttes ut med maskinens faktiske hjemmekatalog."""
    if isinstance(obj, dict):
        return {k: expand(v, home) for k, v in obj.items()}
    if isinstance(obj, list):
        return [expand(v, home) for v in obj]
    if isinstance(obj, str):
        return obj.replace("${HOME}", str(home))
    return obj


def collapse(obj, home):
    """Motsatt vei: en sti som starter i hjemmekatalogen lagres som ${HOME}."""
    if isinstance(obj, dict):
        return {k: collapse(v, home) for k, v in obj.items()}
    if isinstance(obj, list):
        return [collapse(v, home) for v in obj]
    if isinstance(obj, str):
        h = str(home)
        if obj == h or obj.startswith(h + os.sep):
            return "${HOME}" + obj[len(h):]
    return obj


def merge_hooks(got, want):
    """`hooks.<Event>` flettes på matcher: en ønsket gruppe erstatter live-gruppa
    med samme matcher, live-grupper med andre matchere står. Inne i en truffet
    gruppe byttes den indre `hooks`-lista ut i sin helhet. Har live-fila flere
    grupper med samme matcher, overlever bare den første — resten er duplikater
    som ellers ville stått igjen som gamle hooks."""
    out = json.loads(json.dumps(got))
    for event, groups in want.items():
        have = out.get(event)
        if not isinstance(groups, list) or not isinstance(have, list):
            out[event] = groups
            continue
        seen = set()
        for group in groups:
            key = group.get("matcher") if isinstance(group, dict) else None
            if key in seen:
                raise ConfigError(
                    "hooks.%s har to ønskede grupper med matcher %r" % (event, key))
            seen.add(key)
            hit = [i for i, lg in enumerate(have)
                   if isinstance(lg, dict) and lg.get("matcher") == key]
            if not hit:
                have.append(group)
                continue
            first = hit[0]
            have[first] = dict(have[first], **group) if isinstance(group, dict) else group
            for i in reversed(hit[1:]):
                del have[i]
        out[event] = have
    return out


def merge_key(key, got, want):
    """→ verdien nøkkelen skal ha i live-fila etter fletting."""
    if isinstance(want, dict) and isinstance(got, dict):
        if key == "hooks":
            return merge_hooks(got, want)
        return deep_merge(json.loads(json.dumps(got)), want)
    return want


def paths(root, home):
    return {
        "desired": root / "settings.d" / "base.json",
        "live": home / ".claude" / "settings.json",
        "skills_src": root / "skills",
        "skills_dst": home / ".claude" / "skills",
        "memory_src": root / "memory",
        "memory_dst": home / ".claude",
        "hooks": root / "hooks",
    }


def backup(live):
    stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    dst = live.with_name(live.name + ".bak-" + stamp)
    n = 0
    while dst.exists():          # samme sekund, flere skrivinger
        n += 1
        dst = live.with_name("%s.bak-%s.%d" % (live.name, stamp, n))
    shutil.copy2(str(live), str(dst))
    old = sorted(live.parent.glob(live.name + ".bak-*"),
                 key=lambda f: (f.stat().st_mtime_ns, f.name))
    for stale in old[:-KEEP_BACKUPS]:
        stale.unlink()
    return dst


def link(src, dst, out):
    """→ True hvis lenka er på plass etterpå, False ved konflikt."""
    label = dst.name
    if dst.is_symlink():
        seen = os.readlink(str(dst))
        if seen == str(src):
            out("allerede riktig: %s" % label)
            return True
        out("konflikt: %s peker på %s, ikke %s — rører den ikke" % (dst, seen, src))
        return False
    elif dst.exists():
        out("konflikt: %s finnes og er ikke en symlenke — rører den ikke" % dst)
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.symlink_to(src)
    out("lenket: %s -> %s" % (label, src))
    return True


def sources(p):
    """→ [(kilde, mål)] for skills (kataloger) og memory (filer)."""
    out = []
    if p["skills_src"].is_dir():
        for src in sorted(p["skills_src"].iterdir()):
            if src.is_dir():
                out.append((src, p["skills_dst"] / src.name))
    if p["memory_src"].is_dir():
        for src in sorted(p["memory_src"].iterdir()):
            if src.is_file():
                out.append((src, p["memory_dst"] / src.name))
    return out


def cmd_apply(root, home, out=print):
    p = paths(root, home)
    desired = expand(load(p["desired"]), home)
    live = load(p["live"])

    merged = json.loads(json.dumps(live))
    for key in MANAGED:
        if key in desired:
            merged[key] = merge_key(key, merged.get(key), desired[key])

    if merged == live:
        out("allerede riktig: settings.json")
    else:
        p["live"].parent.mkdir(parents=True, exist_ok=True)
        if p["live"].exists():
            out("sikkerhetskopi: %s" % backup(p["live"]).name)
        write_atomic(p["live"], dump(merged))
        changed = [k for k in MANAGED if live.get(k) != merged.get(k)]
        out("skrev settings.json (%s)" % ", ".join(changed))

    if p["hooks"].is_dir():
        for hook in sorted(p["hooks"].glob("*.py")):
            mode = hook.stat().st_mode
            if mode & 0o111 != 0o111:
                hook.chmod(mode | 0o111)
                out("satt kjørbar: hooks/%s" % hook.name)

    ok = True
    for src, dst in sources(p):
        ok = link(src, dst, out) and ok
    return 0 if ok else 1


def trunc(val, width=60):
    text = json.dumps(val, sort_keys=True, ensure_ascii=False)
    return text if len(text) <= width else text[:width - 1] + "…"


def enabled_plugins(listing):
    """→ navnene i `claude plugin list` som står med status enabled.

    Utskriften er blokker: en linje med `❯ navn`, så felt, deriblant
    `Status: ✔ enabled` eller `Status: ✘ disabled`. En delstrengsjekk på hele
    utskriften ville godtatt en plugin som er installert og slått av."""
    found, name = set(), None
    for line in listing.splitlines():
        line = line.strip()
        if line.startswith("❯"):
            name = line[1:].strip()
        elif name and line.lower().startswith("status:"):
            low = line.lower()
            if "disabled" not in low and "enabled" in low:
                found.add(name)
            name = None
    return found


def cmd_check(root, home, out=print):
    p = paths(root, home)
    desired = expand(load(p["desired"]), home)
    live = load(p["live"])
    drift = 0

    for key in MANAGED:
        if key not in desired:
            continue
        want, got = desired[key], live.get(key)
        if merge_key(key, got, want) == got:
            continue
        out("avvik: %s  ønsket=%s  live=%s" % (key, trunc(want), trunc(got)))
        drift += 1

    for src, dst in sources(p):
        if not dst.is_symlink():
            out("avvik: %s mangler eller er ikke en symlenke" % dst)
            drift += 1
        elif os.readlink(str(dst)) != str(src):
            out("avvik: %s peker på %s, ikke %s" % (dst, os.readlink(str(dst)), src))
            drift += 1

    wanted = [k for k, on in (desired.get("enabledPlugins") or {}).items() if on]
    if wanted:
        if shutil.which("claude") is None:
            out("merk: claude ikke på PATH — plugins ikke sjekket")
        else:
            try:
                res = subprocess.run(
                    ["claude", "plugin", "list"], stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL, universal_newlines=True,
                    timeout=30,
                )
                listing = res.stdout
                if res.returncode != 0:
                    listing = None
                    out("merk: claude plugin list feilet (kode %d) — plugins ikke "
                        "sjekket" % res.returncode)
            except subprocess.TimeoutExpired:
                listing = None
                out("merk: claude plugin list tidsavbrutt — plugins ikke sjekket")
            if listing is not None:
                on = enabled_plugins(listing)
                for name in wanted:
                    if name not in on:
                        out("avvik: plugin ikke installert eller slått av: %s" % name)
                        drift += 1

    if p["hooks"].is_dir():
        for hook in sorted(p["hooks"].glob("*.py")):
            if "--selftest" not in hook.read_text(encoding="utf8", errors="replace"):
                continue
            try:
                rc = subprocess.run(
                    [sys.executable, str(hook), "--selftest"],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                    timeout=60,
                ).returncode
            except subprocess.TimeoutExpired:
                out("avvik: selvtest henger (over 60 s): %s" % hook.name)
                drift += 1
                continue
            if rc != 0:
                out("avvik: selvtest feiler: %s" % hook.name)
                drift += 1

    out("rent" if not drift else "%d avvik" % drift)
    return 1 if drift else 0


def cmd_capture(root, home, out=print):
    p = paths(root, home)
    old = load(p["desired"])
    live = load(p["live"])
    new = collapse({k: live[k] for k in MANAGED if k in live}, home)

    for key in sorted(set(old) | set(new)):
        if key not in new:
            out("fjernet: %s" % key)
        elif key not in old:
            out("ny: %s = %s" % (key, trunc(new[key])))
        elif old[key] != new[key]:
            out("endret: %s  fra=%s  til=%s" % (key, trunc(old[key]), trunc(new[key])))
    if old == new:
        out("ingen endring")

    write_atomic(p["desired"], dump(new))
    return 0


COMMANDS = {"apply": cmd_apply, "check": cmd_check, "capture": cmd_capture}


def main(argv):
    root = Path(__file__).resolve().parent
    home = Path(os.path.expanduser("~"))
    if len(argv) != 2 or argv[1] not in COMMANDS:
        print("bruk: manage.py {apply|check|capture|--selftest}", file=sys.stderr)
        return 2
    return run(argv[1], root, home)


def run(name, root, home, out=print):
    """→ exit-kode. En ulesbar JSON-fil blir én melding og en kode ulik 0."""
    try:
        return COMMANDS[name](root, home, out)
    except ConfigError as exc:
        print("feil: %s" % exc, file=sys.stderr)
        return 1


# ─── Selvtest ────────────────────────────────────────────────────────────────
# Kjører alltid mot et midlertidig HOME og et midlertidig repo, aldri mot de
# ekte. Ingen sti under det virkelige ~/.claude/ røres.

def selftest():
    import contextlib
    import io
    import tempfile

    results = []
    temps = []

    def case(name, ok, detail=""):
        results.append(ok)
        print("%s %s" % ("✅" if ok else "❌", name))
        if not ok and detail:
            print("   %s" % detail)

    def scratch():
        temps.append(Path(tempfile.mkdtemp()))
        return temps[-1]

    tmp = scratch()
    root = tmp / "repo"
    home = tmp / "home"
    p = paths(root, home)
    (root / "settings.d").mkdir(parents=True)
    (root / "skills" / "unslop").mkdir(parents=True)
    (root / "memory").mkdir(parents=True)
    (root / "memory" / "CLAUDE.md").write_text("@RTK.md\n", encoding="utf8")
    p["live"].parent.mkdir(parents=True)

    automode = {"repos": ["/a/b", "/c/d"], "n": 3}
    live = {
        "autoMode": automode,
        "someRuntimeKey": {"deep": [1, 2, 3]},
        "theme": "light",
    }
    p["live"].write_text(dump(live), encoding="utf8")
    desired = {"theme": "dark", "model": "opus[1m]",
               "permissions": {"allow": ["Bash(ls:*)"]}}
    p["desired"].write_text(dump(desired), encoding="utf8")

    lines = []
    rc = cmd_apply(root, home, lines.append)
    after = load(p["live"])
    case("apply fletter inn en styrt nøkkel",
         rc == 0 and after.get("theme") == "dark" and after.get("model") == "opus[1m]",
         repr(after))
    case("apply lar autoMode stå urørt, verdi for verdi",
         after.get("autoMode") == automode, repr(after.get("autoMode")))
    case("apply lar andre ustyrte nøkler stå urørt, verdi for verdi",
         after.get("someRuntimeKey") == live["someRuntimeKey"])
    skill_link = home / ".claude" / "skills" / "unslop"
    memory_link = home / ".claude" / "CLAUDE.md"
    case("apply lenker skills og memory til riktig kilde",
         skill_link.is_symlink() and memory_link.is_symlink()
         and os.readlink(str(skill_link)) == str(root / "skills" / "unslop")
         and os.readlink(str(memory_link)) == str(root / "memory" / "CLAUDE.md"),
         repr([skill_link.is_symlink(), memory_link.is_symlink()]))

    before_bytes = p["live"].read_bytes()
    lines2 = []
    rc2 = cmd_apply(root, home, lines2.append)
    case("apply er idempotent: bare no-ops, identisk fil",
         rc2 == 0 and p["live"].read_bytes() == before_bytes
         and all("allerede riktig" in ln for ln in lines2),
         repr(lines2))

    case("check er 0 når alt stemmer", cmd_check(root, home, lambda *_: None) == 0)

    p["desired"].write_text(dump(dict(desired, theme="ansi")), encoding="utf8")
    drift_lines = []
    case("check er 1 ved avvik, og navngir nøkkelen",
         cmd_check(root, home, drift_lines.append) == 1
         and any("avvik: theme" in ln for ln in drift_lines), repr(drift_lines))
    p["desired"].write_text(dump(desired), encoding="utf8")

    # Konflikt: en ekte katalog der en skill-lenke skal stå.
    (root / "skills" / "kollisjon").mkdir()
    clash = home / ".claude" / "skills" / "kollisjon"
    clash.mkdir(parents=True)
    (clash / "egen.md").write_text("må overleve\n", encoding="utf8")
    conflict_lines = []
    rc3 = cmd_apply(root, home, conflict_lines.append)
    case("ekte katalog på en skill-sti meldes som konflikt og overskrives ikke",
         rc3 == 1 and not clash.is_symlink()
         and (clash / "egen.md").read_text(encoding="utf8") == "må overleve\n"
         and any("konflikt" in ln for ln in conflict_lines), repr(conflict_lines))
    shutil.rmtree(str(clash))
    shutil.rmtree(str(root / "skills" / "kollisjon"))

    # Konflikt: en ekte fil der memory-lenka skal stå — førstegangstilfellet.
    memory_link.unlink()
    memory_link.write_text("min egen globale hukommelse\n", encoding="utf8")
    file_lines = []
    rc4 = cmd_apply(root, home, file_lines.append)
    case("ekte fil på ~/.claude/CLAUDE.md meldes som konflikt og overskrives ikke",
         rc4 == 1 and not memory_link.is_symlink()
         and memory_link.read_text(encoding="utf8") == "min egen globale hukommelse\n"
         and any("konflikt" in ln for ln in file_lines), repr(file_lines))
    memory_link.unlink()

    # Konflikt: en symlenke brukeren selv har laget til noe annet. Den skal
    # ikke rettes opp i det stille.
    egen = tmp / "min-egen-CLAUDE.md"
    egen.write_text("min egen fil\n", encoding="utf8")
    memory_link.symlink_to(egen)
    alien_lines = []
    rc5 = cmd_apply(root, home, alien_lines.append)
    case("fremmed symlenke meldes som konflikt og retargetes ikke",
         rc5 == 1 and os.readlink(str(memory_link)) == str(egen)
         and any("konflikt" in ln for ln in alien_lines), repr(alien_lines))
    memory_link.unlink()

    # capture skal gi tilbake nøyaktig den ønskefila apply nettopp brukte, og
    # plukke opp en endring i live-fila. Uten den andre halvdelen ville en
    # capture som ikke skriver noe som helst bestått.
    cmd_apply(root, home, lambda *_: None)
    want_file = p["desired"].read_text(encoding="utf8")
    cmd_capture(root, home, lambda *_: None)
    round_ok = p["desired"].read_text(encoding="utf8") == want_file
    mutert = load(p["live"])
    mutert["theme"] = "solarized"
    p["live"].write_text(dump(mutert), encoding="utf8")
    cmd_capture(root, home, lambda *_: None)
    captured = load(p["desired"])
    case("capture går rundt og fryser en endring i live-fila",
         round_ok and captured.get("theme") == "solarized"
         and captured.get("model") == desired["model"],
         "%s %r" % (round_ok, captured))
    p["desired"].write_text(dump(desired), encoding="utf8")

    for i in range(8):
        p["desired"].write_text(dump(dict(desired, model="m%d" % i)), encoding="utf8")
        cmd_apply(root, home, lambda *_: None)
    baks = sorted(p["live"].parent.glob("settings.json.bak-*"))
    case("sikkerhetskopier lages og ryddes til %d" % KEEP_BACKUPS,
         len(baks) == KEEP_BACKUPS, repr([b.name for b in baks]))

    # Hvilke fem som blir stående: navnerekkefølgen er her med vilje en annen
    # enn alderen, så en rydding som sorterer på navn eller kutter feil ende
    # av lista faller igjennom.
    tmp8 = scratch()
    tmp8.joinpath("d").mkdir()
    livefile = tmp8 / "d" / "settings.json"
    livefile.write_text("{}\n", encoding="utf8")
    alder = {}
    for i, minutt in enumerate([5, 1, 7, 3, 6, 2, 4]):
        f = livefile.with_name("settings.json.bak-%s" % "abcdefg"[i])
        f.write_text("%d" % i, encoding="utf8")
        os.utime(str(f), (1000000 + minutt * 60, 1000000 + minutt * 60))
        alder[f.name] = minutt
    ny = backup(livefile).name       # kopien av livefile er den ferskeste
    igjen = {f.name for f in livefile.parent.glob("settings.json.bak-*")}
    eldst_forst = sorted(alder, key=lambda n: alder[n])
    case("ryddinga sletter de eldste sikkerhetskopiene, ikke de nyeste",
         igjen == {ny} | set(eldst_forst[-(KEEP_BACKUPS - 1):]),
         repr(sorted(igjen)))

    # Portabilitet: en tracket sti med ${HOME} skal treffe maskinens eget hjem.
    tmp2 = scratch()
    r2, h2 = tmp2 / "repo", tmp2 / "home"
    p2 = paths(r2, h2)
    (r2 / "settings.d").mkdir(parents=True)
    p2["live"].parent.mkdir(parents=True)
    p2["live"].write_text(dump({}), encoding="utf8")
    tmpl = "${HOME}/.config/claude/hooks/slop-gate.py"
    p2["desired"].write_text(
        dump({"hooks": {"X": [{"command": tmpl}]}}), encoding="utf8")
    cmd_apply(r2, h2, out=lambda *a: None)
    got = load(p2["live"])["hooks"]["X"][0]["command"]
    case("HOME-mal utvides til maskinens hjemmekatalog",
         got == str(h2) + "/.config/claude/hooks/slop-gate.py", got)
    # Endre live-fila først, ellers ville en capture som ikke skriver noe
    # bestått: ønskefila inneholder allerede malen.
    live2 = load(p2["live"])
    live2["hooks"]["X"][0]["command"] = str(h2) + "/.config/claude/hooks/annen.py"
    p2["live"].write_text(dump(live2), encoding="utf8")
    cmd_capture(r2, h2, out=lambda *a: None)
    back = load(p2["desired"])["hooks"]["X"][0]["command"]
    case("capture legger ${HOME} tilbake, også for en verdi den ikke hadde før",
         back == "${HOME}/.config/claude/hooks/annen.py", back)

    # Kontroll: en sti som bare begynner med de samme tegnene som
    # hjemmekatalogen er ikke under den, og skal stå bokstavelig. Denne skal
    # feile hvis collapse går tilbake til en naken startswith.
    naboen = str(h2) + "en/x"
    case("capture kollapser ikke en sti som bare likner hjemmekatalogen",
         collapse(naboen, h2) == naboen, collapse(naboen, h2))
    case("capture kollapser hjemmekatalogen selv",
         collapse(str(h2), h2) == "${HOME}", collapse(str(h2), h2))

    # hooks-lista flettes på matcher, så lokale grupper overlever.
    tmp3 = scratch()
    r3, h3 = tmp3 / "repo", tmp3 / "home"
    p3 = paths(r3, h3)
    (r3 / "settings.d").mkdir(parents=True)
    p3["live"].parent.mkdir(parents=True)
    p3["live"].write_text(dump({"hooks": {"PreToolUse": [
        {"matcher": "Bash", "hooks": [
            {"type": "command", "command": "gammel.py"},
            {"type": "command", "command": "fremmed-sosken.py"}]},
        {"matcher": "Write", "hooks": [{"type": "command", "command": "plugin.py"}]},
    ]}}), encoding="utf8")
    p3["desired"].write_text(dump({"hooks": {"PreToolUse": [
        {"matcher": "Bash", "hooks": [{"type": "command", "command": "ny.py"}]}]}}),
        encoding="utf8")
    cmd_apply(r3, h3, lambda *_: None)
    groups = load(p3["live"])["hooks"]["PreToolUse"]
    by_matcher = {g["matcher"]: g for g in groups}
    case("apply beholder hook-grupper med andre matchere",
         set(by_matcher) == {"Bash", "Write"}
         and [h["command"] for h in by_matcher["Write"]["hooks"]] == ["plugin.py"],
         repr(groups))
    case("apply bytter ut hooks-lista i gruppa som treffer på matcher",
         [h["command"] for h in by_matcher["Bash"]["hooks"]] == ["ny.py"], repr(groups))
    case("check er 0 etter fletting av hooks",
         cmd_check(r3, h3, lambda *_: None) == 0)

    # Live-fila har to grupper med samme matcher. Bare den første skal
    # erstattes; blir den andre stående, står en gammel hook igjen og check
    # melder likevel rent.
    p3["live"].write_text(dump({"hooks": {"PreToolUse": [
        {"matcher": "Bash", "hooks": [{"type": "command", "command": "gammel.py"}]},
        {"matcher": "Bash", "hooks": [{"type": "command", "command": "gammel2.py"}]},
        {"matcher": "Write", "hooks": [{"type": "command", "command": "plugin.py"}]},
    ]}}), encoding="utf8")
    cmd_apply(r3, h3, lambda *_: None)
    dup = load(p3["live"])["hooks"]["PreToolUse"]
    case("apply fjerner duplikate live-grupper med samme matcher",
         [g["matcher"] for g in dup] == ["Bash", "Write"]
         and [h["command"] for h in dup[0]["hooks"]] == ["ny.py"], repr(dup))

    # To ønskede grupper med samme matcher ville stille kollapset til den
    # siste. Det er en feil i ønskefila, og skal sies fra om.
    p3["desired"].write_text(dump({"hooks": {"PreToolUse": [
        {"matcher": "Bash", "hooks": [{"type": "command", "command": "a.py"}]},
        {"matcher": "Bash", "hooks": [{"type": "command", "command": "b.py"}]}]}}),
        encoding="utf8")
    before3 = p3["live"].read_bytes()
    err3 = io.StringIO()
    with contextlib.redirect_stderr(err3):
        rc_dup = run("apply", r3, h3, lambda *_: None)
    case("to ønskede hook-grupper med samme matcher er en feil, og ingenting skrives",
         rc_dup != 0 and p3["live"].read_bytes() == before3
         and "matcher" in err3.getvalue(), "%d %r" % (rc_dup, err3.getvalue()))

    # En ønsket gruppe som ikke er en dict skal bytte ut, ikke kaste TypeError.
    tmp7 = scratch()
    r7, h7 = tmp7 / "repo", tmp7 / "home"
    p7 = paths(r7, h7)
    (r7 / "settings.d").mkdir(parents=True)
    p7["live"].parent.mkdir(parents=True)
    p7["live"].write_text(dump({"hooks": {"PreToolUse": [
        {"hooks": [{"type": "command", "command": "gammel.py"}]}]}}), encoding="utf8")
    p7["desired"].write_text(dump({"hooks": {"PreToolUse": ["x"]}}), encoding="utf8")
    rc7 = cmd_apply(r7, h7, lambda *_: None)
    case("ikke-dict ønsket hook-gruppe byttes inn uten TypeError",
         rc7 == 0 and load(p7["live"])["hooks"]["PreToolUse"] == ["x"],
         repr(load(p7["live"]).get("hooks")))

    # En ulesbar live-fil er en feil, ikke et tomt objekt.
    tmp4 = scratch()
    r4, h4 = tmp4 / "repo", tmp4 / "home"
    p4 = paths(r4, h4)
    (r4 / "settings.d").mkdir(parents=True)
    p4["desired"].write_text(dump({"theme": "dark"}), encoding="utf8")
    p4["live"].parent.mkdir(parents=True)
    p4["live"].write_text('{"theme": "dark",\n', encoding="utf8")
    broken = p4["live"].read_bytes()
    want_bytes = p4["desired"].read_bytes()

    def raises(fn):
        try:
            fn(r4, h4, lambda *_: None)
        except ConfigError:
            return True
        return False

    case("ødelagt live-fil stopper apply, og ingenting skrives",
         raises(cmd_apply) and p4["live"].read_bytes() == broken)
    case("ødelagt live-fil stopper capture, og ønskefila står urørt",
         raises(cmd_capture) and p4["desired"].read_bytes() == want_bytes)
    err = io.StringIO()
    with contextlib.redirect_stderr(err):
        rc_broken = run("check", r4, h4, lambda *_: None)
    case("ødelagt live-fil gir check en exit-kode ulik 0, med filnavnet i meldinga",
         rc_broken != 0 and str(p4["live"]) in err.getvalue(),
         "%d %r" % (rc_broken, err.getvalue()))

    # autoMode er maskingenerert og skal stå urørt selv om ønskefila har den.
    tmp5 = scratch()
    r5, h5 = tmp5 / "repo", tmp5 / "home"
    p5 = paths(r5, h5)
    (r5 / "settings.d").mkdir(parents=True)
    p5["live"].parent.mkdir(parents=True)
    p5["live"].write_text(
        dump({"autoMode": {"repos": ["/mitt/repo"]}, "theme": "light"}), encoding="utf8")
    p5["desired"].write_text(
        dump({"autoMode": {"repos": []}, "theme": "dark"}), encoding="utf8")
    cmd_apply(r5, h5, lambda *_: None)
    got5 = load(p5["live"])
    case("apply rører ikke autoMode i live-fila, selv når base.json har nøkkelen",
         got5.get("autoMode") == {"repos": ["/mitt/repo"]} and got5.get("theme") == "dark",
         repr(got5))

    # Rettigheter: settings.json kan bære env med API-nøkler, og skal ikke bli
    # verdenslesbar av at temp-fila arver umask.
    tmp6 = scratch()
    r6, h6 = tmp6 / "repo", tmp6 / "home"
    p6 = paths(r6, h6)
    (r6 / "settings.d").mkdir(parents=True)
    p6["live"].parent.mkdir(parents=True)
    p6["desired"].write_text(dump({"theme": "dark"}), encoding="utf8")
    cmd_apply(r6, h6, lambda *_: None)
    mode6 = p6["live"].stat().st_mode & 0o777
    case("en settings.json som ikke fantes lages med 0600", mode6 == 0o600, oct(mode6))
    p6["live"].chmod(0o600)
    p6["desired"].write_text(dump({"theme": "ansi"}), encoding="utf8")
    cmd_apply(r6, h6, lambda *_: None)
    mode6b = p6["live"].stat().st_mode & 0o777
    case("apply beholder 0600 på en settings.json som alt er 0600",
         mode6b == 0o600, oct(mode6b))

    for t in temps:
        shutil.rmtree(str(t), ignore_errors=True)
    bad = results.count(False)
    print("\n%d/%d ok" % (len(results) - bad, len(results)))
    return 1 if bad else 0


if __name__ == "__main__":
    if sys.argv[1:2] == ["--selftest"]:
        sys.exit(selftest())
    sys.exit(main(sys.argv))
