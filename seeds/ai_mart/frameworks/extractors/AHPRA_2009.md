# TinyFish Extraction Prompt — AHPRA_2009

> **Framework:** AHPRA Code of Conduct + AI practice guidance
> **Publisher:** Australian Health Practitioner Regulation Agency
> **Jurisdiction:** AU-HEALTH
> **Effective:** Code of Conduct 2014-03-17 (shared across Boards); AI-specific guidance emerging 2024-26
> **Stage:** Structural rows live; AI-specific CPD + notifiable-conduct guidance refresh monthly

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `AHPRA_2009` |
| `framework_publisher` | `Australian Health Practitioner Regulation Agency` |
| `jurisdiction_code` | `AU-HEALTH` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.ahpra.gov.au/Resources/Code-of-conduct.aspx` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.ahpra.gov.au/Resources/Code-of-conduct.aspx
  supplementary_urls:
    - https://www.ahpra.gov.au/About-Ahpra/What-We-Do/Statutory-Authority/Health-Practitioner-Regulation-National-Law.aspx
    - https://www.ahpra.gov.au/News/AI-in-healthcare.aspx
    - https://www.ahpra.gov.au/Notifications.aspx
  content_type: auto
  timeout_seconds: 90
```

## 3. Extraction prompt

```
Extract obligations on registered health practitioners when using AI.

Control ID pattern: AHPRA.<AREA> where AREA ∈ {PROF_RESP, COMPETENCE,
INFORMED_CONSENT, CONFIDENTIALITY, SCOPE_OF_PRACTICE, EVIDENCE_BASED,
ADVERTISING, NOTIFIABLE, CPD, RECORDKEEPING}.

Obligation family mapping:
  PROF_RESP         → accountability
  COMPETENCE        → human_oversight
  INFORMED_CONSENT  → transparency
  CONFIDENTIALITY   → data_governance
  SCOPE_OF_PRACTICE → accountability
  EVIDENCE_BASED    → testing_monitoring
  ADVERTISING       → transparency
  NOTIFIABLE        → redress
  CPD               → human_oversight
  RECORDKEEPING     → recordkeeping

Key invariant:
- AI never transfers professional liability. Clinician remains accountable.
  This anchors most row descriptions.
```

## 4. Edge cases

1. AHPRA covers 16+ health professions through separate Boards — some obligations are Board-specific (e.g. Medical Board publishes medical-specific AI guidance). Capture Board attribution in `notes` when material.
2. Notifiable conduct is defined in the National Law Part 8 — AI misuse obligations are being interpreted by Boards as tribunal cases emerge. Refresh monthly.
3. CPD registration standards vary by profession — AI-specific CPD expectations are in early stages across Boards.
