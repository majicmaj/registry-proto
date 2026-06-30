#!/usr/bin/env bash
#
# Scenario tests for buf.registry.search.v1beta1. Each fixture is validated against the
# compiled schema with `buf convert`: usecases/ must parse, negative/ must be rejected.
# Round-tripping to JSON doubles as documentation. See tests/README.md for scope.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Locate buf, preferring the repo-vendored binary.
if [[ -x ".tmp/bin/buf" ]]; then
  BUF=".tmp/bin/buf"
elif command -v buf >/dev/null 2>&1; then
  BUF="buf"
else
  echo "error: buf not found. Run 'make build', or put buf v1.70.0 on PATH." >&2
  exit 2
fi

PKG="buf.registry.search.v1beta1"
IMG="$(mktemp -t buf-search-image.XXXXXX)"
EMPTY="$(mktemp -t buf-search-empty.XXXXXX)"
trap 'rm -f "$IMG" "$EMPTY"' EXIT
"$BUF" build -o "$IMG#format=binpb" || { echo "error: buf build failed" >&2; exit 2; }

# The message type for a fixture is its filename up to the first '.', e.g.
# SearchSymbolsRequest.txtpb -> buf.registry.search.v1beta1.SearchSymbolsRequest
type_of() { local b; b="$(basename "$1")"; echo "$PKG.${b%%.*}"; }
header()  { grep -m1 '^# ' "$1" | sed 's/^# //'; }
# A fixture only exercises the schema if its type exists in the image; converting empty
# input succeeds for any real type and fails for a typo'd filename.
type_exists() { "$BUF" convert "$IMG#format=binpb" --type="$1" --from="$EMPTY#format=txtpb" --to="-#format=json" >/dev/null 2>&1; }

for d in tests/usecases tests/negative; do
  if [[ -z "$(find "$d" -name '*.txtpb' -print -quit)" ]]; then
    echo "error: no fixtures found in $d" >&2
    exit 2
  fi
done

pass=0
fail=0

echo "=== POSITIVE: every use case is a valid instance of the schema ==="
while IFS= read -r f; do
  t="$(type_of "$f")"
  out="$("$BUF" convert "$IMG#format=binpb" --type="$t" --from="$f#format=txtpb" --to="-#format=json" 2>&1)"
  rc=$?
  if [[ $rc -eq 0 && -n "$out" && "$out" != "{}" ]]; then
    pass=$((pass + 1))
    printf '\nPASS  %s\n' "$(header "$f")"
    printf '  type:  %s\n' "${t#"$PKG".}"
    printf '  wire:  %s\n' "$out"
  else
    fail=$((fail + 1))
    printf '\nFAIL  %s\n  type: %s\n  err:  %s\n' "$f" "$t" "$out"
  fi
done < <(find tests/usecases -name '*.txtpb' | sort)

echo
echo "=== NEGATIVE: malformed requests must be rejected ==="
while IFS= read -r f; do
  t="$(type_of "$f")"
  if ! type_exists "$t"; then
    fail=$((fail + 1))
    printf '\nFAIL  unknown type %s (check the fixture filename): %s\n' "$t" "$f"
    continue
  fi
  out="$("$BUF" convert "$IMG#format=binpb" --type="$t" --from="$f#format=txtpb" --to="-#format=json" 2>&1)"
  if [[ $? -ne 0 ]]; then
    pass=$((pass + 1))
    printf '\nPASS  rejected: %s\n  why:   %s\n' "$(header "$f")" "$(echo "$out" | tail -1)"
  else
    fail=$((fail + 1))
    printf '\nFAIL  should have been rejected: %s\n' "$f"
  fi
done < <(find tests/negative -name '*.txtpb' | sort)

echo
echo "================================================"
echo "  passed: $pass   failed: $fail"
if [[ $fail -eq 0 ]]; then echo "  ALL GREEN"; exit 0; else echo "  FAILURES"; exit 1; fi
