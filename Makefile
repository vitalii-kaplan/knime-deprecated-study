# Deprecated-KNIME-node study Makefile.
#
# The canonical process description is scripts/knime_source/knime_source_mining_chain.json.
# These targets provide convenient wrappers around the retained source-mining
# scripts. Network access is used only by clone-knime-oss.

.DEFAULT_GOAL := help

PYTHON ?= python3
LATEXMK ?= latexmk
SHELL := bash

KNIME_OSS_ROOT ?= ../2026-06-knime-oss
KNIME_CLONE_MANIFEST ?= data/original/knime_source/logs/knime_oss_clone_manifest.csv
SNAPSHOT_DATE ?= 2026-06-28
SNAPSHOT_ID ?= date-$(SNAPSHOT_DATE)
KNIME_SNAPSHOT_ROOT ?= data/original/knime_snapshots
KNIME_SNAPSHOT_OUT ?= $(KNIME_SNAPSHOT_ROOT)/$(SNAPSHOT_DATE)
KNIME_SNAPSHOT_SUMMARY ?= data/processed/knime_snapshots/knime_node_snapshot_summary.csv
DEPRECATED_FACTORY_REGISTRY ?= data/processed/k2pweb/deprecated_node_factory_registry.csv
K2PWEB_FACTORIES ?= data/original/k2pweb/factories.csv
K2PWEB_JOIN_AUDIT ?= data/processed/k2pweb/k2pweb_factory_join_audit.csv
K2PWEB_USAGE_SUMMARY ?= data/processed/k2pweb/k2pweb_deprecated_node_usage_summary.csv
SNAPSHOT_DATES ?= 2018-04-03 2019-01-01 2019-12-05 2020-01-01 2021-01-01 2022-01-01 2023-01-01 2023-02-22 2024-01-01 2025-01-01 2026-01-01 2026-03-03 2026-06-28

.PHONY: help
help: ## Show targets and important parameters.
	@printf 'Project targets:\n'
	@awk 'BEGIN {FS = ":.*## "}; /^[A-Za-z0-9_.-]+:.*## / {printf "  %-28s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf '\nParameters:\n'
	@printf '  KNIME_OSS_ROOT=%s\n' "$(KNIME_OSS_ROOT)"
	@printf '  KNIME_CLONE_MANIFEST=%s\n' "$(KNIME_CLONE_MANIFEST)"
	@printf '  SNAPSHOT_DATE=%s\n' "$(SNAPSHOT_DATE)"
	@printf '  SNAPSHOT_ID=%s\n' "$(SNAPSHOT_ID)"

.PHONY: clone-knime-oss
clone-knime-oss: ## Clone/update and validate public knime-oss repositories. Network required.
	bash scripts/knime_source/clone_knime_oss_repos.sh \
	  "$(KNIME_OSS_ROOT)" \
	  "$(KNIME_CLONE_MANIFEST)"

.PHONY: article
article: ## Build the focused LNCS manuscript.
	cd article && $(LATEXMK) -pdf -interaction=nonstopmode article.tex

.PHONY: checkout-knime-snapshot
checkout-knime-snapshot: ## Check out all local KNIME repositories at SNAPSHOT_DATE.
	bash scripts/knime_source/checkout_knime_oss_by_date.sh \
	  "$(KNIME_OSS_ROOT)" \
	  "$(SNAPSHOT_DATE)" \
	  "$(KNIME_SNAPSHOT_OUT)/logs/checkout_$(SNAPSHOT_DATE).csv"

.PHONY: collect-knime-snapshot
collect-knime-snapshot: ## Extract structured node metadata from the current checkout.
	$(PYTHON) scripts/knime_source/collect_knime_node_snapshot.py \
	  "$(KNIME_OSS_ROOT)" \
	  --snapshot-id "$(SNAPSHOT_ID)" \
	  --snapshot-date "$(SNAPSHOT_DATE)" \
	  --out-dir "$(KNIME_SNAPSHOT_OUT)"

.PHONY: knime-snapshot
knime-snapshot: checkout-knime-snapshot collect-knime-snapshot ## Check out and extract one source-date snapshot.

.PHONY: knime-snapshots-all
knime-snapshots-all: ## Rebuild every date in SNAPSHOT_DATES from one local clone.
	for date in $(SNAPSHOT_DATES); do \
	  $(MAKE) knime-snapshot SNAPSHOT_DATE="$$date" SNAPSHOT_ID="date-$$date" KNIME_OSS_ROOT="$(KNIME_OSS_ROOT)"; \
	done

.PHONY: knime-snapshot-summary
knime-snapshot-summary: ## Build the processed cross-snapshot node summary.
	$(PYTHON) scripts/knime_source/build_knime_node_snapshot_summary.py \
	  "$(KNIME_SNAPSHOT_ROOT)" \
	  --out "$(KNIME_SNAPSHOT_SUMMARY)"

.PHONY: deprecated-node-usage
deprecated-node-usage: ## Build the deprecated-factory registry and exact k2pweb join.
	$(PYTHON) scripts/k2pweb/build_deprecated_node_usage.py \
	  "$(KNIME_SNAPSHOT_ROOT)/$(SNAPSHOT_DATE)/plugin_nodes.csv" \
	  "$(K2PWEB_FACTORIES)" \
	  --registry-out "$(DEPRECATED_FACTORY_REGISTRY)" \
	  --join-audit-out "$(K2PWEB_JOIN_AUDIT)" \
	  --summary-out "$(K2PWEB_USAGE_SUMMARY)" \
	  --observation-start "2026-03-25" \
	  --observation-end "2026-07-15" \
	  --export-date "2026-07-15"

.PHONY: check-json
check-json: ## Validate the source-mining process description.
	$(PYTHON) -m json.tool scripts/knime_source/knime_source_mining_chain.json >/dev/null

.PHONY: test-clone-script
test-clone-script: ## Test automatic clone validation without network access.
	bash scripts/knime_source/test_clone_knime_oss_repos.sh

.PHONY: check
check: check-json test-clone-script knime-snapshot-summary deprecated-node-usage ## Run local validation and rebuild derived source-mining data.
