# Deprecated KNIME Nodes and knime2py

This repository supports an empirical study of deprecated components in KNIME
workflows. The study combines two complementary evidence sources:

1. longitudinal mining of public `knime-oss` source metadata; and
2. privacy-preserving aggregate observations from knime2py conversion requests.

This is a focused copy of an earlier project. Material unrelated to deprecated
nodes or knime2py is intentionally not part of this repository.

## Research Focus

The study asks:

- How has declared KNIME node deprecation changed across source snapshots?
- Which deprecated node types still occur in workflows processed by knime2py?
- Do deprecated nodes have identifiable replacement or migration metadata?
- How does deprecation affect KNIME-to-Python translation support?

Deprecated, hidden, removed, migrated, and unsupported nodes are different
states and must be reported separately. In particular,
unsupported-by-knime2py does not imply deprecated-in-KNIME.

## Current Evidence

The retained repository-mining dataset covers 13 source-date snapshots from
2018-04-03 through 2026-06-28. The 2026-06-28 snapshot contains 1,506
registered ordinary nodes, of which 502 (33.33%) are marked deprecated in
KNIME extension metadata. This is a repository-level compatibility-risk signal;
it is not evidence that every affected workflow fails.

The knime2py evidence stream is planned but is not yet included in this
repository. Any future dataset must contain only anonymized structural records
or aggregates. Approximate log volume must not be reported as a count of
distinct workflows until the unit and deduplication method have been verified.

## Repository Map

```text
ResearchPlan.md            Research framing, status, and next work packages
Methods.md                 Reproducible KNIME source-mining method
article/                   Focused LNCS manuscript and bibliography
data/original/             Per-snapshot KNIME metadata and checkout manifests
data/processed/            Cross-snapshot derived tables
scripts/knime_source/      KNIME source-mining tools and their README
scripts/k2p/               Future privacy-preserving knime2py analysis tools
notes/                     Source-snapshot provenance
```

The canonical KNIME source-mining process is
`scripts/knime_source/knime_source_mining_chain.json`. The `Makefile` provides its common
commands.

## Rebuilding the KNIME Evidence

```sh
make help
make article
make knime-snapshot \
  KNIME_OSS_ROOT=../2026-06-knime-oss \
  SNAPSHOT_DATE=2026-06-28
make knime-snapshot-summary
make check
```

Cloning the public KNIME repositories requires network access:

```sh
make clone-knime-oss KNIME_OSS_ROOT=../2026-06-knime-oss
```

This target clones missing repositories, fetches existing ones, validates the
complete discovered inventory, and writes
`data/original/knime_source/logs/knime_oss_clone_manifest.csv`. It fails instead
of handing an incomplete or inconsistent clone to the snapshot checkout step.

## Data and Privacy Boundaries

- Public KNIME source metadata and its derived tables may be committed with
  provenance.
- Do not commit raw k2pweb or knime2py logs, uploaded workflows, user data,
  credentials, node settings, IP addresses, or stable user/session identifiers.
- Commit only an approved anonymized export or aggregate tables that cannot be
  traced to a person or submitted workflow.
- Record the export window, counting unit, deduplication rule, filter rules, and
  source version alongside every knime2py-derived result.

See `scripts/k2p/README.md` for the proposed data contract and analysis rules.

## Article

The active manuscript is `article/article.tex`. It retains the main article
sections but contains only the deprecated-node study; the earlier bibliometric
and publication-audit sections are not part of this manuscript. Build it with
`make article` or run `latexmk -pdf -interaction=nonstopmode article.tex` from
the `article/` directory.

## Scope Limits

The source snapshots represent public repository metadata near selected dates,
not exact KNIME binary releases. A deprecated marker means that KNIME treats a
node as legacy or discouraged; it does not by itself establish removal,
execution failure, or semantic incompatibility.
