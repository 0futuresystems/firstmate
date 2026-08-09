#!/usr/bin/env bash
# Tests for the Pi primary launcher that keeps project cwd and loads extensions.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT=$(fm_test_tmproot fm-pi-launch)

make_fake_pi() {
  local dir=$1 name=$2 log=$3
  cat > "$dir/$name" <<'SH'
#!/usr/bin/env bash
printf 'cwd=%s\nharness=%s\n' "$PWD" "${FM_PI_HARNESS:-}" > "$FM_PI_LAUNCH_LOG"
for arg in "$@"; do printf 'arg=%s\n' "$arg" >> "$FM_PI_LAUNCH_LOG"; done
SH
  chmod +x "$dir/$name"
}

test_launcher_loads_absolute_extensions_from_child_cwd() {
  local fake child log out watch_line guard_line
  fake="$TMP_ROOT/plain-bin"
  child="$TMP_ROOT/child-project"
  log="$TMP_ROOT/plain.log"
  mkdir -p "$fake" "$child"
  make_fake_pi "$fake" pi "$log"
  out=$(cd "$child" && PATH="$fake:$PATH" FM_PI_LAUNCH_LOG="$log" FM_ROOT_OVERRIDE="$ROOT" "$ROOT/bin/fm-pi.sh" --model test hello)
  [ -z "$out" ] || fail "Pi launcher printed output: $out"
  assert_contains "$(cat "$log")" "cwd=$child" "Pi launcher changed the project cwd"
  assert_contains "$(cat "$log")" 'harness=pi' "Pi launcher did not retain the plain Pi identity"
  assert_contains "$(cat "$log")" 'arg=--no-extensions' "Pi launcher did not disable cwd-dependent extension discovery"
  assert_contains "$(cat "$log")" "arg=$ROOT/.pi/extensions/fm-calm.ts" "Pi launcher omitted the absolute Calm extension"
  assert_contains "$(cat "$log")" "arg=$ROOT/.pi/extensions/fm-primary-turnend-guard.ts" "Pi launcher omitted the absolute turn-end extension"
  assert_contains "$(cat "$log")" "arg=$ROOT/.pi/extensions/fm-primary-pi-watch.ts" "Pi launcher omitted the absolute watcher extension"
  watch_line=$(grep -nF "arg=$ROOT/.pi/extensions/fm-primary-pi-watch.ts" "$log" | cut -d: -f1)
  guard_line=$(grep -nF "arg=$ROOT/.pi/extensions/fm-primary-turnend-guard.ts" "$log" | cut -d: -f1)
  [ "$watch_line" -lt "$guard_line" ] || fail "Pi launcher loaded the turn-end guard before watcher establishment"
  assert_contains "$(cat "$log")" 'arg=hello' "Pi launcher did not preserve user arguments"
  pass "Pi launcher loads absolute primary extensions without changing child project cwd"
}

test_launcher_preserves_signed_identity_and_rejects_unknown_harnesses() {
  local fake log out status
  fake="$TMP_ROOT/signed-bin"
  log="$TMP_ROOT/signed.log"
  mkdir -p "$fake"
  make_fake_pi "$fake" pi-signed "$log"
  out=$(PATH="$fake:$PATH" FM_PI_LAUNCH_LOG="$log" FM_ROOT_OVERRIDE="$ROOT" FM_PI_HARNESS=pi-signed "$ROOT/bin/fm-pi.sh" --thinking high)
  [ -z "$out" ] || fail "signed Pi launcher printed output: $out"
  assert_contains "$(cat "$log")" 'harness=pi-signed' "Pi launcher did not retain the signed identity"
  status=0
  out=$(FM_PI_HARNESS=invalid "$ROOT/bin/fm-pi.sh" 2>&1) || status=$?
  expect_code 2 "$status" "Pi launcher unknown harness refusal"
  assert_contains "$out" 'FM_PI_HARNESS must be pi or pi-signed' "Pi launcher did not explain its harness refusal"
  pass "Pi launcher preserves pi-signed and fails closed for an unknown harness"
}

test_launcher_loads_absolute_extensions_from_child_cwd
test_launcher_preserves_signed_identity_and_rejects_unknown_harnesses
