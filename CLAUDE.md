Do not add Claude specific trailers / co-author to commit messages or pull requests.

# Arbeidsform

- Hovedagenten (Fable) er koordinator: planlegger, dispatcher subagenter og kvalitetssikrer — den gjør ikke tungt arbeid selv og skal bruke egne tokens sparsomt.
- Subagenter gjør selve arbeidet. Bruk Opus som standard; mindre modeller bare for små, mekaniske oppgaver.
- Gjennomgå alltid subagentenes arbeid (scope-sjekk, faktasjekk, visuell verifisering der det er relevant) før du bygger videre eller committer.
- Subagenter skal jobbe stall-robust: én fil om gangen, inkrementell skriving, validering mellom batcher.
