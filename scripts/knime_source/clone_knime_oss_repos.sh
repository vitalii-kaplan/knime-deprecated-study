set -euo pipefail

ORG="knime-oss"
API_URL="https://api.github.com/orgs/${ORG}/repos"

usage() {
  printf 'Usage: %s TARGET_DIRECTORY [MANIFEST_CSV]\n' "$(basename "$0")" >&2
  printf 'Clone or update all public %s repositories and validate the result.\n' "$ORG" >&2
  printf 'Default MANIFEST_CSV: TARGET_DIRECTORY/.knime_oss_clone_manifest.csv\n' >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

require_relative_path() {
  case "$2" in
    /*)
      printf 'Error: %s must be relative to the repository root: %s\n' "$1" "$2" >&2
      exit 1
      ;;
  esac
}

remote_matches_expected() {
  remote="$1"
  expected_repo="$2"

  case "$remote" in
    https://github.com/*|http://github.com/*)
      remote_path="${remote#*://github.com/}"
      ;;
    git@github.com:*)
      remote_path="${remote#git@github.com:}"
      ;;
    ssh://git@github.com/*)
      remote_path="${remote#ssh://git@github.com/}"
      ;;
    *)
      return 1
      ;;
  esac

  remote_path="${remote_path%.git}"
  [ "$remote_path" = "${ORG}/${expected_repo}" ]
}

write_manifest_row() {
  jq -Rrn \
    --arg collected_at "$collected_at" \
    --arg organization "$ORG" \
    --arg repo "$1" \
    --arg clone_url "$2" \
    --arg local_path "$3" \
    --arg action "$4" \
    --arg status "$5" \
    --arg origin_url "$6" \
    --arg head_commit "$7" \
    --arg note "$8" \
    '[$collected_at, $organization, $repo, $clone_url, $local_path, $action, $status, $origin_url, $head_commit, $note] | @csv' \
    >> "$manifest_tmp"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 1
fi

require_command curl
require_command date
require_command git
require_command grep
require_command jq
require_command mktemp
require_command sort

target_dir="${1%/}"
manifest="${2:-${target_dir}/.knime_oss_clone_manifest.csv}"
collected_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

require_relative_path "TARGET_DIRECTORY" "$target_dir"
require_relative_path "MANIFEST_CSV" "$manifest"

mkdir -p "$target_dir"
mkdir -p "$(dirname "$manifest")"

work_dir="$(mktemp -d "knime-oss-clone.XXXXXX")"
inventory_unsorted="${work_dir}/inventory-unsorted.tsv"
inventory="${work_dir}/inventory.tsv"
inventory_names="${work_dir}/inventory-names.txt"
manifest_tmp="$(mktemp "${manifest}.tmp.XXXXXX")"

cleanup() {
  rm -rf "$work_dir"
  rm -f "$manifest_tmp"
}
trap cleanup EXIT

export GIT_LFS_SKIP_SMUDGE=1
export GIT_TERMINAL_PROMPT=0

page=1
per_page=100

while :; do
  request_url="${API_URL}?per_page=${per_page}&page=${page}"
  if ! response="$(curl -fsSL "$request_url")"; then
    printf 'Error: GitHub repository discovery failed for page %d.\n' "$page" >&2
    exit 2
  fi
  if ! printf '%s' "$response" | jq -e 'type == "array"' >/dev/null; then
    printf 'Error: GitHub returned a non-array response for page %d.\n' "$page" >&2
    exit 2
  fi

  count="$(printf '%s' "$response" | jq 'length')"
  if [ "$count" -eq 0 ]; then
    break
  fi

  printf '%s' "$response" | jq -r '.[] | [.name, .clone_url] | @tsv' \
    >> "$inventory_unsorted"
  page=$((page + 1))
done

if [ ! -s "$inventory_unsorted" ]; then
  printf 'Error: GitHub discovery returned no public %s repositories.\n' "$ORG" >&2
  exit 2
fi

sort -t $'\t' -k1,1 "$inventory_unsorted" > "$inventory"
cut -f1 "$inventory" > "$inventory_names"

if duplicate_repo="$(sort "$inventory_names" | uniq -d | head -n 1)" && [ -n "$duplicate_repo" ]; then
  printf 'Error: duplicate repository name in discovered inventory: %s\n' "$duplicate_repo" >&2
  exit 2
fi

printf '%s\n' \
  'collected_at,organization,repo,clone_url,local_path,action,status,origin_url,head_commit,note' \
  > "$manifest_tmp"

expected_count=0
verified_count=0
failure_count=0

while IFS=$'\t' read -r name clone_url; do
  expected_count=$((expected_count + 1))
  repo_dir="${target_dir}/${name}"
  action=""
  status="verified"
  origin_url=""
  head_commit=""
  note=""

  if [ -d "$repo_dir/.git" ]; then
    action="updated"
    origin_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
    if ! remote_matches_expected "$origin_url" "$name"; then
      status="invalid_remote"
      note="origin does not identify ${ORG}/${name}"
    elif ! git -C "$repo_dir" fetch --prune origin; then
      status="fetch_failed"
      note="git fetch --prune origin failed"
    fi
  elif [ -e "$repo_dir" ]; then
    action="invalid_existing_path"
    status="not_a_git_worktree"
    note="expected repository path exists without .git"
  else
    action="cloned"
    if ! git clone --filter=blob:none "$clone_url" "$repo_dir"; then
      status="clone_failed"
      note="git clone failed"
    fi
  fi

  if [ "$status" = "verified" ]; then
    origin_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
    if ! remote_matches_expected "$origin_url" "$name"; then
      status="invalid_remote"
      note="origin does not identify ${ORG}/${name}"
    elif [ "$(git -C "$repo_dir" rev-parse --is-inside-work-tree 2>/dev/null || true)" != "true" ]; then
      status="invalid_worktree"
      note="repository is not a Git worktree"
    elif ! head_commit="$(git -C "$repo_dir" rev-parse --verify 'HEAD^{commit}' 2>/dev/null)"; then
      status="missing_head_commit"
      note="HEAD does not resolve to a commit"
    fi
  fi

  if [ "$status" = "verified" ]; then
    verified_count=$((verified_count + 1))
    printf '[verified] %s (%s)\n' "$name" "$action"
  else
    failure_count=$((failure_count + 1))
    printf '[failed] %s: %s\n' "$name" "$status" >&2
  fi

  write_manifest_row \
    "$name" "$clone_url" "$repo_dir" "$action" "$status" \
    "$origin_url" "$head_commit" "$note"
done < "$inventory"

for git_dir in "$target_dir"/*/.git; do
  [ -d "$git_dir" ] || continue
  repo_dir="$(dirname "$git_dir")"
  name="$(basename "$repo_dir")"
  if grep -Fxq "$name" "$inventory_names"; then
    continue
  fi

  origin_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
  head_commit="$(git -C "$repo_dir" rev-parse --verify 'HEAD^{commit}' 2>/dev/null || true)"
  failure_count=$((failure_count + 1))
  printf '[failed] %s: unexpected local repository\n' "$name" >&2
  write_manifest_row \
    "$name" "" "$repo_dir" "none" "unexpected_local_repository" \
    "$origin_url" "$head_commit" "not present in the discovered public organization inventory"
done

mv "$manifest_tmp" "$manifest"

printf 'Expected %d repositories; verified %d; failures %d.\n' \
  "$expected_count" "$verified_count" "$failure_count"
printf 'Manifest: %s\n' "$manifest"

if [ "$failure_count" -ne 0 ] || [ "$verified_count" -ne "$expected_count" ]; then
  exit 3
fi
