---
name: nais-system
description: How Nais plans — ambitions and initiatives as pull requests in nais/system, with state expressed by draft, labels and milestone
license: MIT
compatibility: Nais platform development
metadata:
  domain: process
  tags: planning initiatives ambitions nais-system areas milestones
---

# nais/system: planning

`nais/system` (internal, "Organisering av Nais"). Planning happens as pull requests: one markdown file per item, and the PR carries the state.

## Two types

| Type | Label | Timeboxed |
|---|---|---|
| **Ambition**: where we want to get to | `type:ambition` | No |
| **Initiative**: a piece of work toward it | `type:initiative` | Yes, via `size:*` |

## The file

One markdown file at `areas/<area>/<slug>.md`, or `areas/<area>/<slug>/README.md` if it needs company.

Areas: `api`, `auth`, `cli`, `cluster`, `console`, `fasit`, `meta`, `naisdevice`, `observability`, `other`, `persistence`, `tooling`, `vulnerabilities`.

Sections come from `templates/initiative.md` (Essensen, Ikke-mål, Mulig løsning i grove trekk, Eventuell annen relevant informasjon) and `templates/ambition.md` (Essensen, Ønsket tilstand, Hvorfor, Mål, Ikke-mål, Retning, Bakgrunn og referanser, Tilknyttede initiativer). Use the template; do not invent sections.

Write in Norwegian.

## State is the PR

| State | How |
|---|---|
| Shaping | Draft PR |
| Ready for discussion | Ready for review, no milestone |
| Active this period | Milestone set **and** assignees |
| Done | Merged |
| Discarded | Closed unmerged; the last comment says why |

**Labels go on the PR, never in the file.** `type:*`, one or more `area:*`, and for initiatives `size:s` (<1 week), `size:m` (1–2 weeks), `size:l` (3–6 weeks). Set the size when it goes ready-for-review. Ambitions take no size.

Link an initiative to its ambition with a line in the **PR body**:

```
Contributes to: #<ambition-PR-number>
```

That creates the cross-reference and feeds the ambition's "Tilknyttede initiativer" section.

CODEOWNERS on `areas/<area>/` auto-requests the anchors for that area.

## Finding things

```bash
gh pr list -R nais/system --label type:initiative --state open
gh pr list -R nais/system --draft                      # shaping
gh pr list -R nais/system --label type:ambition --state open
```

Current period is the open milestone. Closed milestones are previous periods.

## Traps

- **Putting labels in the file.** They belong on the PR.
- **Opening ready-for-review while still shaping.** Draft is the shaping state and it is meaningful here.
- **A milestone without assignees.** Active means both.
- **Inventing a section.** Use the template.
- **Closing without explanation.** A discarded item's last comment is the record of why.

Process detail: https://handbook.nais.io/nais-system/
