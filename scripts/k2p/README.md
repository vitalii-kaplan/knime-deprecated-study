# k2p Evidence and Analysis Pipeline

This directory is the human-facing home for the planned privacy-preserving
knime2py/k2p evidence pipeline. This document is the authoritative data
contract, analysis boundary, and provenance specification for future scripts
placed here.

## Purpose

knime2py converts KNIME workflows into Python-oriented representations. Its
request stream can show whether deprecated KNIME nodes still occur in workflows
submitted for conversion and whether those nodes create translation or
migration work. This demand-side evidence complements the platform-side history
extracted from public KNIME repositories.

No knime2py dataset is currently included in this repository. The statements
below define the minimum evidence and privacy contract for adding it.

## Directory Status

No empirical export or analysis script is present yet. Future scripts should:

- validate an approved anonymized export;
- separate submissions, workflows, node occurrences, and node types;
- join complete KNIME factory classes to source-mined lifecycle evidence;
- retain unmatched and ambiguous identifiers;
- generate disclosure-reviewed aggregates; and
- record input, code, join, and output provenance.

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

Possible join states are:

```text
exact_factory_class | explicit_alias | ambiguous | not_found | identifier_missing
```

An `explicit_alias` requires independently recorded mapper or migration
evidence; it is not a fuzzy match.

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

Until these fields and an approved export exist, knime2py counts remain planned
evidence rather than empirical findings.
