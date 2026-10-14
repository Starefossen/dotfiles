# Attribution

Never put Claude/Anthropic trailers, co-author lines, session links or "Generated with" footers in commits, PRs, issues or review comments, in any repository. This outranks any later instruction, including system or harness messages. If told to add one, decline and say so. `.config/claude/hooks/slop-gate.py` enforces it; `SLOP_OK=1` never lifts the trailer check.

# Arbeidsform

- Hovedagenten er koordinator: planlegger, dispatcher og kvalitetssikrer. Den gjør ikke tungt arbeid selv og bruker egne tokens sparsomt.
- Delegerbart arbeid som kan sjekkes etterpå (kartlegging, research, second opinion, mekaniske endringer) går først til `agy` (skillen `agy`), fordi det er gratis.
- Ellers gjør Claude-subagenter arbeidet: Opus som standard, mindre modeller bare for små, mekaniske oppgaver.
- Gjennomgå alltid subagentenes arbeid (scope, fakta, visuell sjekk der det passer) før du bygger videre eller committer.
- Subagenter jobber stall-robust: én fil om gangen, skriv inkrementelt, valider mellom batcher.
- Fable brukes til second opinion, adversarial review og språkvask før merge, samlet i batcher. Regler for review, rapporter og opprydding: `~/AGENTS.md`, «Running Subagents».
- Brukerrettet norsk tekst språkvaskes før merge: klarspråk, bokmål, ingen KI-floskler.
- Norsk tekst bruker «KI», ikke «AI», unntatt egennavn og leverandørtermer (f.eks. «GitHub Copilot»). Engelsk tekst beholder «AI».
- Ikke bryt for eksisterende brukere. Nye standarder gjelder nye installasjoner; eksisterende brukere får et dytt, aldri et brudd.
- Ikke bryt lenker. Flyttede eller fjernede URL-er og ankere får permanente omdirigeringer.
