# k2pweb Evidence and Analysis Pipeline

This directory documents the privacy-preserving knime2py/k2p evidence contract
and analysis boundary. The current factory-only k2pweb export is processed by
`scripts/k2pweb/build_deprecated_node_usage.py` because its exact join
depends directly on the source-mined KNIME factory registry.

## Purpose

knime2py converts KNIME workflows into Python-oriented representations. Its
request stream can show whether deprecated KNIME nodes still occur in workflows
submitted for conversion and whether those nodes create translation or
migration work. This demand-side evidence complements the platform-side history
extracted from public KNIME repositories.

The repository includes a factory-only k2pweb export covering 2026-03-25 through
2026-07-15. It contains a study-local deduplicated workflow index and one full
factory class per node occurrence. It does not contain conversion outcomes,
translation-support status, workflow contents, node settings, or user/session
identifiers. The statements below remain the minimum contract for richer future
exports.

## Directory Status

The current script validates and analyzes the limited factory-occurrence export.
Future extensions should:

- validate an approved anonymized export;
- separate submissions, workflows, node occurrences, and node types;
- join complete KNIME factory classes to source-mined lifecycle evidence;
- retain unmatched and ambiguous identifiers;
- generate disclosure-reviewed aggregates; and
- record input, code, join, and output provenance.

Run the current analysis from the repository root:

```sh
make deprecated-node-usage
```

The script writes:

```text
data/processed/k2pweb/deprecated_node_factory_registry.csv
data/processed/k2pweb/k2pweb_factory_join_audit.csv
data/processed/k2pweb/k2pweb_deprecated_node_usage_summary.csv
```

The current result contains 62 deduplicated workflows, 2745 node occurrences,
and 160 factory classes. Exact matching to the 2026-06-28 ordinary-node
registry resolves 146 factory classes and 2549 occurrences. Twenty-one
workflows contain a matched deprecated factory, accounting for 294 occurrences
and 21 distinct deprecated factory classes.

Fourteen factory classes remain `not_found`. This status means absent from the
selected public ordinary-node registry, not invalid in KNIME. It includes a
dynamically produced factory, a factory removed after the 2019 snapshot, and
factories potentially supplied by extensions outside the retained public-source
corpus.

## Unit of Analysis

Keep these units separate:

- **submission:** one conversion request; retries may duplicate a workflow;
- **workflow:** a deduplicated workflow represented by a random study-local ID;
- **node occurrence:** one node instance inside one workflow;
- **node type:** a normalized KNIME node identifier, preferably its full factory
  class;
- **conversion outcome:** the result for a submission or deduplicated workflow.

An approximate count of log records or node observations must not be described
as a count of workflows or users.

## Privacy-Preserving Export

Raw service data stays outside this repository. Export only fields required for
aggregate analysis, after removing workflow contents and operational metadata
that could identify a submitter.

Never export:

- names, email addresses, IP addresses, authentication data, or stable account
  and session identifiers;
- uploaded data files or complete workflow archives;
- node configuration values, paths, URLs, database details, credentials, free
  text, or workflow names;
- exact timestamps when a coarser observation period is sufficient.

Generate random study-local identifiers during export. If deduplication needs a
workflow fingerprint, compute it in the private environment and export only a
non-reversible study-specific token. Document retention and deletion rules for
the private intermediate.

## Proposed Normalized Tables

### Workflow table

```text
workflow_id
observation_period
node_count
distinct_node_type_count
submission_count
conversion_status
knime_version_if_structurally_available
export_version
```

### Node-occurrence table

```text
workflow_id
node_position_id
factory_class
node_name_if_non_identifying
extension_id_if_available
knime2py_support_status
translation_rule_id_if_available
conversion_impact
export_version
```

Use controlled values such as:

```text
knime2py_support_status = supported | partially_supported | unsupported | unknown
conversion_impact = none_observed | warning | manual_action | conversion_blocked | unknown
conversion_status = success | partial | failed | not_attempted | unknown
```

These are knime2py states, not KNIME lifecycle states. The analysis derives
`deprecated`, `hidden`, migration, and replacement attributes only after joining
the exported node identifier to the KNIME source-mining tables.

## Join Rules

1. Normalize a full factory-class identifier without changing its semantic
   identity.
2. Match exact full identifiers to the selected KNIME snapshot or lifecycle
   table.
3. Record the snapshot used for classification.
4. Retain unmatched and ambiguous node types with explicit reasons.
5. Never infer identity from a DOI-like suffix, class-name tail, path fragment,
   or other partial string.
6. Report join coverage before reporting deprecation prevalence.

The current join-audit states are:

```text
exact_deprecated | exact_not_deprecated | not_found
```

Future `explicit_alias` handling would require independently recorded mapper or
migration evidence; it must not be inferred through fuzzy matching.

## Core Metrics

After validation, report at least:

- number of submissions, deduplicated workflows, node occurrences, and node
  types;
- exact-join coverage and unmatched node types;
- workflows containing at least one deprecated node;
- deprecated node occurrences as a share of all node occurrences;
- distinct deprecated node types observed;
- concentration of deprecated occurrences by node type and extension;
- knime2py support status for deprecated and non-deprecated node occurrences;
- conversion outcomes for workflows with and without deprecated nodes;
- deprecated node types with mapper, migration-rule, or documented replacement
  evidence.

Descriptive comparisons do not establish that deprecation caused a conversion
failure. A causal claim requires error-level or controlled experimental
evidence that isolates the affected node.

## Deduplication and Bias

Document how retries, resubmissions, templates, and automated traffic are
handled. Report both submission-level and deduplicated-workflow results when
repeated requests are analytically relevant. State the observation window and
recognize that knime2py users are a self-selected population; their workflows
do not represent all KNIME workflows.

Before publishing rare-node tables, apply a disclosure review and suppress or
group cells below an agreed minimum count. Report the threshold with the
results.

## Required Provenance

Every processed knime2py result must record:

- observation window;
- export date;
- exporter version or commit;
- input scope and filters;
- definitions of submission, workflow, and occurrence;
- deduplication method;
- KNIME snapshot or lifecycle-table version used for joins;
- join coverage and unresolved identifiers;
- suppression or disclosure-control rule; and
- script and output paths.

For the current export, the observation window, export date, counting units,
classification snapshot, join coverage, script, and output paths are recorded.
The exporter version and the implementation details of the upstream
deduplication procedure were not supplied; this is a provenance limitation even
though each exported `index` is confirmed to identify one deduplicated
workflow.

Counts outside the current factory-occurrence scope remain planned evidence
until the required fields and an approved export exist.
