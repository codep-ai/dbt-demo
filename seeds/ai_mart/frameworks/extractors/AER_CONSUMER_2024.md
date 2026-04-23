# TinyFish Extraction Prompt — AER_CONSUMER_2024

> **Framework:** AER consumer protection + retail AI guidance
> **Publisher:** Australian Energy Regulator
> **Jurisdiction:** AU-ENERGY
> **Effective:** 2020-01-01
> **Stage:** Complete on top-level; refresh for regulator updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `AER_CONSUMER_2024` |
| `framework_publisher` | `Australian Energy Regulator` |
| `jurisdiction_code` | `AU-ENERGY` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `energy` |
| `source_url` | `https://www.aer.gov.au/industry/retail` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.aer.gov.au/industry/retail
  supplementary_urls:
    - https://www.aer.gov.au/consumers
    - https://www.aer.gov.au/industry/networks/network-performance
  content_type: auto
  javascript: enabled
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations from this framework that apply to AI systems used in
Australian energy sector operations (utilities, networks, O&G, renewables,
market operations).

Control ID pattern: AER.<AREA>  AREA ∈ {BEST_OFFER, HARDSHIP, LIFE_SUPPORT, MKT_REPRESENTATIONS, BILLING_ACCURACY, CONCESSIONS, DISPUTE_RESOLUTION, DER_CUSTOMER, RING_FENCING, CUSTOMER_DATA}

Obligation family mapping:
AER.BEST_OFFER        → transparency
AER.HARDSHIP          → redress
AER.LIFE_SUPPORT      → human_oversight (no disconnection)
AER.MKT_REPRESENTATIONS → transparency
AER.BILLING_ACCURACY  → testing_monitoring
AER.CONCESSIONS       → accountability
AER.DISPUTE_RESOLUTION→ redress (EWO referral)
AER.DER_CUSTOMER      → impact_assessment
AER.RING_FENCING      → accountability (DNSP obligation)
AER.CUSTOMER_DATA     → data_governance (CDR + Privacy)

Invariants:
- industry_scope = 'energy' on every row.
- jurisdiction_code = 'AU-ENERGY' on every row.
- Where the obligation cross-refs another regulator's control (e.g.
  AESCSF citing SOCI, IEC 62443, AU Privacy APPs), preserve the
  cross-reference in `notes`.
```

## 4. Edge cases

1. NECF vs VIC (own regime) — flag VIC-specific rows where applicable.
2. Life-support customer protection is absolute — disconnection prohibited.
3. Ring-fencing applies only to DNSPs — tag in notes.
4. CDR-energy overlay is under implementation — expect updates.
