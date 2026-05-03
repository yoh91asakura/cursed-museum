#!/usr/bin/env bash
set -euo pipefail

project_dir="${PROJECT_DIR:-$(pwd)}"
cd "${project_dir}"

mapfile -d '' gdscript_files < <(
  find . \
    \( -path './.git' -o -path './.godot' -o -path './build' -o -path './exports' \) -prune \
    -o -name '*.gd' -print0
)

if [[ "${#gdscript_files[@]}" -eq 0 ]]; then
  echo "::notice::No GDScript files found; lint job has nothing to check yet."
  exit 0
fi

gdformat --check "${gdscript_files[@]}"
gdlint "${gdscript_files[@]}"
