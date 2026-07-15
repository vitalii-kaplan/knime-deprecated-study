# Deprecated Nodes in KNIME Workflows

This repository contains the data, scripts, and manuscript for an empirical
study of deprecated KNIME nodes as a maintenance, translation, and long-term
reproducibility risk.

The study connects two evidence streams:

1. longitudinal mining of public `knime-oss` source metadata; and
2. an anonymized factory-occurrence export from deduplicated k2pweb workflows.

Deprecation is treated as a compatibility-risk signal. It does **not** mean that
a node is broken, that a workflow cannot execute, or that a translation failure
was caused by the node.

## Headline Results

| Measurement | Result |
|---|---:|
| Retained KNIME source snapshots | 13 |
| Snapshot period | 2018-04-03 to 2026-06-28 |
| Ordinary nodes in the 2026-06-28 snapshot | 1,506 |
| Deprecated ordinary-node registrations | 502 (33.33%) |
| Unique deprecated factory classes | 487 |
| Deduplicated k2pweb workflows | 62 |
| Observed node occurrences | 2,745 |
| Observed factory classes | 160 |
| Workflows containing a matched deprecated factory | 21 (33.87%) |
| Matched deprecated-node occurrences | 294 (10.71%) |
| Distinct matched deprecated factories used | 21 |

The exact join matched 146 of 160 observed factory classes and 2,549 of 2,745
occurrences to ordinary-node registrations in the 2026-06-28 source snapshot.
Fourteen factory classes remained unresolved by that join. “Unresolved” means
absent from the selected public ordinary-node registry, not invalid in KNIME.

## Research Questions

The current manuscript asks:

- How has declared KNIME node deprecation changed across public source
  snapshots?
- What additions, removals, and status transitions accompany that change?
- Which nodes classified as deprecated in the latest retained snapshot occur
  in the observed k2pweb workflows, and at what prevalence?

Replacement, migration, translation-support, and conversion-outcome analyses
remain follow-on work. Unsupported-by-knime2py and deprecated-in-KNIME are
separate states.

## Reproduce the Results

Requirements are Bash, Git, curl, jq, Python 3.11 or newer, and `latexmk` for
the manuscript. Run commands from the repository root.

```sh
make check
make article
```

`make check` validates the process description, runs the clone-script
integration test, and rebuilds the processed snapshot and k2pweb tables.

To reconstruct a source snapshot from a local clone:

```sh
make knime-snapshot \
  KNIME_OSS_ROOT=../2026-06-knime-oss \
  SNAPSHOT_DATE=2026-06-28
```

To discover, clone, update, and validate the public repository inventory
(network required):

```sh
make clone-knime-oss KNIME_OSS_ROOT=../2026-06-knime-oss
```

Useful individual targets are:

```sh
make knime-snapshot-summary
make deprecated-node-usage
make help
```

The canonical executable process description is
[`scripts/knime_source/knime_source_mining_chain.json`](scripts/knime_source/knime_source_mining_chain.json).

## Main Artifacts

| Path | Purpose |
|---|---|
| [`article/article.tex`](article/article.tex) | Active LNCS manuscript |
| [`ResearchPlan.md`](ResearchPlan.md) | Research framing and next work packages |
| [`Methods.md`](Methods.md) | Detailed collection and analysis method |
| [`data/original/knime_snapshots/`](data/original/knime_snapshots/) | Per-snapshot XML-derived records and checkout manifests |
| [`data/processed/knime_snapshots/knime_node_snapshot_summary.csv`](data/processed/knime_snapshots/knime_node_snapshot_summary.csv) | Longitudinal snapshot summary |
| [`data/original/k2pweb/factories.csv`](data/original/k2pweb/factories.csv) | Anonymized workflow index and factory occurrences |
| [`data/processed/k2pweb/deprecated_node_factory_registry.csv`](data/processed/k2pweb/deprecated_node_factory_registry.csv) | Unique deprecated factories in the classification snapshot |
| [`data/processed/k2pweb/k2pweb_factory_join_audit.csv`](data/processed/k2pweb/k2pweb_factory_join_audit.csv) | Exact join result for every observed factory |
| [`data/processed/k2pweb/k2pweb_deprecated_node_usage_summary.csv`](data/processed/k2pweb/k2pweb_deprecated_node_usage_summary.csv) | Aggregate join and prevalence measurements |
| [`scripts/knime_source/`](scripts/knime_source/) | KNIME repository checkout and metadata-mining tools |
| [`scripts/k2pweb/`](scripts/k2pweb/) | k2pweb registry/join analysis and privacy contract |

## Data and Privacy Boundaries

The k2pweb export covers 2026-03-25 through 2026-07-15. Each `index` uniquely
identifies one deduplicated workflow within the export, and each row represents
one node occurrence. The retained file contains factory classes only; it does
not contain workflow contents, node settings, credentials, IP addresses, or
stable user/session identifiers.

Raw service logs, uploaded workflows, user data, and identifying operational
metadata must not enter this repository. See
[`scripts/k2pweb/README.md`](scripts/k2pweb/README.md) for the complete data
contract and analysis rules.

## Interpretation and Coverage Limits

- Date-based source snapshots approximate repository states near selected
  dates; they are not reconstructed KNIME binary distributions.
- The public-source corpus does not include every separately distributed,
  proprietary, or unavailable KNIME extension.
- The current ordinary-node extractor reads registrations from `plugin.xml`.
  It does not yet collect extension contributions from `fragment.xml`.
- Dynamically produced node factories may not appear as ordinary `<node>`
  registrations. For example, `DynamicJSNodeFactory` is supplied through a
  node-set factory.
- Persisted workflows can retain factory identifiers after a registration has
  disappeared from later source snapshots.
- Hidden, removed, migrated, unmatched, and unsupported nodes must not be
  treated as synonyms for deprecated nodes.
- The 62 observed workflows are a self-selected k2pweb population and are not
  representative of all KNIME workflows.
- The current export contains no translation-support or conversion-outcome
  fields, so it cannot support causal claims about conversion failure.

## Manuscript

The active paper is [`article/article.tex`](article/article.tex). Build it with
`make article`; the generated PDF is intentionally ignored by Git.

## License

The repository is released under the [MIT License](LICENSE).
