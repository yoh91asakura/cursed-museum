#!/usr/bin/env bash
set -euo pipefail

project_dir="${PROJECT_DIR:-$(pwd)}"
godot_bin="${GODOT_BIN:-godot}"
gdunit_runner="${project_dir}/addons/gdUnit4/bin/gdUnit4.gd"

if [[ ! -f "${project_dir}/project.godot" ]]; then
  echo "::notice::project.godot is not present on this branch; gdUnit4 will run after CRSD-001 lands."
  exit 0
fi

if [[ ! -f "${gdunit_runner}" ]]; then
  echo "::notice::gdUnit4 addon is not present; skipping until addons/gdUnit4 is committed."
  exit 0
fi

"${godot_bin}" --headless \
  --path "${project_dir}" \
  --script addons/gdUnit4/bin/gdUnit4.gd \
  --add-only res://tests
