set -euo pipefail

clone_script="scripts/knime_source/clone_knime_oss_repos.sh"
test_root="$(mktemp -d "test-knime-clone.XXXXXX")"
target="${test_root}/target"
manifest="${test_root}/manifest.csv"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

curl() {
  case "$*" in
    *"&page=1"*)
      printf '%s\n' '[{"name":"alpha","clone_url":"https://github.com/knime-oss/alpha.git"},{"name":"beta","clone_url":"https://github.com/knime-oss/beta.git"}]'
      ;;
    *)
      printf '%s\n' '[]'
      ;;
  esac
}

git() {
  if [ "$1" = "clone" ]; then
    url="$3"
    destination="$4"
    mkdir -p "$destination/.git"
    printf '%s\n' "$url" > "$destination/.git/mock-origin"
    printf '%s\n' '0123456789abcdef0123456789abcdef01234567' \
      > "$destination/.git/mock-head"
    return 0
  fi

  if [ "$1" = "-C" ]; then
    repo="$2"
    shift 2
    case "$1 $2" in
      "remote get-url")
        command cat "$repo/.git/mock-origin"
        ;;
      "fetch --prune")
        return 0
        ;;
      "rev-parse --is-inside-work-tree")
        printf '%s\n' true
        ;;
      "rev-parse --verify")
        command cat "$repo/.git/mock-head"
        ;;
      *)
        printf 'Unsupported mock git call: %s\n' "$*" >&2
        return 2
        ;;
    esac
    return 0
  fi

  printf 'Unsupported mock git call: %s\n' "$*" >&2
  return 2
}

export -f curl
export -f git

bash "$clone_script" "$target" "$manifest" >/dev/null

if [ "$(grep -c ',"cloned","verified",' "$manifest")" -ne 2 ]; then
  printf 'Expected two verified clone rows.\n' >&2
  exit 1
fi

bash "$clone_script" "$target" "$manifest" >/dev/null

if [ "$(grep -c ',"updated","verified",' "$manifest")" -ne 2 ]; then
  printf 'Expected two verified update rows.\n' >&2
  exit 1
fi

mkdir -p "$target/unexpected/.git"
printf '%s\n' 'https://github.com/knime-oss/unexpected.git' \
  > "$target/unexpected/.git/mock-origin"
printf '%s\n' 'fedcba9876543210fedcba9876543210fedcba98' \
  > "$target/unexpected/.git/mock-head"

if bash "$clone_script" "$target" "$manifest" >/dev/null 2>&1; then
  printf 'Expected an unexpected repository to fail validation.\n' >&2
  exit 1
fi

if ! grep -q '"unexpected_local_repository"' "$manifest"; then
  printf 'Expected the unexpected repository failure in the manifest.\n' >&2
  exit 1
fi

printf 'clone script integration test passed\n'
