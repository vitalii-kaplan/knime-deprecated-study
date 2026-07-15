# Methods

This file records how we collect the longitudinal KNIME snapshot data and join
the resulting deprecated-factory registry to the anonymized k2pweb
factory-occurrence export. The primary processed outputs are under
`data/processed/knime_snapshots/` and `data/processed/k2pweb/`.

## Source Code

The KNIME source repositories were cloned from the public `knime-oss`
GitHub organization into:

```text
../2026-06-knime-oss
```

The clone process is recorded in:

- `notes/knime-oss-source-snapshot.md`

The cloning script is:

- `scripts/knime_source/clone_knime_oss_repos.sh`

It discovers the current public organization inventory, clones missing
repositories, fetches existing repositories, and validates every expected
worktree, origin remote, and HEAD commit. It fails on missing, invalid, or
unexpected local repositories and writes the retained manifest:

- `data/original/knime_source/logs/knime_oss_clone_manifest.csv`

The project `Makefile` is the current command index for rerunning these steps.
Use `make help` to see the wrapped targets and parameters. In particular,
`make knime-snapshot` wraps checkout plus extraction for one date, and
`make knime-snapshot-summary` rebuilds the processed cross-snapshot table.

The repositories are treated as source snapshots. A row in the results table is
computed by putting the cloned repositories into a defined state, then running
the same mining script over the whole source tree.

The exact top-level repository list used by the current local clone is recorded
in:

- `data/processed/knime_snapshots/knime_oss_repositories.csv`

The local clone directory timestamp is `2026-06-27 01:16:28` on the host
filesystem. Future reruns record the discovery/fetch time in the clone manifest
because the set of public repositories in the organization may change.

The clone currently contains 91 immediate Git repositories. The date-checkout
script processes 90 non-hidden immediate repositories because its shell glob
matches:

```text
<source-root>/*/.git
```

The hidden top-level repository `.github` is therefore excluded from the
date-based mining snapshots. This is acceptable for the current deprecated-node
analysis because `.github` is organization metadata rather than a KNIME node
implementation repository, but the exclusion is recorded here for
reproducibility.

The current local environment used for this run was:

| Item | Value |
|---|---|
| Operating system | macOS Darwin 25.5.0, arm64 |
| Git | 2.54.0 |
| Git LFS | 3.7.1 |
| Python | 3.14.5 |

Network access is needed for the initial GitHub clone or future fetches. The
date checkout, metadata extraction, and summary build operate on the local
clone.

## Deprecated-Node Markers

KNIME node deprecation is represented primarily through Eclipse extension
metadata rather than Java `@Deprecated` annotations. The primary marker for an
ordinary node is in `plugin.xml`:

```xml
<extension point="org.knime.workbench.repository.nodes">
  <node
      category-path="/..."
      deprecated="true"
      factory-class="...SomeNodeFactory">
  </node>
</extension>
```

The defining schema is:

- `../2026-06-knime-oss/knime-workbench/org.knime.workbench.repository/schema/Node.exsd`

It specifies that deprecated nodes are not shown in the node repository but are
still loaded in existing workflows. When the extension registration contains
the marker, the node-description XML does not also need to declare it.

Dynamic node sets use a separate extension point and are counted separately
from ordinary nodes:

```xml
<extension point="org.knime.workbench.repository.nodesets">
  <nodeset
      deprecated="true"
      factory-class="...SomeNodeSetFactory">
  </nodeset>
</extension>
```

The corresponding schema is:

- `../2026-06-knime-oss/knime-workbench/org.knime.workbench.repository/schema/nodesets.exsd`

A secondary marker exists in node-description XML:

```xml
<knimeNode icon="./dectree.png" type="Learner" deprecated="true">
```

Files ending in `NodeFactory.xml` and rooted at `knimeNode` are parsed as this
secondary source. Extension-point deprecation remains authoritative for
ordinary registered nodes.

At runtime, KNIME exposes status through `NodeFactory.isDeprecated()`. Ordinary
nodes normally receive their status from extension registration. Dynamic nodes
provided through `NodeSetFactory` can also supply the status in code. Relevant
source locations include:

- `../2026-06-knime-oss/knime-core/org.knime.core/src/eclipse/org/knime/core/node/NodeFactory.java`
- `../2026-06-knime-oss/knime-core/org.knime.core/src/eclipse/org/knime/core/node/extension/NodeSpecCollectionProvider.java`

Hidden nodes, marked with `hidden="true"`, are not counted as deprecated. They
can also be absent from the ordinary node repository while remaining loadable,
but do not receive the same deprecation label. Hidden and deprecated status are
therefore retained as separate fields.

Deprecation is also distinct from migration and replacement. KNIME provides:

- `NodeFactoryClassMapper`, which maps persisted factory-class names to newer
  implementations; and
- `NodeMigrationRule`, which registers workflow-node migration rules.

Their schemas are:

- `../2026-06-knime-oss/knime-core/org.knime.core/schema/NodeFactoryClassMapper.exsd`
- `../2026-06-knime-oss/knime-database/org.knime.workflow.migration/schema/NodeMigrationRule.exsd`

Mapper and migration-rule records are compatibility evidence, not deprecation
markers.

The implemented mining rules are:

1. Parse `plugin.xml` as structured XML.
2. Extract ordinary registrations from
   `org.knime.workbench.repository.nodes`.
3. Count only case-insensitive `deprecated="true"` as declared deprecation.
4. Extract dynamic node sets separately from
   `org.knime.workbench.repository.nodesets`.
5. Parse node-description XML as a secondary source.
6. Retain `hidden="true"` separately.
7. Extract factory-class mappers and migration rules into separate tables.
8. Do not infer removal, replacement, runtime failure, or knime2py support from
   deprecation alone.

Clone provenance is recorded in `notes/knime-oss-source-snapshot.md`.

## Snapshot Extraction Script

The full snapshot extraction script is:

- `scripts/knime_source/collect_knime_node_snapshot.py`

The cross-snapshot summary builder is:

- `scripts/knime_source/build_knime_node_snapshot_summary.py`

For a given source snapshot, it parses all repositories below the source root
and reports:

| Column | Meaning |
|---|---|
| `plugin_xml_registered_nodes` | Number of ordinary node registrations found in `plugin.xml` under `org.knime.workbench.repository.nodes`. |
| `plugin_xml_deprecated_nodes` | Number of ordinary node registrations where `deprecated="true"`. This is the primary deprecated-node count. |
| `plugin_xml_unique_deprecated_factory_classes` | Number of unique non-empty `factory-class` values among deprecated ordinary node registrations. |
| `plugin_xml_hidden_nodes` | Number of ordinary node registrations where `hidden="true"`. |
| `plugin_xml_registered_nodesets` | Number of dynamic nodeset registrations found in `plugin.xml` under `org.knime.workbench.repository.nodesets`. |
| `plugin_xml_deprecated_nodesets` | Number of dynamic nodeset registrations where `deprecated="true"`. |
| `node_description_files` | Number of parsed `*NodeFactory.xml` files whose root element is `knimeNode`. |
| `node_description_deprecated_files` | Number of those node-description files where the root `knimeNode` has `deprecated="true"`. |

The node-description count is a secondary marker and should not be added to the
primary `plugin_xml_deprecated_nodes` count, because both mechanisms can refer
to the same node.

The parser uses Python's standard `xml.etree.ElementTree` XML parser. It walks
the source tree and skips `.git`, `target`, `bin`, and `.metadata` directories.
Malformed or unreadable XML files are ignored. Boolean XML attributes are
treated as true only when their value is case-insensitively equal to `true`.

For `plugin.xml`, the extractor counts direct child elements inside these
extension points:

| Extension point | Counted child element | Output table |
|---|---|---|
| `org.knime.workbench.repository.nodes` | `node` | `plugin_nodes.csv` |
| `org.knime.workbench.repository.nodesets` | `nodeset` | `plugin_nodes.csv` |
| `org.knime.core.NodeFactoryClassMapper` | `NodeFactoryClassMapper` | `factory_class_mappers.csv` |
| `org.knime.workflow.migration.NodeMigrationRule` | `Rule` | `migration_rules.csv` |

For node-description XML, the extractor reads files ending in
`NodeFactory.xml` whose root element is `knimeNode`.

The full snapshot extractor writes one row per observed source-code record and
adds `snapshot_id` and `snapshot_date` to every row. It produces:

- `plugin_nodes.csv`: ordinary node and nodeset registrations from `plugin.xml`
- `node_descriptions.csv`: parsed `*NodeFactory.xml` files
- `factory_class_mappers.csv`: `org.knime.core.NodeFactoryClassMapper`
  registrations
- `migration_rules.csv`: `org.knime.workflow.migration.NodeMigrationRule`
  registrations
- `summary.csv`: derived counts for the snapshot

## Result Table

The summary table is:

- `data/processed/knime_snapshots/knime_node_snapshot_summary.csv`

Each row records one source-code state and the counts produced by
the snapshot files under `data/original/knime_snapshots/`. The table is
rebuilt with `scripts/knime_source/build_knime_node_snapshot_summary.py`.

Current columns:

```text
snapshot_id,snapshot_kind,snapshot_date,knime_version,source_basis,
repos_processed,repos_skipped,plugin_xml_files,repos_with_plugin_xml,
registered_nodes,registered_nodesets,registered_total,
unique_factory_classes,deprecated_nodes,deprecated_nodesets,
deprecated_total,unique_deprecated_factory_classes,
deprecated_node_percent,hidden_nodes,hidden_node_percent,
deprecated_and_hidden_nodes,node_description_files,
description_deprecated_files,description_deprecated_percent,
factory_class_mapper_count,migration_rule_count,
nodes_added_since_previous,nodes_removed_since_previous,
nodes_newly_deprecated_since_previous,
nodes_no_longer_deprecated_since_previous,
nodes_newly_hidden_since_previous,nodes_no_longer_hidden_since_previous,
nodes_category_changed_since_previous
```

The `snapshot_kind` column identifies whether the row is based on an official
product tag or a date-based source snapshot. The `snapshot_date` column is the
tag date or the target date used for the source snapshot.

Transition columns compare each row with the previous snapshot in chronological
order. The node identity key is the non-empty `factory_class` value. If a node
registration has no `factory_class`, the fallback key is:

```text
plugin_xml:element:category_path
```

This means that transition counts are metadata-level approximations. They are
strongest for ordinary nodes with stable factory classes, and weaker for records
without factory classes or for refactorings that change factory-class names.

## Date-Based Rows

Date-based rows are produced by checking out every
repository under the KNIME source root to the latest commit at or before:

```text
<target-date> 23:59:59
```

The checkout script is:

- `scripts/knime_source/checkout_knime_oss_by_date.sh`

For every date in the register, the checkout command followed this template:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  <YYYY-MM-DD> \
  data/original/knime_snapshots/<YYYY-MM-DD>/logs/checkout_<YYYY-MM-DD>.csv
```

The equivalent Makefile form is:

```bash
make knime-snapshot \
  KNIME_OSS_ROOT=../2026-06-knime-oss \
  SNAPSHOT_DATE=<YYYY-MM-DD>
```

The extraction command followed this template:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-<YYYY-MM-DD> \
  --snapshot-date <YYYY-MM-DD> \
  --out-dir data/original/knime_snapshots/<YYYY-MM-DD>
```

The date-based snapshot register currently contains annual checkpoints,
major-version anchor dates, and the final current-state checkout:

| Snapshot date | Purpose | Repositories checked out | Repositories skipped |
|---|---:|---:|---:|
| `2018-04-03` | Earliest local 3.x-era anchor | 44 | 46 |
| `2019-01-01` | Annual checkpoint | 45 | 45 |
| `2019-12-05` | 4.x-era major-version anchor | 53 | 37 |
| `2020-01-01` | Annual checkpoint | 54 | 36 |
| `2021-01-01` | Annual checkpoint | 60 | 30 |
| `2022-01-01` | Annual checkpoint | 67 | 23 |
| `2023-01-01` | Annual checkpoint | 72 | 18 |
| `2023-02-22` | 5.x-era major-version anchor | 72 | 18 |
| `2024-01-01` | Annual checkpoint | 80 | 10 |
| `2025-01-01` | Annual checkpoint | 86 | 4 |
| `2026-01-01` | Annual checkpoint | 90 | 0 |
| `2026-03-03` | 5.11-era major-version anchor | 90 | 0 |
| `2026-06-28` | Final current-state checkout | 90 | 0 |

Each row has its own manifest and per-record extraction tables under:

```text
data/original/knime_snapshots/<snapshot-date>/
```

For `2026-01-01`, the checkout command was:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2026-01-01 \
  data/original/knime_snapshots/2026-01-01/logs/checkout_2026-01-01.csv
```

The checkout script:

1. Finds each Git repository immediately below the source root.
2. Finds the latest commit at or before the target date using `git rev-list`.
3. Checks out that commit in detached-head mode.
4. Writes a manifest with repository name, status, target date, selected commit,
   selected commit date, and previous head.

For this run, the script processed 90 repositories, checked out 90, and skipped
0. The manifest is:

- `data/original/knime_snapshots/2026-01-01/logs/checkout_2026-01-01.csv`

The script sets `GIT_LFS_SKIP_SMUDGE=1` so that historical checkouts do not
download large Git LFS payloads. This is acceptable for the deprecated-node
analysis because the mining step reads text metadata such as `plugin.xml` and
`*NodeFactory.xml`.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2026-01-01 \
  --snapshot-date 2026-01-01 \
  --out-dir data/original/knime_snapshots/2026-01-01
```

The snapshot output contains:

```text
plugin_nodes.csv
node_descriptions.csv
factory_class_mappers.csv
migration_rules.csv
summary.csv
```

This row was one historical checkpoint in the series.

For `2025-01-01`, the same process was run with:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2025-01-01 \
  data/original/knime_snapshots/2025-01-01/logs/checkout_2025-01-01.csv
```

This processed 90 repositories, checked out 86, and skipped 4 repositories
that had no commit at or before the target date.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2025-01-01 \
  --snapshot-date 2025-01-01 \
  --out-dir data/original/knime_snapshots/2025-01-01
```

This row was one historical checkpoint in the series.

For `2024-01-01`, the same process was run with:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2024-01-01 \
  data/original/knime_snapshots/2024-01-01/logs/checkout_2024-01-01.csv
```

This processed 90 repositories, checked out 80, and skipped 10 repositories
that had no commit at or before the target date.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2024-01-01 \
  --snapshot-date 2024-01-01 \
  --out-dir data/original/knime_snapshots/2024-01-01
```

This row was one historical checkpoint in the series.

For `2023-01-01`, the same process was run with:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2023-01-01 \
  data/original/knime_snapshots/2023-01-01/logs/checkout_2023-01-01.csv
```

This processed 90 repositories, checked out 72, and skipped 18 repositories
that had no commit at or before the target date.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2023-01-01 \
  --snapshot-date 2023-01-01 \
  --out-dir data/original/knime_snapshots/2023-01-01
```

This row was one historical checkpoint in the series.

For `2022-01-01`, the same process was run with:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2022-01-01 \
  data/original/knime_snapshots/2022-01-01/logs/checkout_2022-01-01.csv
```

This processed 90 repositories, checked out 67, and skipped 23 repositories
that had no commit at or before the target date.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2022-01-01 \
  --snapshot-date 2022-01-01 \
  --out-dir data/original/knime_snapshots/2022-01-01
```

This row was one historical checkpoint in the series.

For `2021-01-01`, the same process was run with:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2021-01-01 \
  data/original/knime_snapshots/2021-01-01/logs/checkout_2021-01-01.csv
```

This processed 90 repositories, checked out 60, and skipped 30 repositories
that had no commit at or before the target date.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2021-01-01 \
  --snapshot-date 2021-01-01 \
  --out-dir data/original/knime_snapshots/2021-01-01
```

For `2020-01-01`, the same process was run with:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2020-01-01 \
  data/original/knime_snapshots/2020-01-01/logs/checkout_2020-01-01.csv
```

This processed 90 repositories, checked out 54, and skipped 36 repositories
that had no commit at or before the target date.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2020-01-01 \
  --snapshot-date 2020-01-01 \
  --out-dir data/original/knime_snapshots/2020-01-01
```

These rows were historical checkpoints in the series.

For `2019-01-01`, the same process was run with:

```bash
bash scripts/knime_source/checkout_knime_oss_by_date.sh \
  ../2026-06-knime-oss \
  2019-01-01 \
  data/original/knime_snapshots/2019-01-01/logs/checkout_2019-01-01.csv
```

This processed 90 repositories, checked out 45, and skipped 45 repositories
that had no commit at or before the target date.

The full per-record snapshot was collected with:

```bash
python3 scripts/knime_source/collect_knime_node_snapshot.py \
  ../2026-06-knime-oss \
  --snapshot-id date-2019-01-01 \
  --snapshot-date 2019-01-01 \
  --out-dir data/original/knime_snapshots/2019-01-01
```

This row was one historical checkpoint in the series.

The cross-snapshot summary was rebuilt with:

```bash
python3 scripts/knime_source/build_knime_node_snapshot_summary.py \
  data/original/knime_snapshots \
  --out data/processed/knime_snapshots/knime_node_snapshot_summary.csv
```

After the final extraction, the KNIME repositories were intentionally left at
the `2026-06-28` date-based state. This is the current-state row available from
the local clone.

## Extending The Table

To add another date-based row:

1. Choose a target date.
2. Run `make knime-snapshot SNAPSHOT_DATE=<YYYY-MM-DD>` with `KNIME_OSS_ROOT`
   set to the local KNIME source clone. This writes the checkout manifest under
   the snapshot's `logs/` directory and collects per-record metadata into the
   snapshot directory.
3. Rebuild `data/processed/knime_snapshots/knime_node_snapshot_summary.csv` with
   `scripts/knime_source/build_knime_node_snapshot_summary.py`.
4. Keep the checkout manifest and per-record snapshot tables for auditability.

To add another tag-based row:

1. Identify the official KNIME Analytics Platform tag or component state.
2. Checkout the source repositories to the corresponding tag or documented
   component commits.
3. Run `scripts/knime_source/collect_knime_node_snapshot.py` into a snapshot-specific output
   directory.
4. Rebuild `data/processed/knime_snapshots/knime_node_snapshot_summary.csv` with
   `scripts/knime_source/build_knime_node_snapshot_summary.py`.
5. Record the tag, commit, and date used to define the row.

Tag-based rows represent official release states when the tags are available.
Date-based rows represent source-code snapshots near a selected date and should
be labelled as date-based snapshots in the `snapshot_kind` and `source_basis`
columns.

## k2pweb Evidence Integration

The longitudinal source data describes which nodes KNIME declares deprecated,
hidden, or subject to compatibility metadata. The current second evidence
stream uses an approved factory-only export from k2pweb to measure which node
types occur in deduplicated workflows. The export does not contain translation
support or conversion outcomes.

The integration has five stages:

1. Export factory occurrences with study-local deduplicated workflow indexes;
   exclude raw workflows, settings, paths, URLs, credentials, IP addresses, and
   stable user or session identifiers.
2. Treat deduplicated workflows, node occurrences, and distinct node types as
   separate units and record the observation window.
3. Build a unique deprecated-factory registry from the 2026-06-28 ordinary-node
   registrations.
4. Join complete factory-class identifiers exactly and retain unmatched
   identifiers with explicit join states.
5. Produce workflow-, occurrence-, and factory-level aggregates with recorded
   input and classification dates.

The executable analysis is
`scripts/k2pweb/build_deprecated_node_usage.py`. It writes:

- `data/processed/k2pweb/deprecated_node_factory_registry.csv`;
- `data/processed/k2pweb/k2pweb_factory_join_audit.csv`; and
- `data/processed/k2pweb/k2pweb_deprecated_node_usage_summary.csv`.

The current exact join matches 146 of 160 factory classes and 2549 of 2745
occurrences. It identifies deprecated factories in 21 of 62 workflows and in
294 node occurrences. Fourteen factory classes remain unmatched and are not
assigned a deprecation state.

The input tables, controlled labels, join rules, metrics, and privacy
requirements are specified in `scripts/k2pweb/README.md`. The current
factory-occurrence export supports workflow-, occurrence-, and factory-level
deprecation prevalence after exact matching. Translation-support and
conversion-outcome results remain out of scope until those fields are supplied
and validated.

## Reproducibility Notes And Limitations

The current work is reproducible from the scripts and retained intermediate
tables in this repository. A researcher can rerun the extraction by cloning the
public `knime-oss` repositories, checking out each target date with
`scripts/knime_source/checkout_knime_oss_by_date.sh`, collecting per-snapshot metadata with
`scripts/knime_source/collect_knime_node_snapshot.py`, and rebuilding
`data/processed/knime_snapshots/knime_node_snapshot_summary.csv` with
`scripts/knime_source/build_knime_node_snapshot_summary.py`.

The retained files needed to audit the current results are:

- `data/processed/knime_snapshots/knime_oss_repositories.csv`
- `data/processed/knime_snapshots/knime_node_snapshot_summary.csv`
- `data/processed/k2pweb/deprecated_node_factory_registry.csv`
- `data/processed/k2pweb/k2pweb_factory_join_audit.csv`
- `data/processed/k2pweb/k2pweb_deprecated_node_usage_summary.csv`
- `data/original/k2pweb/factories.csv`
- `data/original/knime_snapshots/<snapshot-date>/logs/checkout_<snapshot-date>.csv`
- `data/original/knime_snapshots/<snapshot-date>/plugin_nodes.csv`
- `data/original/knime_snapshots/<snapshot-date>/node_descriptions.csv`
- `data/original/knime_snapshots/<snapshot-date>/factory_class_mappers.csv`
- `data/original/knime_snapshots/<snapshot-date>/migration_rules.csv`
- `data/original/knime_snapshots/<snapshot-date>/summary.csv`

Important limitations for the study:

- The analysis covers public `knime-oss` repositories available in the local
  clone, not proprietary or unavailable KNIME extensions.
- Date-based snapshots approximate source states near selected dates. They are
  not exact binary release builds.
- The final `2026-06-28` row is the current state available from the local Git
  refs, not a fresh network fetch made on every analysis run.
- Earlier rows have fewer checked-out repositories because some repositories
  had no commit at or before the target date.
- The metadata extraction measures declared node status in source files. It
  does not test whether workflows execute successfully in KNIME.
- Ordinary-node and node-set registrations are currently extracted from
  `plugin.xml`; extension contributions in `fragment.xml` are not yet included.
- Deprecated, hidden, removed, and migrated nodes are related but distinct
  compatibility states and should not be collapsed into a single category.
- Transition counts depend on metadata identity keys. They may undercount or
  overcount lifecycle events when factory-class names are refactored.
- The current k2pweb observations represent a self-selected population of
  conversion requests, not all KNIME workflows.
- Submission-level associations between deprecation and conversion outcomes do
  not establish that deprecation caused a failure.
