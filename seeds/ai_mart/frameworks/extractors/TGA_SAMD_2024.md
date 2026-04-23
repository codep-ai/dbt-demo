# TinyFish Extraction Prompt — TGA_SAMD_2024

> **Framework:** Therapeutic Goods Administration — Software as a Medical Device (regulatory framework)
> **Publisher:** Therapeutic Goods Administration (TGA), Australia
> **Jurisdiction:** AU-HEALTH (Australian national — clinical/therapeutic AI)
> **Effective:** SaMD classification rules effective 2021, AI guidance ongoing (TGA AI guidance 2024)
> **Stage:** Stub to complete — supersedes the pre-2024 `TGA_AI_SAMD` stub rows

---

## 1. Framework metadata (constants — pre-populate on every extracted row)

| Column | Value |
|---|---|
| `framework_code` | `TGA_SAMD_2024` |
| `framework_name` | `TGA Software as a Medical Device (SaMD) regulatory framework + AI guidance` |
| `framework_publisher` | `Therapeutic Goods Administration (Australia)` |
| `jurisdiction_code` | `AU-HEALTH` |
| `country_code` | `AU` |
| `effective_from` | `2021-02-25` |
| `is_mandatory` | `true` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.tga.gov.au/resources/resource/guidance/regulatory-changes-software-based-medical-devices` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.tga.gov.au/resources/resource/guidance/regulatory-changes-software-based-medical-devices
  supplementary_urls:
    - https://www.tga.gov.au/resources/resource/guidance/software-based-medical-devices-what-sponsors-and-manufacturers-need-know
    - https://www.tga.gov.au/how-we-regulate/manufacturing/manufacture-medical-device/manufacturer-guidance-specific-types-medical-devices/artificial-intelligence-ai-enabled-medical-devices
    - https://www.tga.gov.au/consultation/consultation-artificial-intelligence-ai-medical-devices
  content_type: auto
  javascript: enabled
  timeout_seconds: 90
  retry_on_failure: 2
  capture:
    - full_page_text
    - content_sha256
    - retrieved_at_utc
```

## 3. Extraction prompt

```
You are extracting TGA SaMD + AI-enabled medical device regulatory controls.
Target ~15 top-level controls covering the obligations an Australian
medical-AI sponsor/manufacturer must meet.

=== CONTROL ID CONVENTION ===
Use dot-notation: TGA.SAMD.<AREA> where AREA is CLASS|PRE_MARKET|POST_MARKET|
CHANGE_MGMT|QMS|LABELLING|ADVERSE_EVENT|CYBERSECURITY|AI_LIFECYCLE|
DATA_QUALITY|HUMAN_OVERSIGHT|TRANSPARENCY|PERFORMANCE|PRIVACY|RECALL

=== OBLIGATION FAMILY MAPPING ===
TGA.SAMD.CLASS           → accountability          (device classification)
TGA.SAMD.PRE_MARKET      → impact_assessment       (conformity assessment pre-market)
TGA.SAMD.POST_MARKET     → testing_monitoring      (post-market surveillance)
TGA.SAMD.CHANGE_MGMT     → risk_management         (change / re-certification)
TGA.SAMD.QMS             → accountability          (quality mgmt system ISO 13485)
TGA.SAMD.LABELLING       → transparency            (labelling + IFU)
TGA.SAMD.ADVERSE_EVENT   → recordkeeping           (incident reporting to TGA)
TGA.SAMD.CYBERSECURITY   → risk_management
TGA.SAMD.AI_LIFECYCLE    → risk_management         (AI-specific lifecycle mgmt)
TGA.SAMD.DATA_QUALITY    → data_governance         (training data lineage)
TGA.SAMD.HUMAN_OVERSIGHT → human_oversight         (clinician-in-the-loop)
TGA.SAMD.TRANSPARENCY    → transparency            (explainability to clinicians)
TGA.SAMD.PERFORMANCE     → testing_monitoring      (clinical performance claims)
TGA.SAMD.PRIVACY         → data_governance         (health info handling)
TGA.SAMD.RECALL          → redress                 (recall + corrective action)

=== EXTRACTION RULES ===
1. control_description: one sentence obligation statement — source-cited.
2. mandatory_records: pipe-separated evidence artefacts the TGA expects
   (e.g. "Technical documentation | Clinical evaluation | PMS plan | IFU").
3. source_section: reference to the canonical TGA doc section.
4. For AI-specific guidance, cite the 2024 AI medical device consultation
   + any subsequent finalised AI guidance.
5. Flag in notes: SaMD class (I, IIa, IIb, III) that this control binds to.

=== INVARIANTS ===
- is_mandatory = true on EVERY row (TGA is a mandatory regulator for
  therapeutic goods entering the Australian market).
- industry_scope = 'healthcare' on every row.
- jurisdiction_code = 'AU-HEALTH'.
- Never fold in FDA / MHRA / EU MDR content here — those get their own
  framework_codes if we add them.
```

## 4. Diff output schema

Same as other frameworks — JSON with rows_extracted / rows_with_changes / structural_flags.

## 5. Known edge cases

1. TGA AI-enabled medical device guidance is evolving (2024 consultation → finalisation 2025-26). Refresh weekly until stable, then monthly.
2. SaMD classification (Class I-III) appears in multiple obligations — capture class-bindingness in `notes` rather than forking rows per class.
3. TGA's "Essential Principles" (Therapeutic Goods (Medical Devices) Regulations 2002 Schedule 1) map to many controls — preserve the EP reference in `source_section`.
4. The framework supersedes the old `TGA_AI_SAMD` stub — during cutover, both codes may coexist; prefer `TGA_SAMD_2024` for new citations.
