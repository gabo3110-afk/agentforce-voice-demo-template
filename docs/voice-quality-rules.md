# Voice Quality Rules

What makes a string speakable. Apply to every `output_es` / `output_pt` returned by an Apex action.

## Hard rules

1. **≤25 words per turn.** Voice agents that ramble lose the caller.
2. **No markdown.** No `**bold**`, no `*italic*`, no `[links]`, no bullet lists. Speak in sentences.
3. **No URLs.** "Visit <brand>plan.example.com" doesn't work in voice. Either say it digit-by-digit or describe it ("on our official website").
4. **No system terminology.** Never reveal "Salesforce", "Apex", "object", "record", "API", error stack traces, or internal class names.
5. **Brand-only.** No mentions of competitor brands. If caller compares, redirect: "Mi especialidad es ayudarte con todo lo relacionado con <Brand>."
6. **Don't close the call.** Always wait for caller confirmation. End with a question or invitation: "¿Te ayudo con algo más?"

## Numbers

Convert digits to spoken words via `VoiceFormatter`:

| Don't | Do |
|---|---|
| "$164,800" | "ciento sesenta y cuatro mil ochocientos pesos" |
| "1336 days" | "mil trescientos treinta y seis días" |
| "+541145551234" | "más cinco cuatro uno..." (digit-by-digit) |
| "30%" | "treinta por ciento" |

The `VoiceFormatter` class in this template handles Spanish and Portuguese. Currency words: "pesos" (ARS), "reais" (BRL), "pesos mexicanos" (MXN), "euros" (EUR). Default based on caller's country.

## Dates

| Don't | Do |
|---|---|
| "31/01/2026" | "el 31 de enero" |
| "2026-05-28" | "el 28 de mayo" |
| "Tuesday" (in PT context) | "terça-feira" |

Drop the year unless business-relevant. Most voice replies sound natural without it.

## Times

| Don't | Do |
|---|---|
| "10:00" | "a las diez" or "a las diez horas" |
| "14:30" | "a las dos y media de la tarde" |

For specific business hours, use the regional convention: 24-hour clock for formal, 12-hour with AM/PM for casual.

## Plate / VIN / chassi reading

When repeating an alphanumeric back to the caller, speak character-by-character but smoothly. Don't pause too much:

| Don't | Do |
|---|---|
| "AD544VI" (mashed together) | "AD cinco cuatro cuatro VI" or "AD 544 VI" naturally |
| "Bravo Echo Four Lima..." (NATO alphabet — too formal) | Just read letters as Spanish/Portuguese letter sounds |

## Brand voice — Spanish rioplatense (Argentina)

- **Voseo:** vos, tenés, podés, querés, decime, fijate, mandame
- **Avoid:** tú, tienes, puedes, quieres
- **Register:** professional but warm. Not slangy, not stiff.
- **Confirmation:** "Dale", "Perfecto", "Listo"
- **Avoid:** "okey", "okay" (sound non-native)

## Brand voice — Portuguese paulistano (Brazil)

- **Form:** você (always), nunca tu
- **Register:** direto e acolhedor
- **Confirmation:** "Pronto", "Combinado", "Perfeito"
- **Avoid:** "tu", overly formal Portuguese (sounds European, not Brazilian)

## PII handling in voice output

When an action's `output_*` field contains data the agent shouldn't read aloud (prior owner's name, sensitive medical info, etc.), redact at the **subagent prompt layer**, not in Apex.

**Apex returns full data:**
```apex
res.output_es = 'La unidad está registrada a nombre de <PRIOR_TITULAR_NAME>. Para hacer el cambio...';
```

**Subagent prompt redacts:**
```yaml
subagent connected_titular:
    reasoning:
        instructions: ->
            | NUNCA expongas el nombre del titular anterior en la respuesta de voz.
              Si el sistema devuelve un titular distinto al que llama, paraphraseá como "otro titular" — no leas el nombre completo.
```

Result: the agent reads action output as context, paraphrases per the instruction, and says "otro titular" in voice.

## Empathy + escalation phrases

Memorize these. They're the right phrasing for the demo flows.

| Scenario | Phrasing |
|---|---|
| System unavailable | "En este momento no puedo acceder al sistema. Te paso con un especialista para que te ayude de inmediato. ¿Podés esperar un momento?" |
| Out of scope | "Esa consulta escapa a lo que puedo ayudarte hoy. ¿Puedo orientarte sobre <domains>?" |
| Competitor mention | "Mi especialidad es ayudarte con todo lo relacionado con <Brand>. Para comparaciones con otras marcas, consultá directamente con cada fabricante." |
| Data not found | "No pude encontrar ese dato en el sistema con la información que me diste. ¿Podrías darme otro dato, como la patente, el DNI o el grupo y orden del plan?" |
| Caller emotional | "Entiendo perfectamente, vamos a resolverlo. Te paso con un especialista para que te ayude de inmediato." |
| Elderly without app | "Bárbaro, podés gestionarlo todo por teléfono conmigo. No hace falta instalar nada." |

## Test the voice quality

Run the action directly via anonymous Apex and **read the `output_*` aloud yourself**:

```apex
BrandGetServicePrice.Request req = new BrandGetServicePrice.Request();
req.vehicle_model = 'ModelA';
req.service_km = 90000;
req.country = 'AR';
BrandGetServicePrice.Response r = BrandGetServicePrice.getServicePrice(new List<BrandGetServicePrice.Request>{req})[0];
System.debug(r.output_es);
```

If you stumble reading it, the customer will too. Edit the Apex output until it flows naturally.
