#!/usr/bin/env bash
# Local quality gate — the same checks CI runs, in the same order.
# Fails fast on the first broken step. Works in Git Bash on Windows and on
# macOS/Linux. Usage: tool/verify.sh
set -euo pipefail

cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step 'flutter pub get'
flutter pub get

step 'dart format (check only)'
dart format --output=none --set-exit-if-changed .

step 'flutter analyze'
flutter analyze --fatal-infos --fatal-warnings

step 'flutter test --coverage'
flutter test --coverage

printf '\nAll checks passed.\n'
