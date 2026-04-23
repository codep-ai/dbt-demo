# TinyFish Extraction Prompt — AESCSF_2025

> **Framework:** Australian Energy Sector Cyber Security Framework (AESCSF)
> **Publisher:** AEMO / Department of Home Affairs (CISC)
> **Jurisdiction:** AU-ENERGY
> **Effective:** 2018-06-01
> **Stage:** Complete on top-level; refresh for regulator updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `AESCSF_2025` |
| `framework_publisher` | `AEMO / Department of Home Affairs (CISC)` |
| `jurisdiction_code` | `AU-ENERGY` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `energy` |
| `source_url` | `https://aemo.com.au/initiatives/major-programs/cyber-security/aescsf-framework-and-resources` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://aemo.com.au/initiatives/major-programs/cyber-security/aescsf-framework-and-resources
  supplementary_urls:
    - https://www.cisc.gov.au/
    - https://aemo.com.au/initiatives/major-programs/cyber-security
  content_type: auto
  javascript: enabled
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations from this framework that apply to AI systems used in
Australian energy sector operations (utilities, networks, O&G, renewables,
market operations).

Control ID pattern: AESCSF.<DOMAIN>  using AESCSF's 11 domains (Risk Management, Asset Management, Identity and Access, Threat Management, etc.)

Obligation family mapping:
AESCSF.MIL                → accountability (MIL-1/2/3 maturity)
AESCSF.RISK_MGMT          → risk_management
AESCSF.ASSET_MGMT         → recordkeeping
AESCSF.IDENTITY_ACCESS    → accountability
AESCSF.THREAT_MGMT        → testing_monitoring
AESCSF.INCIDENT           → redress
AESCSF.SUPPLY_CHAIN       → third_party_supply_chain
AESCSF.WORKFORCE          → human_oversight
AESCSF.SITUATIONAL        → testing_monitoring
AESCSF.CSIRP              → risk_management
AESCSF.OT_SCADA_AI        → risk_management
AESCSF.INDEPENDENT_ASSURANCE → accountability

Invariants:
- industry_scope = 'energy' on every row.
- jurisdiction_code = 'AU-ENERGY' on every row.
- Where the obligation cross-refs another regulator's control (e.g.
  AESCSF citing SOCI, IEC 62443, AU Privacy APPs), preserve the
  cross-reference in `notes`.
```

## 4. Edge cases

1. MIL target depends on SOCI criticality banding — preserve mapping in notes.
2. AESCSF is binding via SOCI CIRMP rules for designated entities — flag which obligations are SOCI-triggered.
3. Joint AEMO/CISC publications; scrape both.
4. AI-specific overlay is in 2024-25 supplementary guidance — expect frequent updates.
