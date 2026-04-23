# TinyFish Extraction Prompt — NSQHS_STANDARDS_2021

> **Framework:** National Safety and Quality Health Service Standards (2nd ed.)
> **Publisher:** Australian Commission on Safety and Quality in Health Care (ACSQHC)
> **Jurisdiction:** AU-HEALTH
> **Effective:** 2021-09-01 (2nd edition, current)
> **Stage:** Top-level by 8 standards; AI-specific action items evolving

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `NSQHS_STANDARDS_2021` |
| `framework_publisher` | `Australian Commission on Safety and Quality in Health Care` |
| `jurisdiction_code` | `AU-HEALTH` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.safetyandquality.gov.au/standards/nsqhs-standards` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.safetyandquality.gov.au/standards/nsqhs-standards
  supplementary_urls:
    - https://www.safetyandquality.gov.au/standards/nsqhs-standards/actions
    - https://www.safetyandquality.gov.au/our-work/digital-transformation
  content_type: auto
  timeout_seconds: 90
```

## 3. Extraction prompt

```
Extract obligations from the 8 NSQHS Standards that apply to AI-mediated
care in Australian accredited health services.

Control ID pattern: NSQHS.<STD>.<THEME>
  STD ∈ 1..8  (1 Clinical Governance, 2 Partnering with Consumers,
              3 Preventing Healthcare Infection, 4 Medication Safety,
              5 Comprehensive Care, 6 Communicating for Safety,
              7 Blood Management, 8 Recognising & Responding to
              Acute Deterioration)
  THEME = short suffix (GOV, RISK, INCIDENT, WORKFORCE, CONSENT, …)

Obligation family mapping (broad-brush, refine per control):
  Standard 1 — accountability | risk_management | recordkeeping | human_oversight
  Standard 2 — transparency | accountability
  Standard 3 — risk_management
  Standard 4 — risk_management (AI prescribing/dosing)
  Standard 5 — recordkeeping | human_oversight | testing_monitoring
  Standard 6 — transparency (handover/comms)
  Standard 7 — human_oversight
  Standard 8 — human_oversight | testing_monitoring (early warning scores)

For each "Action" referenced in the standard that has an AI angle, produce
one row. Cite the Action number verbatim (e.g. "NSQHS Standard 5 Action 5.04").
```

## 4. Edge cases

1. ACSQHC publishes themed guidance (digital transformation, AI) separately from the core standards — fold relevant cross-references into `notes`.
2. Accreditation cycle — standards apply only to organisations accredited by approved accrediting agencies; flag if an obligation is audit-checked.
3. Some Actions bind based on service type (hospital vs day procedure vs community) — preserve in `notes`.
