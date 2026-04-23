# TinyFish Extraction Prompt — MY_HEALTH_RECORDS_2012

> **Framework:** My Health Records Act 2012 + OAIC health record guidance
> **Publisher:** Australian Digital Health Agency (ADHA) + Office of the Australian Information Commissioner (OAIC)
> **Jurisdiction:** AU-HEALTH
> **Effective:** 2012-06-26 (original); amended 2018, 2023
> **Stage:** Complete on top-level obligations; refresh quarterly for ADHA operational-requirement updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `MY_HEALTH_RECORDS_2012` |
| `framework_publisher` | `Australian Digital Health Agency + OAIC` |
| `jurisdiction_code` | `AU-HEALTH` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.legislation.gov.au/Details/C2023C00321` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.legislation.gov.au/Details/C2023C00321
  supplementary_urls:
    - https://www.digitalhealth.gov.au/initiatives-and-programs/my-health-record
    - https://www.oaic.gov.au/privacy/notifiable-data-breaches
    - https://www.digitalhealth.gov.au/sites/default/files/documents/system-operator-participation-agreement.pdf
  content_type: auto
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations that apply to AI systems interacting with My Health Record data.

Control ID pattern: MHR.<AREA> where AREA ∈ {REGISTRATION, CONSENT,
AUTHORISED_PURPOSE, ACCESS_LOG, DATA_BREACH, ONSHORE, DE_ID, SECURITY,
HPI_MATCH, OAIC_OVERSIGHT, AUDIT_ACCESS, CHILD_PROTECTION}.

Obligation family mapping:
  MHR.REGISTRATION      → accountability
  MHR.CONSENT           → accountability
  MHR.AUTHORISED_PURPOSE→ accountability
  MHR.ACCESS_LOG        → recordkeeping
  MHR.DATA_BREACH       → redress
  MHR.ONSHORE           → data_governance    (CRITICAL — data residency)
  MHR.DE_ID             → data_governance
  MHR.SECURITY          → risk_management
  MHR.HPI_MATCH         → risk_management
  MHR.OAIC_OVERSIGHT    → accountability
  MHR.AUDIT_ACCESS      → recordkeeping
  MHR.CHILD_PROTECTION  → human_oversight

Invariants:
- Cross-reference AU_PRIVACY_APPS where the obligation derives from Privacy
  Act + MHR overlay — preserve reference in `notes`.
- The onshore-data-residency obligation (MHR.ONSHORE) is load-bearing for
  our customer-hosted deployment story — never soften language.
```

## 4. Edge cases

1. Multiple amendment acts (2015, 2018, 2023) — capture cumulative effective version.
2. System Operator (ADHA) publishes operational "Participation Agreement" updates independently of legislation — scrape `digitalhealth.gov.au` for these.
3. Sensitive health records (e.g. mental health, termination, HIV status) carry heightened restrictions — flag in `notes`.
