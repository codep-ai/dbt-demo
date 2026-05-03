# AUSTRAC AML/CTF Act and Industry Guidance — AI/ML in AML

**Framework code:** `AUSTRAC_AML_2025`
**Publisher:** Australian Transaction Reports and Analysis Centre (AUSTRAC)
**Jurisdiction:** AU-FIN · national · mandatory
**Industry scope:** finance
**Source URL:** https://www.austrac.gov.au/business/how-comply-and-report-guidance-and-resources
**Authored:** 2026-05-03
**Rows seeded:** 14

## Why this framework

AUSTRAC is the AU AML/CTF regulator. Reporting entities (banks, gambling, remittance,
crypto exchanges, financial-services providers) must run a risk-based AML/CTF Program
under the AML/CTF Act 2006. AI/ML is now embedded in:

- transaction monitoring (alert generation)
- customer risk scoring (CDD risk rating)
- sanctions, PEP, and adverse-media screening
- KYC document verification and biometric matching
- generative-AI assistance for SMR drafting and customer comms

AUSTRAC has issued AI-specific industry guidance (2024-2025) plus the
**AML/CTF Amendment (Making Australia More Secure) Act 2024** which from 2026 extends
the perimeter to lawyers, accountants, real-estate agents and high-value-goods dealers
("Tranche 2"). Many of these new reporting entities will deploy AI from day one and
need the controls scoped now.

## Coverage themes (14 rows)

| ID                       | Theme                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| AUSTRAC.PROGRAM-AI       | AI must sit inside the Part A AML/CTF Program                         |
| AUSTRAC.RECORD-7Y        | 7-year record-keeping for AI-driven AML decisions                     |
| AUSTRAC.SMR-EXPLAIN      | SMR explainability when AI is the trigger                             |
| AUSTRAC.TIPPING-OFF      | Generative-AI must respect s123 tipping-off offence                   |
| AUSTRAC.IND-REVIEW       | Independent review must scope AI                                      |
| AUSTRAC.MODEL-VAL        | Model validation cycle for AML AI                                     |
| AUSTRAC.ALERT-AUDIT      | Transaction-monitoring alert audit trail with AI provenance           |
| AUSTRAC.SANCT-AI         | Sanctions/PEP screening AI thresholds documented                      |
| AUSTRAC.KYC-AI           | AI-driven KYC quality controls and bias                               |
| AUSTRAC.RISK-SCORE       | Customer risk-score AI explainability + human override                |
| AUSTRAC.TTR-IFTI         | TTR/IFTI reporting accuracy with AI                                    |
| AUSTRAC.GENAI-DRAFT      | Generative AI in SMR drafting requires human-in-the-loop              |
| AUSTRAC.DATA-RESID       | Customer data sovereignty for AI processing (APP 8 link)              |
| AUSTRAC.TRANCHE2         | Tranche 2 expansion — AI uplift for new reporting entities            |

## Cross-references

- **APRA CPS 230 / 234**: operational + information-security overlap. Many APRA-regulated
  entities are also AUSTRAC reporting entities; AI controls must satisfy both.
- **ASIC AI 2024**: customer-fairness obligations (CDD outcomes affect customer treatment).
- **Privacy Act 2026 ADM disclosure (s13ZA)**: AI risk-scoring decisions affecting customer
  outcomes are likely captured by ADM disclosure obligations.

## Refresh strategy

- **Primary source**: austrac.gov.au — guidance and reports section
- **Update cadence**: AUSTRAC issues guidance ad-hoc; recommend monthly TinyFish scrape
- **Tranche 2 effective dates**: 2026 progressive commencement — track via legislation tracker
- **Industry guidance**: monitor AUSTRAC speeches, regtech alerts, court enforcement actions

## Notes

- Effective date set to 2006-12-12 (AML/CTF Act commencement). AI-specific obligations
  derive from Industry Guidance issued 2024-25 and operate as interpretation of the Act.
- The 14 rows here are the high-value AI-in-AML touchpoints. A complete AUSTRAC catalogue
  for non-AI obligations would be 60+ rows; out of scope for AI-governance framing.
- Tipping-off (`AUSTRAC.TIPPING-OFF`) is the highest-risk gap most banks have when
  deploying customer-facing generative AI. Cited refusals must be tested.
