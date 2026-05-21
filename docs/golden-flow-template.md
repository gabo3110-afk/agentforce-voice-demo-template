# Golden Flow Capture Template

Before any code: lock in the demo's "Golden Flow" — the exact verified utterances and expected agent responses for each demo case. Without this, the demo team and the AI engineer iterate on different mental models and the demo never converges.

Copy this template, fill it in for your demo, and use it as the regression-test baseline.

---

## Demo metadata

- **Customer:** <Customer Name>
- **Demo date:** <YYYY-MM-DD>
- **Demo location:** <city / venue>
- **Languages:** <es-AR | pt-BR | ...>
- **Phase 1 cases:** <count>
- **Phase 1 duration:** ~25 minutes
- **Phase 2 (unscripted):** ~5 minutes

---

## Confirmed cases — Phase 1

For each case, capture:

### Case 1 — <Short title>

**Country:** <AR | BR | ...>
**Risk:** <LOW | MEDIUM | HIGH>
**Customer:** <Demo Customer 1>
**Reference data:**
- ID: <DNI / CPF / etc.>
- Vehicle: <model / VIN / chassi>
- Other: <plan group / order number / etc.>

**Critical rules:**
- Rule 1 (e.g., "no home delivery — pickup at dealership only")
- Rule 2 (e.g., "if caller is elderly, do not pressure to install app")

**Dialogue (verified):**

| Turn | Speaker | Verified message |
|---|---|---|
| 1 | 👤 | <exact caller utterance> |
| 1 | 🤖 | <exact agent reply with **bold** on data points> ⚙ `<action_name>(input1="...")` |
| 2 | 👤 | <next utterance> |
| 2 | 🤖 | <next reply> |

---

### Case 2 — <next case>

(repeat for each case)

---

## Phase 2 (unscripted) scenarios to dry-run

The customer WILL push these. Walk them in your dry run before demo day:

| Scenario | Sample utterance | What you're testing |
|---|---|---|
| Regional slang | <local slang sample> | Tolerance + appropriate register |
| Barge-in / interruption | (mid-response) "espera, no es eso" | Voice channel handles transport, agent picks up new info |
| Emotional escalation | "¡Esto es absurdo, dame un humano YA!" | Empathetic acknowledgment + escalation flow triggers |
| Confused caller | "no entiendo, soy mayor, no tengo app" | No app pressure, voice-only alternatives |
| False information | "ah pero <BRAND> no cubre el motor" | Polite correction with official data |
| Out of scope | "¿cuánto cuesta un <competitor model>?" | Brand-only redirect |
| System down | (simulate Apex error) | Graceful escape: "Te paso con un especialista..." |

## Voice quality rules

Refer to [voice-quality-rules.md](voice-quality-rules.md) for the full rule set. Highlights:

- ≤25 words per turn
- No markdown, no URLs, no system terminology
- Numbers spoken naturally (not "$164,800" but "ciento sesenta y cuatro mil ochocientos pesos")
- Dates spoken naturally ("el 31 de enero", not "31/01/2026")
- Never close the call — wait for caller confirmation
- Brand-only — no competitor mentions

## Brand voice fingerprint

Document for the agent's `system.instructions` block:

- **Register:** <formal | warm | casual | professional>
- **Address forms:** <vos | tú | usted | você>
- **Common greetings:** <"¡Hola!" | "Olá!" | ...>
- **Closing pattern:** <"¡Que tengas un buen día y seguí disfrutando tu <Brand>!">

Be specific. Generic system prompts produce generic-sounding agents.

## Test data inventory

For each case, list the records in your demo org that support the flow. After deploying via `scripts/apex/load-test-data.apex`, verify:

```bash
sf data query --query "SELECT Name, DNI__c, CPF__c, Country_Code__c FROM Account WHERE Country_Code__c IN ('AR','BR') ORDER BY Country_Code__c, Name" --target-org <org>
sf data query --query "SELECT COUNT(Id) total FROM Brand_Warranty__c" --target-org <org>
sf data query --query "SELECT COUNT(Id) total FROM Brand_Savings_Plan__c" --target-org <org>
# ... etc.
```

Numbers should match what `load-test-data.apex` claims it created.

## Pre-demo checklist (T-48 hours)

- [ ] Walk every Phase 1 case live in `sf agent preview` against the **published + activated** agent
- [ ] Capture verified turn-by-turn dialogues — these become your regression-test baseline
- [ ] Dry-run all Phase 2 scenarios — fix any that break
- [ ] Verify Voice channel (Service Cloud Voice / messaging) handshake — phone-call latency differs from text preview
- [ ] Confirm permset assignment on the Einstein Agent User
- [ ] Check that the **Active version is the latest** (forgetting `sf agent activate` is the #1 demo-day disaster)
- [ ] Pre-stage demo accounts in the Customer 360 LWC (if applicable) so the screen looks populated when the demo starts
