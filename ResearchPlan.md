# Research Plan: Deprecated KNIME Nodes and knime2py

## Initial Assessment

This is a viable paper idea, but it needs a sharper research contribution than
"count deprecated KNIME nodes".

The strongest angle is:

> Deprecated visual workflow components as a reproducibility and maintenance
> risk in scientific and data-science workflows.

This connects directly to the larger review: visual workflows are not only
graphs; they depend on platform-specific nodes whose lifecycle changes over
time. Deprecated nodes can break reuse, migration, translation to code, and
long-term reproducibility.

## Gap and Contribution

The gap appears to exist. There is adjacent work on scientific workflow
reproducibility, workflow reuse, workflow decay, provenance, tool support, and
visual analytics, but the preliminary search did not find a study that
systematically examines deprecated KNIME nodes or their occurrence in real
user-submitted workflows.

The paper can therefore be framed as:

> the first empirical study of deprecated-node lifecycle and real-world
> deprecated-node use in KNIME workflows.

The contribution should combine two forms of evidence:

1. **KNIME repository mining.** This gives platform-side evidence: where
   deprecation appears in source code and metadata, which node families are
   affected, when deprecation appears, and whether replacement or migration
   information is available.
2. **k2pweb / knime2py usage statistics.** This gives demand-side evidence:
   which deprecated nodes appear in real user-submitted conversion requests,
   how frequently they appear, and how they affect translation support.

This combination is stronger than either dataset alone. Repository mining
shows the lifecycle of KNIME components. k2pweb shows practical impact that
only this project can currently observe.

Current title:

> Deprecated KNIME Nodes in Source Repositories and User Workflows

The key claim should be careful:

> Prior work discusses scientific workflow reproducibility, reuse, workflow
> decay, and tool evolution, but we found no study that systematically
> analyzes deprecated KNIME nodes and their occurrence in real user-submitted
> workflows.

## Empirical Data Sources

The paper can combine two complementary data sources.

1. KNIME-side evidence:
   - mine KNIME repositories and extensions for deprecated nodes;
   - record node name, extension, replacement node if documented,
     deprecation version/date if available, category, and reason if available;
   - classify deprecated nodes by function, such as IO, preprocessing,
     machine learning, visualization, scripting, database, chemistry, and
     workflow control.

2. k2pweb request evidence:
   - use the approved export of 62 deduplicated workflows, 2745 node
     occurrences, and 160 factory classes;
   - join complete factory classes exactly to the selected KNIME snapshot;
   - report join coverage and retain unresolved identifiers;
   - measure workflow- and occurrence-level deprecated-node exposure; and
   - defer comparisons with translation support or conversion outcomes until
     those fields are available.

The result is reported at workflow, node-occurrence, and distinct-factory
levels. These denominators must remain separate; no user count is inferred from
the workflow indexes.

## k2pweb Data Source

k2pweb should be treated as a structured empirical source, not simply as a log
file. Before analysis, define and verify the unit of every record:
submission, deduplicated workflow, node occurrence, or distinct node type.
Retries and repeated submissions can otherwise inflate prevalence estimates.

The repository should receive only an approved anonymized export or aggregate
tables. Raw k2pweb/knime2py logs, uploaded workflows, node settings, paths,
URLs, credentials, IP addresses, and stable user or session identifiers must
remain outside the project. The current export uses study-local workflow
indexes and records its observation window. Its exporter version and upstream
deduplication implementation were not supplied and remain provenance
limitations.

The preferred node identifier is the complete KNIME factory class. Join it
exactly to the repository-mined lifecycle data and record join coverage. Keep
unmatched and ambiguous identifiers rather than silently dropping them. A
known mapper or migration rule may justify an explicit alias, but suffix or
partial-string matching is not sufficient evidence of node identity.

At minimum, a richer future k2pweb analysis should report:

- submissions, deduplicated workflows, node occurrences, and node types as
  separate counts;
- workflows containing one or more deprecated nodes;
- deprecated-node occurrences as a share of all node occurrences;
- the most frequently observed deprecated node types, subject to disclosure
  controls;
- exact join coverage and unresolved identifiers;
- knime2py support status for deprecated and non-deprecated nodes; and
- conversion outcomes for workflows with and without deprecated nodes.

These comparisons are descriptive. They do not prove that deprecation caused a
conversion failure unless error-level or controlled evidence isolates the node.
The full proposed data contract is recorded in `scripts/k2pweb/README.md`.

## Stronger Contribution

The paper becomes stronger if it adds a maintenance and translation-impact
layer:

- How many deprecated nodes have clear replacements?
- How many replacements are semantically equivalent versus approximate?
- Which deprecated nodes block deterministic KNIME-to-Python translation?
- Can migration rules be generated for some deprecated nodes?
- How often are deprecated nodes part of core analytical logic versus
  peripheral IO or visualization?
- Are deprecated nodes clustered in older workflows, or do they still appear
  in recent user submissions?

A practical artifact would make the contribution more credible, for example:

- a deprecated-node detector for KNIME workflows;
- a migration-advisory table linking deprecated nodes to replacements;
- warnings integrated into `knime2py` or k2pweb;
- translation rules for deprecated nodes whose semantics are still recoverable;
- a small reproducible dataset of aggregate deprecated-node statistics.

## Possible Research Questions

1. How prevalent are deprecated KNIME nodes in real submitted workflows?
2. Which deprecated node families create the largest practical maintenance
   burden?
3. To what extent does KNIME documentation provide machine-actionable
   migration paths?
4. How do deprecated nodes affect workflow-to-code translation and
   reproducibility?
5. Can deprecated-node usage be converted into actionable warnings, migration
   suggestions, or translation rules?

## Method Sketch

1. Define "deprecated node" carefully.
   - Deprecated in source code.
   - Marked deprecated or obsolete in node metadata.
   - Hidden from normal UI but still executable.
   - Replaced by another node.
   - Removed from current KNIME distributions.
   - Unsupported by `knime2py`.

   These categories should not be collapsed. Deprecated, removed, replaced,
   and unsupported mean different things.

2. Mine KNIME metadata.
   - Clone relevant KNIME repositories.
   - Search for deprecation markers in node factories, plugin descriptors,
     XML metadata, documentation, migration code, and node annotations.
   - Build a structured table:
     `node_id`, `node_name`, `extension`, `category`, `deprecated_marker`,
     `replacement`, `source_file`, `version_or_date`, `evidence_url`,
     `notes`.

3. Mine k2pweb / knime2py submissions.
   - Extract only structural metadata unless user consent covers more.
   - Do not store personal data, data files, credentials, node settings that
     may contain secrets, or identifiable workflow content.
   - Count deprecated node occurrences and workflow-level exposure.
   - Separate repeated submissions from distinct workflows where possible.

4. Assess translation impact.
   - For each deprecated node encountered in user requests, classify:
     supported by `knime2py`, unsupported, replacement available,
     deterministic mapping available, ambiguous semantics, or requires manual
     intervention.

5. Report aggregate statistics.
   - Number of deprecated node types in KNIME metadata.
   - Number and percentage of submitted workflows containing deprecated nodes.
   - Deprecated node occurrences by category.
   - Top deprecated nodes observed in practice.
   - Replacement availability and migration confidence.
   - Effect on translation success/failure.

## Suggested Dataset Schema

Before collecting data, define a table schema so the analysis is auditable:

- `node_id`
- `node_name`
- `extension`
- `category`
- `first_seen_version`
- `deprecated_seen_version`
- `deprecated_commit`
- `deprecated_marker`
- `replacement_node`
- `replacement_evidence`
- `source_file`
- `evidence_url`
- `k2pweb_occurrences`
- `k2pweb_workflow_count`
- `translation_status`
- `migration_status`
- `notes`

For the current export, report the verified units: 62 deduplicated workflows,
2745 node occurrences, and 160 distinct factory classes. Do not describe node
occurrences as workflows, submissions, sessions, or users.

## Cautions

- Do not expose user-submitted workflows or sensitive metadata.
- Report only aggregate statistics unless explicit permission exists.
- Distinguish node occurrences from distinct workflows.
- Avoid claiming that deprecated nodes prove KNIME is unreproducible. A more
  defensible claim is that deprecated components are one measurable threat to
  long-term workflow reuse, maintainability, and translation.
- Do not frame the paper as an attack on KNIME. Frame it as empirical evidence
  about lifecycle risk in visual analytical workflow systems.
- Keep unsupported-by-`knime2py` separate from deprecated-in-KNIME.

## Preliminary Literature Search

Search date: 2026-06-24.

Searches were run through web and scholarly-index queries for:

- `deprecated KNIME nodes`
- `KNIME deprecated workflow`
- `KNIME obsolete nodes`
- `KNIME reproducibility deprecated`
- `scientific workflow deprecated tools`
- `workflow reusability tool upgrading`
- `workflow decay scientific workflows reproducibility`

No exact scholarly article was found that appears to study deprecated KNIME
nodes directly. That is promising for novelty, but it also means the paper
must anchor itself in adjacent literature rather than claim an established
subfield.

Closest related work found:

- **KNIME for reproducible cross-domain analysis of life science data**
  (2017), DOI: `10.1016/j.jbiotec.2017.07.028`.
  This is a KNIME reproducibility/use paper, but it does not appear to focus
  on deprecated nodes.

- **Reusability Challenges of Scientific Workflows: A Case Study for Galaxy**
  (2023), arXiv: `2309.07291`.
  This is highly relevant because it reports workflow-reuse barriers such as
  tool upgrading, unavailable tool support, design flaws, incomplete workflows,
  and workflow loading failures. It is not KNIME-specific.

- **CodeR3: A GenAI-Powered Workflow Repair and Revival Ecosystem** (2025),
  arXiv: `2511.19510`.
  This is relevant to workflow decay and revival, especially for legacy
  workflow systems and obsolete dependencies. It is not KNIME-specific.

- **Scientific workflows for computational reproducibility in the life
  sciences: Status, challenges and opportunities** (2017), DOI:
  `10.1016/j.future.2017.01.012`.
  This is broader reproducibility background for scientific workflows.

- **The role of metadata in reproducible computational research** (2021), DOI:
  `10.1016/j.patter.2021.100322`.
  This is relevant for arguing that node lifecycle, version, and replacement
  metadata matter for reproducibility.

## Candidate Literature Sources

The following sources may support this study. They should be retrieved,
screened, and read before making evidence claims; source papers are not bundled
in this repository.

### KNIME and Visual Workflow Context

- **KNIME: The Konstanz Information Miner** (Berthold et al., 2008), DOI:
  `10.1007/978-3-540-78246-9_38`.
  Use to introduce KNIME as the visual workflow platform being studied and to
  ground terminology such as nodes, ports, and workflow construction.

- **The WEKA Data Mining Software: An Update** (Hall et al., 2009), DOI:
  `10.1145/1656274.1656278`.
  Use as a comparison case for visual/workflow-style machine-learning
  environments. It can help show that visual data-mining workbenches are a
  broader class, not a KNIME-only phenomenon.

- **State of Art of Data Mining and Learning Analytics Tools in Higher
  Education** (noted in `notes.md`), DOI: `10.3991/ijet.v15i21.16435`.
  Use only as background that KNIME, RapidMiner, WEKA, Orange, and related
  tools appear in applied data-mining/learning-analytics contexts. It is not
  evidence about deprecated nodes.

### KNIME Reproducibility Examples

- **Improving the Reproducibility of Geospatial Scientific Workflows: The Use
  of Geosocial Media in Facilitating Disaster Response** (noted in
  `notes.md`), DOI: `10.1080/14498596.2019.1654944`.
  Use as KNIME-specific background for reproducible scientific workflows. It
  supports the claim that KNIME workflows are used as reproducible research
  artifacts, making lifecycle risks such as deprecation important.

- **K-span: Open and reproducible spatial analytics using scientific
  workflows** (Forkan et al., 2023), DOI: `10.3389/feart.2023.1130262`.
  Use as a recent KNIME-based reproducible spatial-analytics example. It can
  motivate why deprecated nodes matter in long-lived, shared workflow tools.

- **Solar Radiation Modeling With KNIME and Solar Analyst: Increasing
  Environmental Model Reproducibility Using Scientific Workflows** (noted in
  `notes.md`), DOI: `10.1016/j.envsoft.2020.104780`.
  Use as another KNIME-specific reproducibility case. It can support the
  argument that workflow reuse depends on recovering steps, parameters,
  dependencies, and executable components over time.

### Scientific Workflow Reuse, Decay, and Metadata

- **Scientific workflows for computational reproducibility in the life
  sciences: Status, challenges and opportunities** (Cohen-Boulakia et al.,
  2017), DOI: `10.1016/j.future.2017.01.012`.
  Use as broad workflow-reproducibility background and to position deprecated
  nodes as one concrete workflow-maintenance challenge.

- **Workflows and e-Science: An overview of workflow system features and
  capabilities** (Deelman et al., 2009), DOI:
  `10.1016/j.future.2008.06.012`.
  Use for general scientific workflow terminology: tasks, dependencies,
  provenance, execution, and interoperability.

- **The role of metadata in reproducible computational research** (recorded in
  the preliminary search), DOI: `10.1016/j.patter.2021.100322`.
  Use to argue that deprecation status, node version, replacement mapping, and
  extension identity are metadata needed for long-term workflow reuse.

- **Reusability Challenges of Scientific Workflows: A Case Study for Galaxy**
  (found in search), arXiv: `2309.07291`.
  Use as the closest methodological analogue. It studies workflow-reuse
  barriers such as tool upgrading and unavailable tool support. The KNIME
  deprecated-node paper can be positioned as a platform-specific, node-level
  version of this broader reusability problem.

- **CodeR3: A GenAI-Powered Workflow Repair and Revival Ecosystem** (found in
  search), arXiv: `2511.19510`.
  Use cautiously as recent workflow-decay/revival background. It supports the
  framing that legacy workflows can decay because services, dependencies, and
  execution environments change.

### Provenance, Traceability, and Inspectability

- **An Extensible Framework for Provenance in Human Terrain Visual Analytics**
  (Walker et al., 2013), DOI: `10.1109/tvcg.2013.132`.
  Use to connect visual analytical workflows with provenance. Deprecated-node
  detection can be framed as part of provenance about the computational
  components used in analysis.

- **Storage and Use of Provenance Information for Relational Database
  Queries** (Bao et al., 2011), DOI:
  `10.1007/978-3-642-20152-3_32`.
  Use for lineage/provenance concepts where outputs depend on transformations.
  It is not KNIME-specific, but supports the idea that dependency history
  matters for explaining results.

- **DCTracVis: A System Retrieving and Visualizing Traceability Links Between
  Source Code and Documentation** (Chen et al., 2018), DOI:
  `10.1007/s10515-018-0243-8`.
  Use as a traceability analogue: the deprecated-node study needs trace links
  between workflow nodes, KNIME source-code declarations, documentation, and
  replacement nodes.

- **Improving Automated Documentation to Code Traceability by Combining
  Retrieval Techniques** (Chen and Grundy, 2011), DOI:
  `10.1109/ase.2011.6100057`.
  Use as background for automatically connecting deprecated-node evidence in
  source code and documentation.

- **Visualizing Traceability Links Between Source Code and Documentation**
  (Chen and Grundy, 2012), DOI: `10.1109/vlhcc.2012.6344496`.
  Use as a possible design reference if the study produces a migration
  advisory or evidence browser.

### Repository Mining, Versioning, and Maintenance Analogues

- **Why the Proof Fails in Different Versions of Theorem Provers: An
  Empirical Study of Compatibility Issues in Isabelle** (Luan et al., 2025),
  DOI: `10.1145/3715787`.
  Use as an empirical analogue for version-induced breakage. It is not about
  KNIME, but it supports studying how platform evolution affects artifacts
  that used to work.

- **A Study of Single Statement Bugs Involving Dynamic Language Features**
  (Sui et al., 2022), DOI: `10.1145/3524610.3527883`.
  Use only as a maintenance/hidden-runtime-behavior analogy if needed. It can
  support discussion of why visible workflow graphs may hide behavior that is
  difficult to translate or repair.

- **Test Flakiness' Causes, Detection, Impact and Responses: A Multivocal
  Review** (Rasheed et al., 2023), DOI: `10.1016/j.jss.2023.111837`.
  Use for validation threats: if deprecated-node migration affects execution
  order, external dependencies, or environment assumptions, tests may become
  unstable or hard to interpret.

- **An Empirical Study of Flaky Tests in JavaScript** (Hashemi et al., 2022),
  DOI: `10.1109/icsme55016.2022.00011`.
  Use as a concrete empirical-testing analogue for environment- and
  dependency-sensitive behavior in software artifacts.

### Workflow Translation and Migration Implications

- **From Verified Model to Executable Program: The PAT Approach** (Zhu et al.,
  2015), DOI: `10.1007/s11334-015-0269-z`.
  Use to support the idea that translation from higher-level models to code
  requires explicit semantic preservation, not just syntactic conversion.

- **Generating Obligations, Assertions and Tests from UI Models** (Bowen and
  Reeves, 2017), DOI: `10.1145/3095807`.
  Use to motivate generated checks for migrated or translated deprecated
  nodes.

- **Model-Based Testing of Interactive Systems Using Interaction Sequences**
  (Turner et al., 2020), DOI: `10.1145/3397873`.
  Use as model-based testing background for workflows that combine visual and
  functional components.

- **Creating Formal Models from Informal Design Artefacts** (Bowen et al.,
  2022), DOI: `10.1080/10447318.2022.2095833`.
  Use to justify translating informal/visual artifacts into more explicit
  models before validation or migration.

- **From Code to Design: A Reverse Engineering Approach** (Varoy et al.,
  2016), DOI: `10.1109/iceccs.2016.030`.
  Use if the paper discusses recovering migration meaning from code and
  metadata rather than relying only on visible workflow diagrams.

### Analytics Pipelines, Optimization, and Real-World Impact

- **PipeMind: Toward a Multi-Agent Framework for Real-Time Feedback and
  Continuous Optimization in Analytics Pipelines** (Rezaei et al., 2025),
  DOI: `10.1145/3701716.3715193`.
  Use only as a broader analytics-pipeline context source. It is useful if the
  paper discusses advisory tooling or automated feedback for problematic
  workflow components.

- **Process-Data Quality: The True Frontier of Process Mining** (ter Hofstede
  et al., 2023), DOI: `10.1145/3613247`.
  Use as an analogy for data quality in event/process logs. k2pweb logs need
  careful cleaning, deduplication, and interpretation before claiming usage
  patterns.

- **An Empirical Study of Bugs in Data Visualization Libraries** (Lu et al.,
  2025), DOI: `10.1145/3729363`.
  Use as a methodological analogue for empirical defect/risk studies in
  data-analysis infrastructure. It can help justify classifying symptoms,
  causes, and impact categories rather than only reporting counts.

### Human Factors and Visual Analytics

- **Sensemaking in Visual Analytics: Processes and Challenges** (Attfield et
  al., 2010), DOI: `10.2312/PE/EUROVAST/EUROVAST10/001-006`.
  Use to connect deprecated nodes with visual analytics sensemaking and
  interpretability: migration or replacement should not silently change the
  analyst's process.

- **An Interactive Human Centered Data Science Approach Towards Crime Pattern
  Analysis** (Qazi and Wong, 2019), DOI: `10.1016/j.ipm.2019.102066`.
  Use as background that human-centered analytical workflows involve iterative
  interaction, not only batch execution. Deprecated-node warnings should be
  understandable to workflow authors.

- **Introducing Teachers Who Use GUI-Driven Tools for the Randomization Test
  to Code-Driven Tools**, DOI:
  `10.1080/10986065.2021.1922856`.
  Use if discussing the usability impact of moving from visual workflows to
  code or migration advice. It is not about KNIME deprecation directly.

### Sources to Avoid Overusing

Some local sources are useful for the broader thesis but less central to this
paper. Formal-methods papers, agentic-code-generation papers, and backend
optimization papers should be used only if the deprecated-node study includes
translation, migration, or generated-test artifacts. Otherwise they may make a
short empirical paper look unfocused.

## Current Project Status

The repository-mining pipeline is implemented and documented in `Methods.md`
and `scripts/knime_source/`. It currently covers 13 source-date snapshots from
2018-04-03 through 2026-06-28. The processed longitudinal table is:

- `data/processed/knime_snapshots/knime_node_snapshot_summary.csv`

Selected source-date anchors are:

| Date | Version context | Registered nodes | Deprecated nodes | Share |
|---|---|---:|---:|---:|
| `2018-04-03` | Analytics Platform 3.5.3 anchor | 1301 | 193 | 14.83% |
| `2019-12-05` | Analytics Platform 4.1.0 anchor | 1191 | 227 | 19.06% |
| `2023-02-22` | Analytics Platform 5.0.0 anchor | 1442 | 433 | 30.03% |
| `2026-03-03` | Analytics Platform 5.11.0 anchor | 1503 | 503 | 33.47% |
| `2026-06-28` | Final retained source-date snapshot | 1506 | 502 | 33.33% |

These are metadata-level results. They show declared legacy surface, not
workflow execution failure. An approved factory-only k2pweb export is now
included for 62 deduplicated workflows observed from 2026-03-25 through
2026-07-15. Its exact join to the 2026-06-28 snapshot provides usage evidence,
but no translation-support or conversion-outcome fields. The join matches 146
of 160 observed factory classes and identifies deprecated factories in 21
workflows and 294 of 2745 node occurrences.

## Next Work Packages

### Node-Level Lifecycle Table

Derive a longitudinal table with fields such as:

```text
node_key, repo, factory_class, first_seen, last_seen,
first_deprecated, last_deprecated, ever_deprecated,
ever_hidden, removed_by_current_snapshot,
category_change_count, description_deprecated_seen
```

Use it to distinguish newly deprecated, persistently deprecated, hidden,
removed, category-changed, and metadata-inconsistent nodes.

### Migration and Replacement Evidence

- Link exact deprecated factory classes to `NodeFactoryClassMapper` evidence.
- Link deprecated or replaced nodes to `NodeMigrationRule` evidence.
- Separate nodes with an observed migration path from those without one.
- Do not infer replacement identity through fuzzy or suffix matching.

### Manual Semantic Validation

Inspect representative examples of:

- a deprecated node with migration evidence;
- a deprecated node without migration evidence;
- a hidden node;
- a removed identity;
- inconsistent extension and description markers; and
- a deprecated dynamic node set.

### k2pweb Extensions

The factory-only export, counting units, exact join, and unresolved identifiers
are now retained under `data/original/k2pweb/` and
`data/processed/k2pweb/`. Next, investigate unresolved identifiers against
dynamic node sets, removed registrations, and extension-distribution
boundaries. Any richer export should add translation-support and
conversion-outcome fields using the controlled labels in
`scripts/k2pweb/README.md`, while continuing to report workflow and occurrence
units separately.

## Current Judgment

This can be a credible short empirical paper or tool paper if it produces:

- a reproducible method for identifying deprecated KNIME nodes;
- aggregate evidence from real k2pweb / knime2py workflow requests;
- a taxonomy of deprecated-node risks;
- a translation or migration impact analysis; and
- preferably a practical detector or advisory artifact.

The strongest contribution is not only the statistics. It is the combination
of statistics, taxonomy, and migration/translation implications for long-term
workflow reproducibility.
