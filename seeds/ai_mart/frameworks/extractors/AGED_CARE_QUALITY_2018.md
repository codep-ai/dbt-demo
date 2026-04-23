# TinyFish Extraction Prompt — AGED_CARE_QUALITY_2018

> **Framework:** Aged Care Quality Standards + Royal Commission AI recommendations
> **Publisher:** Aged Care Quality and Safety Commission
> **Jurisdiction:** AU-HEALTH
> **Effective:** 2019-07-01 (current 8 Standards); Royal Commission Final Report 2021
> **Stage:** Top-level on 8 Standards; AI + SIRS interactions still crystallising

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `AGED_CARE_QUALITY_2018` |
| `framework_publisher` | `Aged Care Quality and Safety Commission` |
| `jurisdiction_code` | `AU-HEALTH` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.agedcarequality.gov.au/providers/standards` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.agedcarequality.gov.au/providers/standards
  supplementary_urls:
    - https://www.agedcarequality.gov.au/sirs
    - https://agedcare.royalcommission.gov.au/publications/final-report
    - https://www.agedcarequality.gov.au/providers/assessment-processes
  content_type: auto
  timeout_seconds: 90
```

## 3. Extraction prompt

```
Extract obligations from the 8 Aged Care Quality Standards that apply
when AI is used in aged care delivery (monitoring, assistive tech,
decision support, surveillance).

Control ID pattern: ACQ.<N>.<THEME> where N ∈ 1..8; plus ACQ.RC_REC
(Royal Commission recommendations), ACQ.INCIDENT_MGMT (SIRS),
ACQ.CONSENT_SURV, ACQ.RECORDS.

Obligation family mapping:
  Standard 1 (Consumer Dignity & Choice) → accountability
  Standard 2 (Ongoing Assessment)         → human_oversight
  Standard 3 (Personal & Clinical Care)   → risk_management
  Standard 4 (Services for Daily Living)  → human_oversight
  Standard 5 (Organisation Environment)   → transparency (surveillance disclosure)
  Standard 6 (Feedback & Complaints)      → redress
  Standard 7 (Human Resources)            → human_oversight
  Standard 8 (Organisational Governance)  → accountability

Anchors:
- Royal Commission rec. 107 (assistive technology) + rec. 14 (data rights)
  are active policy drivers.
- SIRS (Serious Incident Response Scheme) Guidelines 2021 cover reportable
  incidents including AI-contributing events.
```

## 4. Edge cases

1. New Aged Care Act (phased introduction from 2026) will modify these Standards — watch for supersession signals.
2. Distinction between residential, community, CHSP providers — some obligations scope-specific; note in `notes`.
3. Royal Commission recommendations are advisory but shape Commission regulatory priorities — treat as binding-in-effect.
