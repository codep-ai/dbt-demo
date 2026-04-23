# TinyFish Extraction Prompt — IEA_AI_ENERGY_2024

> **Framework:** IEA AI for Energy — policy + governance guidance
> **Publisher:** International Energy Agency
> **Jurisdiction:** INT-ENERGY
> **Effective:** 2024-04-01
> **Stage:** Guidance — refresh quarterly

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `IEA_AI_ENERGY_2024` |
| `framework_publisher` | `International Energy Agency` |
| `jurisdiction_code` | `INT-ENERGY` |
| `country_code` | `INT` |
| `is_mandatory` | `false` |
| `industry_scope` | `energy` |
| `source_url` | `https://www.iea.org/reports/why-ai-and-energy-are-the-new-power-couple` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.iea.org/reports/why-ai-and-energy-are-the-new-power-couple
  supplementary_urls:
    - https://www.iea.org/topics/digitalisation
    - https://www.iea.org/reports
  content_type: auto
  javascript: enabled
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations from this framework that apply to AI systems used in
Australian energy sector operations (utilities, networks, O&G, renewables,
market operations).

Control ID pattern: IEA.<AREA>  AREA ∈ {TRANSPARENCY, ENERGY_USE, GRID_INTEGRATION, WORKFORCE_TRANSITION, CONSUMER_EMPOWER, DATA_SHARING, INTL_COOPERATION, RELIABILITY, EMISSIONS_BENEFIT, RESEARCH_DEV}

Obligation family mapping:
IEA.TRANSPARENCY        → transparency
IEA.ENERGY_USE          → recordkeeping (AI workload energy)
IEA.GRID_INTEGRATION    → third_party_supply_chain
IEA.WORKFORCE_TRANSITION → impact_assessment
IEA.CONSUMER_EMPOWER    → transparency
IEA.DATA_SHARING        → data_governance
IEA.INTL_COOPERATION    → third_party_supply_chain
IEA.RELIABILITY         → risk_management
IEA.EMISSIONS_BENEFIT   → impact_assessment (net-emissions)
IEA.RESEARCH_DEV        → accountability

Invariants:
- industry_scope = 'energy' on every row.
- jurisdiction_code = 'INT-ENERGY' on every row.
- Where the obligation cross-refs another regulator's control (e.g.
  AESCSF citing SOCI, IEC 62443, AU Privacy APPs), preserve the
  cross-reference in `notes`.
```

## 4. Edge cases

1. IEA publishes periodic AI/energy reports; scrape quarterly.
2. Non-binding guidance, but widely cited in government AI policies.
3. AI-data-centre grid impact is fast-moving topic — refresh frequently.
