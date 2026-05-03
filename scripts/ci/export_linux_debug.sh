#!/usr/bin/env bash
set -euo pipefail

project_dir="${PROJECT_DIR:-$(pwd)}"
godot_bin="${GODOT_BIN:-godot}"
export_preset_name="${EXPORT_PRESET_NAME:-Linux/X11}"
export_path="${LINUX_EXPORT_PATH:-${project_dir}/build/linux/cursed-museum.x86_64}"
created_preset=0

if [[ ! -f "${project_dir}/project.godot" ]]; then
  echo "::notice::project.godot is not present on this branch; Linux export will run after CRSD-001 lands."
  exit 0
fi

mkdir -p "$(dirname "${export_path}")"

if [[ ! -f "${project_dir}/export_presets.cfg" ]]; then
  created_preset=1
  cat > "${project_dir}/export_presets.cfg" <<'PRESET'
[preset.0]

name="Linux/X11"
platform="Linux/X11"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/linux/cursed-museum.x86_64"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_script=1
binary_format/embed_pck=true
texture_format/bptc=true
texture_format/s3tc=true
texture_format/etc=false
texture_format/etc2=false
PRESET
fi

cleanup() {
  if [[ "${created_preset}" -eq 1 ]]; then
    rm -f "${project_dir}/export_presets.cfg"
  fi
}
trap cleanup EXIT

"${godot_bin}" --headless \
  --path "${project_dir}" \
  --export-debug "${export_preset_name}" \
  "${export_path}"

test -s "${export_path}"
