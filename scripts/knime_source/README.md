# KNIME Source-Mining Scripts

This directory contains the reproducible pipeline for mining deprecated-node
and compatibility metadata from the public `knime-oss` repositories.

The canonical machine-readable process description is
`knime_source_mining_chain.json`. This README is the human-facing command and
file guide. Keep both synchronized when scripts, parameters, or outputs change.

Script files intentionally do not contain absolute interpreter shebangs. Run
them through the Makefile or invoke `bash`/`python3` explicitly from the
repository root.

Filesystem arguments must also be relative to the repository root. The scripts
reject absolute input and output paths rather than embedding host-specific
locations in commands or evidence.

## Requirements

- Bash
- Git
- curl
- jq
- Python 3.11 or newer
- Network access for repository discovery, cloning, and fetching

The checkout, XML extraction, summary generation, and local tests do not require
network access after the repositories are available.

## Scripts

### `clone_knime_oss_repos.sh`

Discovers the current public repositories in the GitHub `knime-oss`
organization, clones missing repositories, fetches existing repositories, and
validates the complete local inventory.

For every discovered repository, it verifies:

- a local Git worktree exists;
- the `origin` remote identifies the expected `knime-oss` repository; and
- `HEAD` resolves to a commit.

It also rejects unexpected local Git repositories because the later checkout
step would otherwise include them in the mining corpus. The script writes a CSV
manifest and exits nonzero if any validation fails.

### `checkout_knime_oss_by_date.sh`

Checks out each non-hidden immediate Git repository to the latest commit at or
before the requested date. It writes a checkout manifest containing repository
status, selected commit and date, and the previous HEAD.

The hidden `.github` repository is excluded by the checkout glob and does not
enter node-metadata extraction.

### `collect_knime_node_snapshot.py`

Parses structured KNIME XML metadata from one checked-out source state. It
extracts:

- ordinary node and dynamic node-set registrations;
- deprecated and hidden markers;
- node-description metadata;
- `NodeFactoryClassMapper` contributions; and
- `NodeMigrationRule` contributions.

The parser excludes repository-control and generated directories such as
`.git`, `target`, `bin`, and `.metadata`.

### `build_knime_node_snapshot_summary.py`

Combines the per-snapshot CSV files into the chronological cross-snapshot
summary. It calculates aggregate counts and adjacent-snapshot transition
approximations.

### `test_clone_knime_oss_repos.sh`

Runs a network-free integration test with simulated GitHub and Git commands. It
checks initial cloning, repeated updating, manifest output, and rejection of an
unexpected local repository.

## Normal Workflow

Run commands from the repository root.

Clone or update and validate the public source repositories:

```sh
make clone-knime-oss \
  KNIME_OSS_ROOT=../2026-06-knime-oss
```

The default validation manifest is:

```text
data/original/knime_source/logs/knime_oss_clone_manifest.csv
```

Checkout and extract one source-date snapshot:

```sh
make knime-snapshot \
  KNIME_OSS_ROOT=../2026-06-knime-oss \
  SNAPSHOT_DATE=2026-06-28
```

Rebuild the cross-snapshot summary:

```sh
make knime-snapshot-summary
```

Run local validation and rebuild the derived summary:

```sh
make check
```

Use `make help` for the complete target and parameter list.

## Inputs and Outputs

The local `knime-oss` clone is normally stored outside this repository and is
not committed.

Per-snapshot evidence is stored under:

```text
data/original/knime_snapshots/<snapshot-date>/
```

Each snapshot contains:

```text
logs/checkout_<snapshot-date>.csv
plugin_nodes.csv
node_descriptions.csv
factory_class_mappers.csv
migration_rules.csv
summary.csv
```

The processed longitudinal summary is:

```text
data/processed/knime_snapshots/knime_node_snapshot_summary.csv
```

## Interpretation Limits

- Deprecated, hidden, removed, migrated, and replaced nodes are different
  states and must remain separate.
- Only a case-insensitive `deprecated="true"` value in the relevant KNIME
  metadata is counted as a deprecation marker.
- Mapper and migration-rule contributions are compatibility evidence, not
  deprecation markers.
- Date-based source states are not exact binary KNIME releases.
- Repository metadata does not establish that a workflow imports, executes, or
  fails at runtime.
- Unsupported-by-knime2py is separate from deprecated-in-KNIME.
