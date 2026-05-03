#!/usr/bin/env bash
set -euo pipefail

godot_version="${GODOT_VERSION:-4.6-stable}"
template_version="${GODOT_TEMPLATE_VERSION:-${godot_version/-/.}}"
install_dir="${GODOT_INSTALL_DIR:-.godot}"
godot_bin="${GODOT_BIN:-${install_dir}/Godot_v${godot_version}_linux.x86_64}"
release_url="https://github.com/godotengine/godot-builds/releases/download/${godot_version}"
tmp_dirs=()

cleanup() {
  for tmp_dir in "${tmp_dirs[@]}"; do
    rm -rf "${tmp_dir}"
  done
}
trap cleanup EXIT

mkdir -p "${install_dir}"

if [[ ! -x "${godot_bin}" ]]; then
  tmp_dir="$(mktemp -d)"
  tmp_dirs+=("${tmp_dir}")

  godot_zip="Godot_v${godot_version}_linux.x86_64.zip"
  curl --fail --location --retry 3 --retry-delay 5 \
    --output "${tmp_dir}/${godot_zip}" \
    "${release_url}/${godot_zip}"
  unzip -q "${tmp_dir}/${godot_zip}" -d "${install_dir}"
  chmod +x "${godot_bin}"
fi

if [[ "${INSTALL_EXPORT_TEMPLATES:-0}" == "1" ]]; then
  template_dir="${HOME}/.local/share/godot/export_templates/${template_version}"
  if [[ ! -f "${template_dir}/linux_debug.x86_64" ]]; then
    tmp_dir="$(mktemp -d)"
    tmp_dirs+=("${tmp_dir}")

    templates_archive="Godot_v${godot_version}_export_templates.tpz"
    curl --fail --location --retry 3 --retry-delay 5 \
      --output "${tmp_dir}/${templates_archive}" \
      "${release_url}/${templates_archive}"
    unzip -q "${tmp_dir}/${templates_archive}" -d "${tmp_dir}"

    mkdir -p "${template_dir}"
    cp -R "${tmp_dir}/templates/." "${template_dir}/"
  fi
fi

"${godot_bin}" --version
