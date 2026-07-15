"""Build a deprecated-factory registry and exact k2pweb usage join."""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path


REGISTRY_FIELDS = [
    "snapshot_id",
    "snapshot_date",
    "factory_class",
    "registration_count",
    "deprecated_registration_count",
    "hidden_registration_count",
    "repositories",
    "plugin_xml_files",
    "category_paths",
]

JOIN_FIELDS = [
    "factory_class",
    "join_status",
    "node_occurrence_count",
    "workflow_count",
]

SUMMARY_FIELDS = [
    "observation_start",
    "observation_end",
    "export_date",
    "classification_snapshot_id",
    "classification_snapshot_date",
    "deprecated_registration_count",
    "deprecated_registry_factory_count",
    "deprecated_factory_with_multiple_registrations_count",
    "workflow_count",
    "node_occurrence_count",
    "distinct_factory_count",
    "exact_match_occurrence_count",
    "exact_match_occurrence_percent",
    "exact_match_factory_count",
    "exact_match_factory_percent",
    "unmatched_occurrence_count",
    "unmatched_factory_count",
    "deprecated_workflow_count",
    "deprecated_workflow_percent",
    "deprecated_node_occurrence_count",
    "deprecated_node_occurrence_percent",
    "distinct_deprecated_factory_count",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def require_fields(path: Path, rows: list[dict[str, str]], fields: set[str]) -> None:
    actual = set(rows[0]) if rows else set()
    missing = fields - actual
    if missing:
        raise ValueError(f"{path} is missing columns: {', '.join(sorted(missing))}")


def bool_value(value: str) -> bool:
    return value.strip().lower() == "true"


def pct(part: int, whole: int) -> str:
    return "0.00" if whole == 0 else f"{part / whole * 100:.2f}"


def joined(values: set[str]) -> str:
    return "|".join(sorted(value for value in values if value))


def relative_path(parser: argparse.ArgumentParser, name: str, path: Path) -> None:
    if path.is_absolute():
        parser.error(f"{name} must be relative to the repository root")


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Build a unique deprecated ordinary-node factory registry for one "
            "KNIME snapshot and join k2pweb factory occurrences exactly."
        )
    )
    parser.add_argument("plugin_nodes", type=Path)
    parser.add_argument("k2pweb_factories", type=Path)
    parser.add_argument("--registry-out", required=True, type=Path)
    parser.add_argument("--join-audit-out", required=True, type=Path)
    parser.add_argument("--summary-out", required=True, type=Path)
    parser.add_argument("--observation-start", required=True)
    parser.add_argument("--observation-end", required=True)
    parser.add_argument("--export-date", required=True)
    args = parser.parse_args()

    for name in (
        "plugin_nodes",
        "k2pweb_factories",
        "registry_out",
        "join_audit_out",
        "summary_out",
    ):
        relative_path(parser, name, getattr(args, name))

    plugin_rows = read_csv(args.plugin_nodes)
    usage_rows = read_csv(args.k2pweb_factories)
    require_fields(
        args.plugin_nodes,
        plugin_rows,
        {
            "snapshot_id",
            "snapshot_date",
            "repo",
            "plugin_xml",
            "element",
            "factory_class",
            "category_path",
            "deprecated",
            "hidden",
        },
    )
    require_fields(args.k2pweb_factories, usage_rows, {"index", "factory"})

    snapshot_ids = {row["snapshot_id"] for row in plugin_rows}
    snapshot_dates = {row["snapshot_date"] for row in plugin_rows}
    if len(snapshot_ids) != 1 or len(snapshot_dates) != 1:
        raise ValueError("plugin_nodes input must contain exactly one snapshot")
    snapshot_id = next(iter(snapshot_ids))
    snapshot_date = next(iter(snapshot_dates))

    registrations: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in plugin_rows:
        factory = row["factory_class"].strip()
        if row["element"] == "node" and factory:
            registrations[factory].append(row)

    deprecated_factories = {
        factory
        for factory, rows in registrations.items()
        if any(bool_value(row["deprecated"]) for row in rows)
    }
    registry_rows: list[dict[str, object]] = []
    for factory in sorted(deprecated_factories):
        rows = registrations[factory]
        registry_rows.append(
            {
                "snapshot_id": snapshot_id,
                "snapshot_date": snapshot_date,
                "factory_class": factory,
                "registration_count": len(rows),
                "deprecated_registration_count": sum(
                    bool_value(row["deprecated"]) for row in rows
                ),
                "hidden_registration_count": sum(
                    bool_value(row["hidden"]) for row in rows
                ),
                "repositories": joined({row["repo"] for row in rows}),
                "plugin_xml_files": joined({row["plugin_xml"] for row in rows}),
                "category_paths": joined({row["category_path"] for row in rows}),
            }
        )

    workflows_by_factory: dict[str, set[str]] = defaultdict(set)
    occurrences_by_factory: dict[str, int] = defaultdict(int)
    factories_by_workflow: dict[str, list[str]] = defaultdict(list)
    for row in usage_rows:
        workflow = row["index"].strip()
        factory = row["factory"].strip()
        if not workflow or not factory:
            raise ValueError("k2pweb input contains a blank index or factory")
        workflows_by_factory[factory].add(workflow)
        occurrences_by_factory[factory] += 1
        factories_by_workflow[workflow].append(factory)

    join_rows: list[dict[str, object]] = []
    for factory in sorted(occurrences_by_factory):
        if factory in deprecated_factories:
            status = "exact_deprecated"
        elif factory in registrations:
            status = "exact_not_deprecated"
        else:
            status = "not_found"
        join_rows.append(
            {
                "factory_class": factory,
                "join_status": status,
                "node_occurrence_count": occurrences_by_factory[factory],
                "workflow_count": len(workflows_by_factory[factory]),
            }
        )

    exact_factories = set(occurrences_by_factory) & set(registrations)
    unmatched_factories = set(occurrences_by_factory) - set(registrations)
    deprecated_occurrences = sum(
        count
        for factory, count in occurrences_by_factory.items()
        if factory in deprecated_factories
    )
    exact_occurrences = sum(
        count
        for factory, count in occurrences_by_factory.items()
        if factory in registrations
    )
    deprecated_workflows = sum(
        any(factory in deprecated_factories for factory in factories)
        for factories in factories_by_workflow.values()
    )
    summary_rows: list[dict[str, object]] = [
        {
            "observation_start": args.observation_start,
            "observation_end": args.observation_end,
            "export_date": args.export_date,
            "classification_snapshot_id": snapshot_id,
            "classification_snapshot_date": snapshot_date,
            "deprecated_registration_count": sum(
                int(row["deprecated_registration_count"]) for row in registry_rows
            ),
            "deprecated_registry_factory_count": len(registry_rows),
            "deprecated_factory_with_multiple_registrations_count": sum(
                int(row["deprecated_registration_count"]) > 1
                for row in registry_rows
            ),
            "workflow_count": len(factories_by_workflow),
            "node_occurrence_count": len(usage_rows),
            "distinct_factory_count": len(occurrences_by_factory),
            "exact_match_occurrence_count": exact_occurrences,
            "exact_match_occurrence_percent": pct(exact_occurrences, len(usage_rows)),
            "exact_match_factory_count": len(exact_factories),
            "exact_match_factory_percent": pct(
                len(exact_factories), len(occurrences_by_factory)
            ),
            "unmatched_occurrence_count": sum(
                occurrences_by_factory[factory] for factory in unmatched_factories
            ),
            "unmatched_factory_count": len(unmatched_factories),
            "deprecated_workflow_count": deprecated_workflows,
            "deprecated_workflow_percent": pct(
                deprecated_workflows, len(factories_by_workflow)
            ),
            "deprecated_node_occurrence_count": deprecated_occurrences,
            "deprecated_node_occurrence_percent": pct(
                deprecated_occurrences, len(usage_rows)
            ),
            "distinct_deprecated_factory_count": len(
                set(occurrences_by_factory) & deprecated_factories
            ),
        }
    ]

    write_csv(args.registry_out, REGISTRY_FIELDS, registry_rows)
    write_csv(args.join_audit_out, JOIN_FIELDS, join_rows)
    write_csv(args.summary_out, SUMMARY_FIELDS, summary_rows)
    print(f"wrote\t{args.registry_out}")
    print(f"deprecated_factories\t{len(registry_rows)}")
    print(f"wrote\t{args.join_audit_out}")
    print(f"observed_factories\t{len(join_rows)}")
    print(f"wrote\t{args.summary_out}")
    print(f"workflows\t{len(factories_by_workflow)}")
    print(f"node_occurrences\t{len(usage_rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
