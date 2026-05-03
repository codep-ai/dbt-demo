# APRA Prudential Standard CPS 230 — Operational Risk Management (incl. AI service providers)

**Framework code:** `APRA_CPS_230`
**Publisher:** Australian Prudential Regulation Authority (APRA)
**Jurisdiction:** AU-FIN · national · mandatory
**Industry scope:** finance
**Source URL:** https://www.apra.gov.au/operational-risk-management-0
**Authored:** 2026-05-03
**Rows seeded:** 12

## Why this framework

CPS 230 is APRA's operational risk standard for ADIs, insurers and RSE
licensees. It commenced **1 July 2025**, with the **service provider
arrangements (s44–s64) hard-deadline of 1 July 2026** for material
arrangements (including pre-existing contracts). For AFSL holders that are
also APRA-regulated (banks, life/general insurers, super funds), **CPS 230 is
the legal hook that pulls third-party AI/LLM providers — OpenAI, Anthropic,
Google, in-house model hosting — squarely inside operational-risk governance**.

`APRA_CPS_220` covers the older risk-management standard. `APRA_CPS_234`
covers information security. CPS 230 is the operational-resilience and
service-provider lens — the **single most important AU framework** for AI
vendor governance and the explicit Jul-2026 sales wedge.

## Coverage themes (12 rows)

| ID                          | Theme                                                                  |
|-----------------------------|------------------------------------------------------------------------|
| CPS230.OPERATIONAL-RISK     | Operational risk profile must include AI/ML risks                      |
| CPS230.CONTROLS-AI          | Controls assessment & effectiveness for AI-supported processes         |
| CPS230.INCIDENT-MGMT        | Incident management covering AI failures (outage, hallucination, drift)|
| CPS230.BCM-AI               | Business continuity for critical AI dependencies                       |
| CPS230.SERVICE-PROVIDER-REG | Register of material service providers (LLM, ML platforms, data brokers)|
| CPS230.SERVICE-PROVIDER-DD  | Due diligence on AI service providers before onboarding                |
| CPS230.CONTRACT-MIN-TERMS   | Minimum contract terms (audit, sub-contractors, data, exit)            |
| CPS230.CONCENTRATION-RISK   | Concentration risk on shared LLM providers (single-vendor dependency)  |
| CPS230.OFFSHORING-NOTIFY    | APRA notification of offshoring AI processing to overseas providers    |
| CPS230.BOARD-OVERSIGHT      | Board accountability for operational risk including AI                 |
| CPS230.TESTING              | Periodic testing of AI controls and BCP scenarios                      |
| CPS230.NOTIFY-INCIDENT      | APRA notification of material AI incidents within 72 hours             |

## Cross-references

- **APRA_CPS_220** (Risk Management) — broader risk framework; CPS 230 is the
  operational-resilience subset.
- **APRA_CPS_234** (Information Security) — overlaps on information assets and
  vendor security; CPS 230 covers business resilience and contracts.
- **APRA_CPG_235** (Managing Data Risk) — guidance companion.
- **ASIC_AFSL_2025 / ASIC_AI_2024** — for dual-regulated entities, ASIC and
  APRA obligations run in parallel.
- **AUSTRAC_AML_2025** — AML/CTF reporting entities have parallel duties.
- **AU_PRIVACY_APPS / PRIVACY_ADM_APP1_7** — privacy obligations on personal
  information used in AI processes.

## Refresh strategy

- **Primary source**: apra.gov.au — CPS 230 standard, CPG 230 guidance,
  speeches and FAQs.
- **Update cadence**: APRA publishes guidance updates ad-hoc; CPS 230 is new
  enough that interpretive guidance is still landing in 2026. Recommend
  **monthly** TinyFish scrape during 2026 ramp-up, then quarterly.
- **High-watch items**:
  - Critical operations definitions for AI-mediated services (advice, claims,
    credit decisioning, fraud).
  - APRA enforcement actions referencing AI vendor failures.
  - 1 July 2026 service-provider deadline interpretation guidance.
  - CPG 230 (companion guide) revisions.

## Notes

- Effective date set to 2025-07-01 (CPS 230 commencement). Service provider
  obligations bind on existing material arrangements from 1 July 2026.
- Material service provider definition explicitly contemplates technology and
  data providers — confirmed in APRA Q&A as covering LLM/AI vendors when
  they support critical operations.
- AI is not named in CPS 230 text but is fully captured by the standard's
  technology-neutral language ("services or technology") and APRA's 2025
  speeches make this scope explicit.
