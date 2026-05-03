# ASIC Australian Financial Services Licence (AFSL) — General Obligations and AI

**Framework code:** `ASIC_AFSL_2025`
**Publisher:** Australian Securities and Investments Commission (ASIC)
**Jurisdiction:** AU-FIN · national · mandatory
**Industry scope:** finance
**Source URL:** https://asic.gov.au/regulatory-resources/financial-services/financial-services-businesses/financial-services-licensing/
**Authored:** 2026-05-03
**Rows seeded:** 14

## Why this framework

AFSL is the licence required to provide financial services in Australia under the
Corporations Act 2001 s911A. Holders include banks, insurers, super funds,
brokers, asset managers, and personal financial advisers — collectively the
core AU FS market and the highest-WTP buyer pool for AI governance.

`ASIC_AI_2024` covers ASIC's general AI guidance. This framework covers the
specific AFSL **general obligations** under s912A and the relevant **ASIC
Regulatory Guides** (RG 78, RG 104, RG 105, RG 175, RG 255, RG 271, RG 274)
where AI is now embedded in licensed services.

## Coverage themes (14 rows)

| ID                       | Theme                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| AFSL.GENERAL-S912A       | Efficiently, honestly, fairly when using AI                           |
| AFSL.RESOURCES           | Adequate resources to deploy and oversee AI                           |
| AFSL.RISK-MGMT           | Risk management systems must cover AI risk (model, hallucination, etc.)|
| AFSL.TRAINING            | Representatives trained on AI tools and limitations                    |
| AFSL.BREACH-REPORT-S912D | s912D breach reporting for AI-caused incidents (RG 78, 30-day)        |
| AFSL.IDR-RG271           | IDR procedures must handle AI-decision complaints (RG 271)            |
| AFSL.DDO-RG274           | Design and Distribution Obligations — AI must respect TMD             |
| AFSL.DIGITAL-ADVICE-RG255| Digital/robo-advice — RG 255 conformance                              |
| AFSL.BID-AI              | Best Interests Duty applies when AI assists personal advice           |
| AFSL.MARKETING-S12DA     | AI-generated marketing must not be misleading or deceptive            |
| AFSL.CLAIMS-AI           | AI in claims handling — fairness and prompt resolution                |
| AFSL.SUITABILITY         | AI suitability/onboarding must reflect actual customer circumstances  |
| AFSL.ORG-COMPETENCE-RG105| Organisational competence covers AI capability (responsible manager)  |
| AFSL.CONFLICTS           | AI must not introduce undisclosed conflicts of interest               |

## Cross-references

- **ASIC_AI_2024**: covers ASIC's general AI principles. AFSL framework is the
  licensing-specific lens.
- **APRA_CPS_230 / 234**: APRA-regulated AFSL holders (banks, super, life/general
  insurers) have parallel APRA obligations.
- **AUSTRAC_AML_2025**: many AFSL holders are also AUSTRAC reporting entities;
  AML controls run in parallel.
- **AU_PRIVACY_APPS** (Privacy Act): AI-driven data handling is dual-regulated.

## Refresh strategy

- **Primary source**: asic.gov.au — INFO 225, RG 78, RG 105, RG 255, RG 271, RG 274
- **Update cadence**: ASIC publishes RG updates ~annually; speeches and INFO sheets
  ad-hoc — recommend monthly TinyFish scrape
- **High-watch items**:
  - RG 255 updates (digital advice expansion expected 2026-27)
  - RG 274 enforcement actions (DDO + AI personalisation)
  - DBFO Bill enactment (Delivering Better Financial Outcomes — affects advice obligations)
  - ASIC INFO 225 future revisions on technology and digital advice

## Notes

- Effective date set to 2002-03-11 (FSR Act commencement). AI-specific obligations
  are interpretation of these standing duties via the ASIC RGs (mostly 2016-2024).
- The 14 rows here are the AFSL+AI touchpoints. A complete AFSL catalogue covering
  all general obligations and RGs is ~50+ rows — out of scope for AI-governance
  framing.
- DBFO reforms (Delivering Better Financial Outcomes Bill 2025-26) may further
  reshape advice obligations — re-author these rows when DBFO Phase 2 lands.
