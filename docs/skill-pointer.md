# Companion Claude Skill

This template repo pairs with the [`sf-ai-agentforce-voice-demo`](https://github.com/anthropics/claude-code) Claude skill that documents the 20 runtime patterns this scaffold encodes.

## Installation

The skill lives at `~/.claude/skills/sf-ai-agentforce-voice-demo/` if installed locally. If you're on a Salesforce Claude Code rollout, it should already be available.

Verify it's loaded:
```bash
ls ~/.claude/skills/sf-ai-agentforce-voice-demo/SKILL.md
```

If missing, install:
```bash
# Clone the canonical source (TBD — replace with the published location once available)
git clone <skill-repo-url> ~/.claude/skills/sf-ai-agentforce-voice-demo
```

## Invocation

When working on a voice demo, invoke the skill:

```
/sf-ai-agentforce-voice-demo
```

The skill triggers automatically based on its description if you say things like:
- "I'm building a voice demo for <customer>"
- "The agent compiles but won't invoke the action"
- "How do I handle bilingual voice output"
- "Why isn't the agent staying in the subagent across turns"

## What the skill provides

| File | When to read |
|---|---|
| `SKILL.md` | Entry point + decision flow + 9-pattern summary |
| `references/runtime-patterns.md` | The 20 patterns. Read before debugging or extending an existing voice agent |
| `references/scaffolding-checklist.md` | New voice demo? Read first. SFDX layout, custom objects, permsets, test data, channel wiring |
| `references/voice-formatter-pattern.md` | Bilingual voice output. ES/PT number-to-words, currency, dates, ID formats |
| `references/test-utterances.md` | Golden Flow phrasing rules + the regression-test transcript pattern |

## How they relate

- **Skill** = the **brain** — patterns, anti-patterns, decisions, debugging guides
- **Repo** (this one) = the **body** — executable scaffold ready to deploy

Update them independently. The skill is the canonical source for the runtime patterns; this repo encodes them as working code.
