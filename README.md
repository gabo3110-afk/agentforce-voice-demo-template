# Agentforce Voice Demo Template

[![Use this template](https://img.shields.io/badge/use%20this-template-2ea44f?style=for-the-badge&logo=github)](https://github.com/gabo3110-afk/agentforce-voice-demo-template/generate)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Salesforce API](https://img.shields.io/badge/Salesforce%20API-v66.0%2B-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/)
[![Agentforce](https://img.shields.io/badge/Agentforce-Voice%20Agent-FF6B35?style=for-the-badge)](https://www.salesforce.com/agentforce/)
[![Agent Script](https://img.shields.io/badge/Agent%20Script-DSL-6E5BFF?style=for-the-badge)](https://developer.salesforce.com/docs/einstein/genai/guide/agent-script-overview.html)
[![Verified](https://img.shields.io/badge/Verified-8%20cases%20%E2%9C%93-success?style=for-the-badge)](docs/golden-flow-template.md)
[![Patterns](https://img.shields.io/badge/Runtime%20Patterns-20-informational?style=for-the-badge)](docs/architecture.md)

A production-tested SFDX scaffold for building bilingual Agentforce Voice agent POCs.

Pairs with the [`sf-ai-agentforce-voice-demo`](docs/skill-pointer.md) Claude skill that documents the 20 runtime patterns this scaffold encodes.

> Battle-tested across one full Spanish + Portuguese voice POC (8 cases, 33 verified turns, 17 .agent versions of iteration). The patterns work.

## What you get

- **Hub-and-spoke `.agent` skeleton** with the `active_topic` auto-route that makes multi-turn dialogues actually work
- **13 invocable Apex action templates** covering the common voice-demo shapes: customer profile lookup, service catalog, contracts/billing, warranty, connected vehicle, sales orders, technical bulletins, case status, action+confirmation flows, write actions
- **Drop-in `VoiceFormatter` class** — Spanish-rioplatense + Portuguese-paulistano number-to-words, currency, dates, month names (production-tested 225 lines, validates 90/90)
- **`<Brand>CustomerLookup` class** — format-tolerant DNI/CPF/plate-number resolver (handles digits-only AND formatted forms)
- **Permission set skeleton** with the easy-to-forget standard objects pre-flagged (`ServiceAppointment`, `Opportunity`, `EmailMessage`, `Task`)
- **Test data factory + idempotent load script** so you can re-run setup safely
- **3 reusable Flow templates** — Case auto-assign, ServiceAppointment confirmation, Escalation Summary
- **Documentation** — voice-quality output rules, Golden Flow capture pattern, regression-test format

## Quick start

```bash
# 1. Create your demo from this template
gh repo create <your-org>/<customer>-voice-demo --template gabo3110-afk/agentforce-voice-demo-template --public --clone
cd <customer>-voice-demo

# 2. Find/replace the placeholders
./scripts/rename-brand.sh "Brand" "Toyota"   # or "Honda", "BMW", etc.

# 3. Authorize your demo org
sf org login web --alias <customer>-voice-demo
sf config set target-org <customer>-voice-demo

# 4. Read the skill's runbook before deploying — patterns matter
# Loads with the SKILL.md from ~/.claude/skills/sf-ai-agentforce-voice-demo/

# 5. Customize: agent customer-specific data, Golden Flow cases, brand voice
# - force-app/main/default/aiAuthoringBundles/*/.agent — system prompt, subagents
# - force-app/main/default/classes/<Brand>Constants.cls — eligibility lists, error messages
# - scripts/apex/load-test-data.apex — your demo customers
# - docs/golden-flow.md — your 8 confirmed dialogue cases

# 6. Deploy phase by phase (see scaffolding-checklist.md from skill)
sf project deploy start -d force-app/main/default/objects -d force-app/main/default/permissionsets -o <org>
sf org assign permset --name <Brand>_Agent_Actions --target-org <org>
sf apex run -f scripts/apex/load-test-data.apex --target-org <org>
sf project deploy start -d force-app/main/default/classes -d force-app/main/default/flows -o <org>
sf project deploy start -d force-app/main/default/aiAuthoringBundles -o <org>

# 7. Validate + publish + activate the agent (always all three!)
sf agent validate authoring-bundle --json --api-name <Brand>_Voice_Orchestrator -o <org>
sf agent publish authoring-bundle --json --api-name <Brand>_Voice_Orchestrator -o <org>
sf agent activate --json --api-name <Brand>_Voice_Orchestrator -o <org>

# 8. Walk your Golden Flow live
sf agent preview start --json --use-live-actions --authoring-bundle <Brand>_Voice_Orchestrator -o <org>
sf agent preview send --json --authoring-bundle <Brand>_Voice_Orchestrator --session-id <SID> -u "<utterance>" -o <org>
```

## Customization checklist

Search-and-replace these placeholders across the repo:

| Placeholder | Replace with | Where it appears |
|---|---|---|
| `<Brand>` / `<BRAND>` | Customer brand name (PascalCase) | Apex class names, custom object names, permset, .agent |
| `<brand>` | lowercase brand name | Asset paths, file names |
| `<DOMAIN_1>`, `<DOMAIN_2>`, ... | Your subagent names | `.agent` file (after_sales, billing, warranty, etc.) |
| `<EINSTEIN_AGENT_USERNAME>` | Real Einstein Agent User from your org | `.agent` config block |
| `<USE CASE>` | Short description | `.agent` config description, README |

The `scripts/rename-brand.sh` helper does the most common replacements in one shot.

## Architecture

This scaffold encodes a hub-and-spoke architecture proven on a multi-domain voice POC:

```
              start_agent agent_router (hub)
                        │
       ┌────────┬──────┴──────┬────────┐
       ▼        ▼             ▼        ▼
   domain_1  domain_2  ...   domain_N  guardrails
   (Apex action +              (off_topic, ambiguous,
    voice-quality                escalation)
    output_es/pt)
```

Key patterns:

1. **Hub** = `start_agent agent_router`. Welcomes, classifies intent, transitions.
2. **Spokes** = 5-10 domain subagents, each owning 1-3 Apex actions and one set of conversational responsibilities.
3. **`active_topic` variable** = hub auto-routes back to the in-flight subagent on follow-up turns. Without this, multi-turn dialogues break.
4. **Apex output IS the voice script** = your action's `output_es` / `output_pt` strings are what the agent speaks. Make them voice-quality.

Full architecture documentation in [docs/architecture.md](docs/architecture.md).

## What's NOT in this template

By design:
- **Customer-specific data** — you bring the Golden Flow, dialogue scripts, brand voice rules
- **Customer-specific cases** — the action templates are skeletons, not implementations
- **Channel wiring** — Service Cloud Voice / Messaging configuration is org-specific
- **LWC components** — Customer 360 UI is per-demo; not generalized here

For an end-to-end Toyota Argentina + Brazil reference implementation that uses this scaffold, ping `@gabo3110-afk` for the private repo link.

## File structure

```
.
├── README.md                                  ← you are here
├── sfdx-project.json
├── force-app/main/default/
│   ├── aiAuthoringBundles/
│   │   └── Brand_Voice_Orchestrator/
│   │       ├── Brand_Voice_Orchestrator.agent       ← .agent skeleton (hub-and-spoke)
│   │       └── Brand_Voice_Orchestrator.bundle-meta.xml
│   ├── classes/
│   │   ├── BrandConstants.cls                  ← language constants, eligibility lists, error msgs
│   │   ├── BrandCustomerLookup.cls             ← format-tolerant DNI/CPF/plate resolver
│   │   ├── BrandGet*.cls                       ← 13 invocable action templates
│   │   ├── BrandSend*.cls
│   │   ├── BrandCreate*.cls
│   │   ├── BrandSchedule*.cls
│   │   ├── VoiceFormatter.cls                  ← bilingual number-to-words utility
│   │   └── *.cls-meta.xml
│   ├── objects/                                ← sample custom-object templates
│   ├── permissionsets/
│   │   └── Brand_Agent_Actions.permissionset-meta.xml
│   ├── flows/                                  ← Case auto-assign, escalation, service confirmation
│   ├── labels/CustomLabels.labels-meta.xml
│   └── translations/pt_BR.translation-meta.xml
├── scripts/
│   ├── apex/
│   │   ├── load-test-data.apex                 ← idempotent test data loader
│   │   └── rename-brand.sh                     ← search-and-replace helper
│   └── data/                                   ← sample CSVs (skeleton)
├── docs/
│   ├── architecture.md                         ← hub-and-spoke explained
│   ├── golden-flow-template.md                 ← capture format for your demo cases
│   ├── voice-quality-rules.md                  ← what makes a string speakable
│   └── skill-pointer.md                        ← link to the runbook skill
└── .github/
    └── workflows/
        └── validate.yml                        ← GitHub Action to validate metadata on PR
```

## Contributing

Improvements welcome. Patterns that helped you ship a voice demo and aren't here yet → PR with a reference to the use case.

## License

MIT — see [LICENSE](LICENSE).

## Origin

Extracted from the Toyota Argentina + Brazil Agentforce Voice POC (May 2026). The 20 runtime patterns this scaffold encodes were discovered across 17 `.agent` versions of debugging — see the [`sf-ai-agentforce-voice-demo`](https://github.com/gabo3110-afk/agentforce-voice-demo-template/blob/main/docs/skill-pointer.md) Claude skill for the full debugging journey.
