# TinyFish Extraction Prompt — NDIS_QUALITY_2018

> **Framework:** NDIS Quality and Safeguarding Framework (+ AI adaptations)
> **Publisher:** NDIS Quality and Safeguards Commission
> **Jurisdiction:** AU-HEALTH (disability services)
> **Effective:** 2018-07-01
> **Stage:** Structural; AI-specific practice-standards interpretation evolving

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `NDIS_QUALITY_2018` |
| `framework_publisher` | `NDIS Quality and Safeguards Commission` |
| `jurisdiction_code` | `AU-HEALTH` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.ndiscommission.gov.au/providers/ndis-practice-standards` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.ndiscommission.gov.au/providers/ndis-practice-standards
  supplementary_urls:
    - https://www.ndiscommission.gov.au/providers/incident-management-and-reportable-incidents
    - https://www.ndiscommission.gov.au/providers/worker-screening
    - https://www.ndiscommission.gov.au/participants/complaints
  content_type: auto
  timeout_seconds: 90
```

## 3. Extraction prompt

```
Extract obligations from the NDIS Practice Standards (Core Module +
Specialist modules) that apply when AI is used in disability service
delivery — support coordination, assistive technology, behaviour
support planning, information management.

Control ID pattern: NDIS.PS.<AREA> where AREA ∈ {RIGHTS, PROVIDER_GOV,
RISK, INCIDENT, COMPLAINTS, WORKFORCE, INFO_MGMT, SUPPORT_COORD,
SPEC_DISABIL, REPORTABLE}.

Obligation family mapping:
  RIGHTS         → accountability (participant choice re AI)
  PROVIDER_GOV   → accountability
  RISK           → risk_management
  INCIDENT       → redress
  COMPLAINTS     → redress
  WORKFORCE      → human_oversight
  INFO_MGMT      → data_governance
  SUPPORT_COORD  → transparency
  SPEC_DISABIL   → impact_assessment
  REPORTABLE     → redress

Invariants:
- Participants retain right to decline AI-mediated supports.
- Restrictive practices + AI-mediated surveillance have heightened
  oversight requirements.
```

## 4. Edge cases

1. Specialist modules (Specialist Behaviour Support, Early Childhood, Specialist Disability Accommodation) may layer obligations — note module attribution.
2. Worker Screening Database check is orthogonal to AI governance but connects in workforce competence for AI tool use.
3. Restrictive practice regulation (including AI-mediated) has state overlays on top of the federal framework.
