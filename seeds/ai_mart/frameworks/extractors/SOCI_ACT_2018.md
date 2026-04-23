# TinyFish Extraction Prompt — SOCI_ACT_2018

> **Framework:** Security of Critical Infrastructure Act 2018 (+ 2022/2023 amendments)
> **Publisher:** Department of Home Affairs — CISC
> **Jurisdiction:** AU-ENERGY
> **Effective:** 2018-07-11
> **Stage:** Complete on top-level; refresh for regulator updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `SOCI_ACT_2018` |
| `framework_publisher` | `Department of Home Affairs — CISC` |
| `jurisdiction_code` | `AU-ENERGY` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `energy` |
| `source_url` | `https://www.cisc.gov.au/legislation-regulation-and-compliance/soci-act-2018` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.cisc.gov.au/legislation-regulation-and-compliance/soci-act-2018
  supplementary_urls:
    - https://www.cisc.gov.au/critical-infrastructure-hub
    - https://www.legislation.gov.au/Details/C2023C00174
  content_type: auto
  javascript: enabled
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations from this framework that apply to AI systems used in
Australian energy sector operations (utilities, networks, O&G, renewables,
market operations).

Control ID pattern: SOCI.<AREA>  AREA ∈ {REGISTER, CIRMP, NOTIFY, GOV_ASSIST, SYSTEMS_NATIONAL, PERSONNEL, SUPPLY_CHAIN, PHYSICAL, CYBER_EXERCISES, BOARD_OVERSIGHT}

Obligation family mapping:
SOCI.REGISTER       → recordkeeping
SOCI.CIRMP          → risk_management
SOCI.NOTIFY         → redress (12h critical / 72h significant)
SOCI.GOV_ASSIST     → accountability
SOCI.SYSTEMS_NATIONAL → accountability
SOCI.PERSONNEL      → accountability
SOCI.SUPPLY_CHAIN   → third_party_supply_chain
SOCI.PHYSICAL       → risk_management
SOCI.CYBER_EXERCISES→ testing_monitoring
SOCI.BOARD_OVERSIGHT→ accountability

Invariants:
- industry_scope = 'energy' on every row.
- jurisdiction_code = 'AU-ENERGY' on every row.
- Where the obligation cross-refs another regulator's control (e.g.
  AESCSF citing SOCI, IEC 62443, AU Privacy APPs), preserve the
  cross-reference in `notes`.
```

## 4. Edge cases

1. SOCI applies to 11 critical sectors — energy is one; ensure rows specific to energy-sector CIRMP Rules.
2. SoNS (Systems of National Significance) adds obligations — tag.
3. CIRMP Rules are amended periodically — refresh monthly.
4. Notification thresholds: 12h critical impact / 72h significant — preserve.
