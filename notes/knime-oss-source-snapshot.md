# KNIME OSS Source Snapshot

This note records the local KNIME source-code snapshot cloned for repository mining.

## Clone Target

- Organization: `knime-oss`
- Source organization URL: https://github.com/knime-oss
- Local path relative to this repository: `../2026-06-knime-oss`
- Clone script: `scripts/knime_source/clone_knime_oss_repos.sh`
- Clone command:

```bash
bash scripts/knime_source/clone_knime_oss_repos.sh ../2026-06-knime-oss
```

The current Makefile form also writes a retained validation manifest:

```bash
make clone-knime-oss \
  KNIME_OSS_ROOT=../2026-06-knime-oss \
  KNIME_CLONE_MANIFEST=data/original/knime_source/logs/knime_oss_clone_manifest.csv
```

## Clone Method

The script queries the GitHub REST API for all public repositories in the
`knime-oss` organization. It clones missing repositories with:

```bash
git clone --filter=blob:none
```

This keeps repository history available for mining while avoiding eager download of all historical blobs. During checkout, some repositories still downloaded large filtered or Git LFS-managed content.

Existing repositories are fetched from `origin`. The script then validates
that every discovered repository is a Git worktree, has an origin identifying
the expected `knime-oss` repository, and has a resolvable HEAD commit. It also
fails if an unexpected local Git repository would enter the later date-based
checkout. The CSV manifest records the discovered inventory, action, validation
status, origin, HEAD, and any failure note. A successful zero exit status is the
automatic handoff to date-based checkout.

## Result

- Repositories processed: 91
- Final cloned repository count: 91
- Final disk usage: 9.8G
- Clone status: completed

## Observed Warnings

The clone of `knime-r` completed with a non-fatal Git LFS warning:

```text
Encountered 4 files that should have been pointers, but weren't:
    org.knime.ext.r3.bin.win32.x86/R-Inst/library/RCurl/doc/withCookies.Rdb
    org.knime.ext.r3.bin.win32.x86/R-Inst/library/lme4/testdata/crabs_randdata00.Rda
    org.knime.ext.r3.bin.win32.x86/R-Inst/library/lme4/testdata/crabs_randdata2.Rda
    org.knime.ext.r3.bin.win32.x86/R-Inst/library/lme4/testdata/survdat_reduced.Rda
```

The script continued after this warning and completed all repositories.

## Notes For Data Mining

- Treat `../2026-06-knime-oss` as an external source snapshot, not as project source code.
- Do not commit the cloned repositories into this paper repository.
- Record future mining scripts, derived tables, and figures in this project repository.
- If the source snapshot is updated later, retain the generated clone manifest
  and record disk usage and any notable warnings in this note or a dated
  successor note.
