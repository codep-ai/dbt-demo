# TinyFish Extraction Prompt — VIC_NSW_HEALTH_AI_2025

> **Framework:** Victorian DFFH + NSW Health AI use policies
> **Publisher:** VIC Department of Families, Fairness and Housing + NSW Ministry of Health
> **Jurisdiction:** AU-HEALTH-STATE
> **Effective:** Rolling 2024-25 (NSW AI Assurance Framework + VIC AI guidance aligned to NSW AIAF)
> **Stage:** Rapidly evolving — refresh **monthly**

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `VIC_NSW_HEALTH_AI_2025` |
| `framework_publisher` | `VIC DFFH + NSW Ministry of Health` |
| `jurisdiction_code` | `AU-HEALTH-STATE` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.health.nsw.gov.au/aihealth/Pages/default.aspx` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.health.nsw.gov.au/aihealth/Pages/default.aspx
  supplementary_urls:
    - https://www.digital.nsw.gov.au/policy/artificial-intelligence
    - https://www.vic.gov.au/ai-use-policy
    - https://www.health.vic.gov.au/publications/health-services-policy
  content_type: auto
  timeout_seconds: 120
  javascript: enabled
```

## 3. Extraction prompt

```
Extract AI use obligations specific to Victorian + NSW public health
services. Cover the intersection of state AI assurance frameworks with
health-specific guidance.

Control ID pattern: STATE.<AREA>

Obligation family mapping:
  STATE.APPROVAL              → accountability
  STATE.RISK_TIER             → impact_assessment
  STATE.PIA                   → impact_assessment
  STATE.EQUITY                → impact_assessment
  STATE.WORKFORCE             → human_oversight
  STATE.PROCUREMENT           → third_party_supply_chain
  STATE.INCIDENT_REPORT       → recordkeeping
  STATE.TRANSPARENCY_REGISTER → transparency
  STATE.CONSUMER_PART         → accountability
  STATE.DATA_SHARING          → data_governance

Invariants:
- Aboriginal + Torres Strait Islander health equity assessment is
  required — not optional. Preserve wording.
- State privacy regimes (VIC PDPA, NSW PPIP Act + HRIP Act) layer on top
  of Commonwealth Privacy Act.
```

## 4. Edge cases

1. NSW AI Assurance Framework applies cross-government; health-specific overlay published separately. Capture both.
2. VIC guidance references NSW AIAF — don't duplicate rows; create VIC-specific rows only where VIC departs.
3. Pilot-phase obligations (public AI registers) may appear then be ratified — preserve pilot flag in `notes`.
