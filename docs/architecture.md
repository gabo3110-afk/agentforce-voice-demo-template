# Architecture — Hub-and-Spoke + active_topic

This scaffold encodes a hub-and-spoke architecture for Agentforce Voice agents, refined across 17 `.agent` versions of debugging on a real demo.

## The shape

```
                start_agent agent_router (the hub)
                         │
        ┌───────┬────────┼────────┬───────┐
        ▼       ▼        ▼        ▼       ▼
    after_   fleet_   savings_  warranty  ... (other domains)
    sales    rental   plan
        │       │        │        │
        └───────┴────────┴────────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
         off_topic  ambiguous_  escalation
                    question
```

**Hub** = `start_agent agent_router`. Welcomes, classifies intent, transitions to a domain subagent.

**Spokes (domain subagents)** = 5-10 subagents, each owning 1-3 Apex actions and one set of conversational responsibilities. Examples from typical voice POCs: `after_sales`, `fleet_rental`, `savings_plan`, `warranty`, `connected_titular`, `sales_orders`, `technical_lookup`.

**Guardrails** = `off_topic`, `ambiguous_question`, `escalation`. Reachable from the hub at any time.

## Why hub-and-spoke

- **Each subagent has 2-5 actions visible to the LLM**, not 13-20. Smaller toolset = better tool-call accuracy.
- **Each subagent has its own conversational rules** (no app pressure for elderly callers in `fleet_rental`, PII redaction in `connected_titular`, no chronic-issue confirmations in `warranty`).
- **Adding a new domain doesn't risk regressing existing ones.** Each spoke is independent.

## The `active_topic` variable — required for multi-turn

The Agentforce runtime restarts at `start_agent` on every user turn. Without state, follow-up messages ("estoy en Caballito", "Sí, mandámelo") fail to re-route to the appropriate subagent because the LLM doesn't have context to know "we were in fleet_rental".

### Variable declaration
```yaml
variables:
    active_topic: mutable string = ""
        description: "Currently in-flight domain subagent. Used for multi-turn routing."
```

### Hub auto-route
```yaml
start_agent agent_router:
    before_reasoning:
        if @variables.active_topic == "fleet_rental":
            transition to @subagent.fleet_rental
        if @variables.active_topic == "savings_plan":
            transition to @subagent.savings_plan
        # ... one per domain
```

### Each domain claims the topic on entry
```yaml
subagent fleet_rental:
    before_reasoning:
        set @variables.active_topic = "fleet_rental"
```

### Why this works
1. Turn 1: user says "I want to rent a car". Agent enters `agent_router`, picks `go_to_fleet_rental`, transitions to `fleet_rental`. The subagent's `before_reasoning` sets `active_topic = "fleet_rental"`. Subagent asks for zone.
2. Turn 2: user says "I'm in zone1". Runtime restarts at `start_agent`. The hub's `before_reasoning` sees `active_topic == "fleet_rental"` and immediately transitions back to `fleet_rental`. The user's "I'm in zone1" lands in `fleet_rental` where the action lives, and the LLM extracts `zone="zone1"` and invokes the action.

Without `active_topic`, the user's "I'm in zone1" would land at `agent_router`, the LLM would try to classify it (sounds like context, not an intent), and either:
- Hallucinate a "let me check that for you" without invoking
- Route to `ambiguous_question`
- Pick a random sibling subagent

## Bilingual output via `output_es` / `output_pt`

Every Apex action's `Response` class includes both `output_es` and `output_pt` String fields. The agent picks based on caller language:

```apex
public class Response {
    @InvocableVariable public Boolean success;
    @InvocableVariable public String output_es;   // Spanish-rioplatense voice script
    @InvocableVariable public String output_pt;   // Portuguese-paulistano voice script
    @InvocableVariable public String error_message;
    // ... domain-specific outputs
}
```

The action constructs both strings using `VoiceFormatter` for natural-language number/date formatting. The LLM reads the appropriate one almost verbatim. This is more reliable than relying on the LLM to compose voice-quality responses from raw record data.

## Three layers of action-invocation discipline

Action descriptions alone don't reliably get the LLM to invoke. Three layers combined work:

### Layer 1: Topic-level action description
```yaml
brand_get_service_history:
    description: "Return last 5 service appointments. EXTRACT the patente from the caller's most recent message and pass it as the 'patente' input. Example: caller says 'la patente es AD 544 VI' → patente='AD 544 VI'. NEVER call this action with all empty inputs."
```

### Layer 2: Subagent reasoning instructions
```yaml
subagent after_sales:
    reasoning:
        instructions: ->
            | PROTOCOLO OBLIGATORIO:
              PASO 1 — Si el cliente mencionó la patente, INMEDIATAMENTE invocá brand_get_service_history.
              PASO 2 — Si NO mencionó, pedí UNA en una pregunta corta.
              PROHIBIDO:
              - Decir "estoy buscando" sin haber invocado la acción.
              - Inventar "no encontré" sin haber llamado la acción.
```

### Layer 3: Action-binding description
```yaml
actions:
    brand_get_service_history: @actions.brand_get_service_history
        description: "Look up service history NOW for the patente the caller just mentioned. Always invoke when patente is provided."
        with patente = ...
```

All three layers are needed. Without layer 2 the LLM goes conversational. Without layer 1 it calls with empty args. Without layer 3 it ignores the action.

## Identity gate (deferred for the demo)

Real identity verification (DNI/CPF lookup) was attempted with multiple patterns and consistently failed because the LLM in this runtime can't reliably slot-fill identity from natural language utterances.

The pragmatic pattern: bypass the identity gate for the demo, defer real verification to channel-injected `MessagingSession` context for production.

```yaml
variables:
    identified: mutable boolean = True
        description: "Identity gate. Default True for the demo — production will populate from MessagingSession context."
```

When the Voice channel is wired, the `MessagingSession.MessagingEndUserId` linked variable pre-populates caller identity from the channel layer, before the LLM has to slot-fill it. Replace the bypass once Voice is wired.

## Permission set structure

The agent's runtime user (Einstein Agent User) only sees what the permset grants. Required:

- All custom objects your actions query
- `Account`, `Contact`, `Asset`, `Case`
- **`ServiceAppointment`** (if service-history flows) ← easy to forget
- **`Opportunity`** (if order-status flows) ← easy to forget
- `EmailMessage` + `Task` (with create) if any action sends emails

See [`force-app/main/default/permissionsets/Brand_Agent_Actions.permissionset-meta.xml`](../force-app/main/default/permissionsets/Brand_Agent_Actions.permissionset-meta.xml) for the full skeleton.

## Anti-patterns to avoid

- **`WITH SECURITY_ENFORCED` in agent-invoked Apex** — throws when the agent user lacks FLS on any field; remove it
- **`with sharing` on Opportunity-reading actions** — Opportunity OWD is often Private; switch to `without sharing` for cross-account read actions
- **Set.contains() for vehicle-model eligibility** — real data ("ModelC XEi G12") needs substring match, not exact
- **`Account.FirstName` for Business Accounts** — null on Business Account; derive from `Account.Name.split(' ')[0]`
- **LongTextArea / multi-select picklist in `WHERE LIKE`** — Salesforce rejects; filter on Topic/Tags only
- **Forgetting to `sf agent activate` after `sf agent publish`** — leaves you testing v17 while org runs v3

See the [`sf-ai-agentforce-voice-demo`](skill-pointer.md) skill's `runtime-patterns.md` for all 20 patterns with examples.
