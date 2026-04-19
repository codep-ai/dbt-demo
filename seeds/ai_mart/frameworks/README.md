# AI Governance Framework Seeds

One flat seed — `ai_controls_seed.csv` — containing all compliance-framework control data. Discriminator columns (`framework_code`, `jurisdiction_code`, `effective_from`) replace what would otherwise be separate dim tables.

**Status:** v0.2 draft, 2026-04-19 — Phase 2.1 Week 1 Day 1 deliverable. No dbt integration yet.

## Why one table, not nine

Total content is only ~55 rows across 7 frameworks. Fragmenting into `dim_framework`, `dim_jurisdiction`, and one CSV per framework (the v0.1 approach) was over-engineered — more files to keep in sync, more cross-file drift risk, harder to review. One flat seed with discriminator columns is simpler at this scale. dbt models can derive normalised `dim_framework` / `dim_jurisdiction` views later via `SELECT DISTINCT` if joins benefit from it.

## Fallback: `sys_common_config` key-value for non-standardisable content

If a future framework has per-control attributes that don't fit the flat-table columns (e.g. EU AI Act Annex III article-specific risk categorisations, or jurisdictional variations that only apply to one control), use `sys_common_config` as a key-value extension rather than adding columns that are null for 95% of rows. Key pattern: `ai_governance.framework.<framework_code>.<control_id>.<attribute>` → value.

Do not add a generic `extras_json` column to the seed yet — wait until actual need. YAGNI.

## File

- **`ai_controls_seed.csv`** — 55 rows across 7 frameworks

## Schema

| Column | Type | Notes |
|---|---|---|
| `framework_code` | string | Discriminator. Values: `AU_6_2025`, `NIST_AI_RMF_10`, `UK_5_PRINCIPLES`, `ISO_42001_2023`, `CO_AI_ACT_2024`, `FINRA_24_09`, `FCA_AI_DP5_22` |
| `framework_name` | string | Human-readable framework name (redundant with `framework_code`, kept for readability in raw-seed lookups) |
| `framework_publisher` | string | Issuing body |
| `jurisdiction_code` | string | Full jurisdiction incl. sub-national scope: `AU`, `US`, `US-CO`, `US-FIN`, `UK`, `UK-FIN`, `INT` |
| `country_code` | string | Country-level only: `AU`, `US`, `UK`, `INT`. Denormalised from `jurisdiction_code` for simpler country-scoped queries ("what frameworks apply in the US?") |
| `effective_from` | date | Framework version effective date (ISO 8601) |
| `is_mandatory` | bool | `true` for enacted law / regulator mandate; `false` for voluntary guidance |
| `source_url` | string | Canonical source URL for citation |
| `control_id` | string | Framework-native control ID (e.g. `P1`, `GOVERN-3`, `A.3`, `CO.6-1-1702`). Unique within `framework_code`. |
| `control_name` | string | Short human name |
| `control_description` | string | One-sentence description, source-cited |
| `control_category` | string | Framework-native grouping (verbatim from source) |
| `obligation_family` | string | Normalised cross-framework obligation. Values: `accountability`, `impact_assessment`, `risk_management`, `transparency`, `testing_monitoring`, `human_oversight`, `redress`, `third_party_supply_chain`, `data_governance`, `recordkeeping`. Enables "one AI system, N frameworks covered" via `WHERE obligation_family = 'accountability'` — no bridge table needed. |
| `mandatory_records` | string | Pipe-separated list of artefacts the framework expects |
| `source_section` | string | Pointer into the source document |
| `retrieved_date` | date | When this row was last verified against source |
| `status` | string | `complete` / `top_level_only` / `stub` — drives downstream filtering |
| `notes` | string | Authoring notes, ambiguity flags, rework TODOs |

## Obligation family distribution

| Family | Rows | Frameworks hit |
|---|---|---|
| `accountability` | 11 | AU, NIST, UK, ISO, CO, FCA |
| `impact_assessment` | 9 | AU, NIST, UK, ISO, CO, FCA |
| `risk_management` | 9 | AU, NIST, UK, CO, FCA |
| `testing_monitoring` | 7 | AU, NIST, ISO, FINRA |
| `third_party_supply_chain` | 6 | NIST, ISO, FINRA, FCA |
| `transparency` | 5 | AU, UK, ISO, CO, FINRA |
| `human_oversight` | 3 | AU, ISO, FINRA |
| `redress` | 2 | UK, CO |
| `recordkeeping` | 2 | CO, FINRA |
| `data_governance` | 1 | ISO |

Observation: `accountability`, `impact_assessment`, and `risk_management` are covered by 5+ frameworks → highest multi-jurisdiction leverage per control built. `data_governance` is only hit by ISO right now; if it becomes important, bridge it in from FINRA recordkeeping + CO Section 1706 data correction rights.

## Row count by framework

| framework_code | Rows | Status |
|---|---|---|
| `AU_6_2025` | 6 | ✅ complete from Oct 2025 guidance |
| `UK_5_PRINCIPLES` | 5 | ✅ complete from White Paper + 2024 response |
| `NIST_AI_RMF_10` | 19 | 🟡 top-level (4 functions × ~5 categories); ~72 subcategories deferred |
| `ISO_42001_2023` | 9 | 🟥 stub (paywalled source); category placeholders only |
| `CO_AI_ACT_2024` | 6 | 🟥 stub; needs verification against enacted SB24-205 text |
| `FINRA_24_09` | 5 | 🟥 stub; needs verification against Notice 24-09 text |
| `FCA_AI_DP5_22` | 5 | 🟥 stub; needs verification against DP5/22 + 2024 AI Update |
| **Total** | **55** | |

## Citation manifest

| framework_code | Publisher | Version | Effective | Source |
|---|---|---|---|---|
| `AU_6_2025` | Australian Government DISR | 1.0 (Oct 2025) | 2025-10-08 | https://www.industry.gov.au/publications/guidance-for-ai-adoption/guidance-ai-adoption-implementation-practices |
| `NIST_AI_RMF_10` | NIST (US Dept of Commerce) | 1.0 | 2023-01-26 | https://www.nist.gov/itl/ai-risk-management-framework |
| `ISO_42001_2023` | ISO/IEC | 2023 | 2023-12-18 | https://www.iso.org/standard/81230.html (paywalled) |
| `UK_5_PRINCIPLES` | UK Government (DSIT) | White Paper + 2024 response | 2024-02-06 | https://www.gov.uk/government/consultations/ai-regulation-a-pro-innovation-approach-policy-proposals |
| `CO_AI_ACT_2024` | Colorado State Legislature | SB24-205 as enacted | 2026-02-01 | https://leg.colorado.gov/bills/sb24-205 |
| `FINRA_24_09` | FINRA | Notice 24-09 | 2024-06-27 | https://www.finra.org/rules-guidance/notices/24-09 |
| `FCA_AI_DP5_22` | FCA | DP5/22 + 2024 AI Update | 2024-01-01 | https://www.fca.org.uk/publications/discussion-papers/dp5-22-artificial-intelligence-machine-learning |
| `APRA_AI_2025` | Australian Prudential Regulation Authority | CPS 230 effective 1 July 2025 + supervisory engagements 2025-26 | 2025-07-01 | https://www.apra.gov.au/operational-risk-management |
| `ASIC_AI_2024` | Australian Securities and Investments Commission | REP 775 (Oct 2024) + Corporations Act s912A + 2026 enforcement priorities | 2024-10-29 | https://asic.gov.au/regulatory-resources/find-a-document/reports/rep-775-beware-the-gap-governance-arrangements-in-the-face-of-ai-innovation/ |

## Rules

1. **Never mutate a published row.** When a framework publishes a new version, add a new `framework_code` (e.g. `AU_6_2025` + `AU_6_2027` coexist) and new rows with the new `effective_from`. Do not overwrite existing rows.
2. **One row per (framework_code, control_id).** Enforce via dbt test `unique` on the compound key.
3. **Flag ambiguity in `notes`.** `STUB`, `TODO — verify against enacted text`, `paywalled — placeholder only` are expected while in draft.
4. **Cross-framework mapping** (e.g. AU P1 ≈ NIST GOVERN-2 ≈ ISO A.3 ≈ UK P4 ≈ FINRA.SUP ≈ FCA.SMCR) does NOT live in this file. It goes in a separate `bridge_control_framework_seed.csv` to be authored when the `ai_mart` dbt extension lands.

## Next steps (not yet done)

- [ ] `bridge_control_framework_seed.csv` — the N:N map between controls expressing the same real-world obligation across frameworks. This is what makes the multi-jurisdiction story actually useful (one AI system, one click, six frameworks covered).
- [ ] Integrate into `ai_mart` dbt models: surface `ai_controls_seed` as the `dim_ai_control` source. No bridge needed for control↔framework since `framework_code` is a column on each control row; use `obligation_family` for cross-framework coverage queries. `bridge_ai_system_control` (N:N between AI systems and controls they satisfy) is a future model once `dim_ai_system` exists.
- [ ] Expand NIST subcategories (~72 rows) once top-level validated.
- [ ] Acquire ISO/IEC 42001:2023 to replace 9 stub rows with real ~38 Annex A controls.
- [ ] Verify Colorado / FINRA / FCA stubs against authoritative texts.
