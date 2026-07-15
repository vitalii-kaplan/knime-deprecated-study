# AGENTS.md

## Project

This repository is for a new paper about deprecated KNIME nodes as a
maintenance, translation, and reproducibility risk. Its research framing and
work plan are in `ResearchPlan.md`.

The project combines:

1. longitudinal mining of public KNIME source metadata; and
2. anonymized structural or aggregate evidence from knime2py/k2pweb requests.

This is a scoped copy of an earlier repository. The active manuscript is
`article/article.tex`; it preserves the earlier article's main section titles
but now contains only deprecated-node material. Do not restore removed research
streams, corpora, pipelines, or manuscript sections unless the user explicitly
changes the project scope.

## Research Thesis

Visual workflows depend on platform components whose lifecycle changes over
time. KNIME deprecation metadata provides platform-side evidence of this
evolution. knime2py request data can provide demand-side evidence of which
deprecated nodes still occur in practice and how they interact with translation
support. Deprecation is a compatibility-risk signal, not proof that a workflow
is broken or scientifically irreproducible.

## Research Questions

1. How has declared KNIME node deprecation evolved across source snapshots?
2. Which deprecated node types occur in workflows observed by knime2py?
3. Which deprecated nodes have identifiable replacement or migration evidence?
4. How does deprecated-node use relate to knime2py translation support and
   conversion outcomes?
5. Can the evidence support actionable warnings or migration advice?

## Evidence Sources

### KNIME source metadata

- Public repositories cloned from the `knime-oss` GitHub organization.
- Per-date checkout manifests and structured XML extraction under
  `data/original/knime_snapshots/<date>/`.
- Derived longitudinal summaries under `data/processed/knime_snapshots/`.
- KNIME node, node-set, node-description, factory-class mapper, and migration
  rule metadata.

### knime2py evidence

- Only an approved anonymized export or aggregate result may enter this
  repository.
- The data contract and metric definitions are in `scripts/k2p/README.md`.
- Until an export is present and validated, describe this evidence stream as
  planned; do not report provisional volume as a verified number of workflows.

## Working Rules

- Never hard-code absolute filesystem paths in scripts, configuration, the
  manuscript, or documentation. Resolve project files relative to the
  repository root and refer to the external KNIME clone as
  `../2026-06-knime-oss` by default.
- Invoke interpreters through commands resolved from `PATH`, for example
  `bash scripts/...` and `python3 scripts/...`; do not add absolute shebang or
  Makefile interpreter paths.
- Web URLs and DOI URLs are not filesystem paths and are unaffected by this
  rule.
- If an absolute filesystem path is genuinely unavoidable, stop and ask the
  user explicitly before adding it. After approval, document the exact path,
  location, and technical reason as an exception in this file.
- Use `ResearchPlan.md` as the research-framing and scope authority.
- Treat `scripts/knime_source/knime_source_mining_chain.json` as the canonical executable
  description of KNIME source mining. Keep the `Makefile` synchronized with it.
- Treat a successful clone step as automatic only when
  `data/original/knime_source/logs/knime_oss_clone_manifest.csv` records every
  discovered repository as verified and the script exits with status zero.
- Prefer structured XML parsing over text grep for deprecation evidence.
- A deprecation marker is only case-insensitive `deprecated="true"` in the
  relevant KNIME metadata. Keep `hidden="true"` separate.
- Keep deprecated, hidden, removed, migrated, replaced, missing, and
  unsupported states distinct.
- Unsupported-by-knime2py does not mean deprecated-in-KNIME, and the reverse is
  also not guaranteed.
- Do not invent counts, node identities, replacement mappings, conversion
  outcomes, or dataset units.
- Mark preliminary figures as provisional until their input, counting unit,
  and deduplication method are recorded.
- Preserve raw KNIME snapshot records separately from processed summaries.
- Keep claims traceable to a source file, snapshot, script, or documented
  knime2py aggregate.
- Keep `article/article.tex` focused on deprecated nodes and the planned
  knime2py evidence stream. Do not reintroduce unrelated earlier sections.
- Do not invent an affiliation. The current `\institute{...}` block contains
  only the supplied email address.

## KNIME Source-Mining Method

The canonical extractor is `scripts/knime_source/collect_knime_node_snapshot.py`. It excludes
repository-control and generated directories such as `.git`, `target`, `bin`,
and `.metadata`, and writes per-record CSVs for:

- ordinary nodes and dynamic node sets;
- node-description XML;
- `NodeFactoryClassMapper` entries; and
- `NodeMigrationRule` entries.

Date-based source snapshots currently cover:

```text
2018-04-03, 2019-01-01, 2019-12-05, 2020-01-01, 2021-01-01,
2022-01-01, 2023-01-01, 2023-02-22, 2024-01-01, 2025-01-01,
2026-01-01, 2026-03-03, 2026-06-28
```

The node identity key is `factory_class` when present; otherwise it falls back
to `plugin_xml:element:category_path`. Adjacent-snapshot transitions are
metadata-level approximations, especially when factory classes are renamed.

Current repository-level result: the 2026-06-28 snapshot has 1,506 registered
ordinary nodes and 502 deprecated ordinary nodes (33.33%). Do not infer runtime
failure from this result.

The local `knime-product` history has product tags beginning with KNIME
Analytics Platform 3.5.3 (`analytics-platform/3.5.3`, dated 2018-04-03). Do not
claim source-code results for earlier versions without adding and documenting a
separate source.

## knime2py Data Rules

- Never commit raw service logs, uploaded workflows, user data, credentials,
  node settings, IP addresses, or stable user/session identifiers.
- Prefer an offline export that assigns random study-local workflow IDs before
  it reaches this repository.
- Record the observation window, exporter version or commit, selection rules,
  deduplication method, and counting unit.
- Distinguish submissions, deduplicated workflows, node occurrences, and
  distinct node types.
- Join knime2py node identifiers to KNIME metadata by an explicit normalized
  factory class or another documented full identifier. Do not use suffix or
  partial-string matching as evidence.
- Preserve unmatched identifiers and join reasons instead of silently dropping
  them.
- Report deprecated-node prevalence at both workflow and occurrence levels.
- Separate translation support from deprecation and record conversion outcomes
  using controlled labels.
- Apply a minimum group-size or equivalent disclosure review before publishing
  rare-node breakdowns.

## Next Analysis Priorities

1. Build a node-level lifecycle table across the retained snapshots.
2. Link deprecated nodes to mapper and migration-rule evidence.
3. Manually validate representative deprecated, hidden, removed, migrated, and
   inconsistent records.
4. Define and validate the knime2py anonymized export.
5. Join observed knime2py node types to the KNIME lifecycle table.
6. Produce aggregate prevalence, translation-impact, and migration-advice
   tables only after the units and join quality are verified.

## Verification

Use:

```sh
make check
```

Before publishing results, rerun source extraction from a documented local
clone where practical. Record any private, manual, or non-reproducible boundary
in the derived-output metadata.

## Repository Layout

```text
.
|-- README.md
|-- AGENTS.md
|-- ResearchPlan.md
|-- Methods.md
|-- article/
|   |-- article.tex
|   `-- references.bib
|-- data/
|   |-- original/knime_snapshots/
|   `-- processed/knime_snapshots/
|-- scripts/
|   |-- knime_source/
|   `-- k2p/
`-- notes/
```
