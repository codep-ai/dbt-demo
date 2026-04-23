# TinyFish Extraction Prompt — NOPSEMA_2024

> **Framework:** NOPSEMA Safety + Environmental Management (+ AI-in-safety guidance)
> **Publisher:** National Offshore Petroleum Safety and Environmental Management Authority
> **Jurisdiction:** AU-ENERGY
> **Effective:** 2009-01-01
> **Stage:** Complete on top-level; refresh for regulator updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `NOPSEMA_2024` |
| `framework_publisher` | `National Offshore Petroleum Safety and Environmental Management Authority` |
| `jurisdiction_code` | `AU-ENERGY` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `energy` |
| `source_url` | `https://www.nopsema.gov.au/safety` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.nopsema.gov.au/safety
  supplementary_urls:
    - https://www.nopsema.gov.au/environment
    - https://www.nopsema.gov.au/assets/guidelines
  content_type: auto
  javascript: enabled
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations from this framework that apply to AI systems used in
Australian energy sector operations (utilities, networks, O&G, renewables,
market operations).

Control ID pattern: NOPSEMA.<AREA>  AREA ∈ {SAFETY_CASE, HSE_AI, ENV_PLAN, WELL_OPS_AI, INCIDENT_REPORT, COMPETENCE, SIMOPS_AI, PROCESS_SAFETY, CYBER_OT, EMERGENCY}

Obligation family mapping:
NOPSEMA.SAFETY_CASE → risk_management
NOPSEMA.HSE_AI      → risk_management
NOPSEMA.ENV_PLAN    → testing_monitoring
NOPSEMA.WELL_OPS_AI → risk_management
NOPSEMA.INCIDENT_REPORT → recordkeeping
NOPSEMA.COMPETENCE  → human_oversight
NOPSEMA.SIMOPS_AI   → human_oversight
NOPSEMA.PROCESS_SAFETY → testing_monitoring (SIL)
NOPSEMA.CYBER_OT    → risk_management
NOPSEMA.EMERGENCY   → human_oversight

Invariants:
- industry_scope = 'energy' on every row.
- jurisdiction_code = 'AU-ENERGY' on every row.
- Where the obligation cross-refs another regulator's control (e.g.
  AESCSF citing SOCI, IEC 62443, AU Privacy APPs), preserve the
  cross-reference in `notes`.
```

## 4. Edge cases

1. Applies only to offshore petroleum facilities — Santos / Woodside / Chevron AU tier.
2. Process safety AI intersects with IEC 61508/61511 SIL levels.
3. Cyber-safety integration (joint NOPSEMA/CISC guidance 2023) is a growing area.
