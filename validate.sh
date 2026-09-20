#!/usr/bin/env bash
# Lints the chart, then renders it for each environment and checks the
# output against the Kubernetes schema. Downloads pinned releases of helm
# and kubeconform into a local cache if they aren't already on PATH.
set -euo pipefail

KUBE_VERSION="1.29.0"
ENVIRONMENTS=(dev prod)

HELM_VERSION="4.3.0"
HELM_SHA256="86584a54def73570558f66f5111cc53dfed56689637ae32c1201205d494f54fb"
HELM_CACHE_DIR="${HOME}/.cache/helm-${HELM_VERSION}"
HELM_BIN="${HELM_CACHE_DIR}/linux-amd64/helm"

KUBECONFORM_VERSION="0.6.7"
KUBECONFORM_SHA256="95f14e87aa28c09d5941f11bd024c1d02fdc0303ccaa23f61cef67bc92619d73"
KUBECONFORM_CACHE_DIR="${HOME}/.cache/kubeconform-${KUBECONFORM_VERSION}"
KUBECONFORM_BIN="${KUBECONFORM_CACHE_DIR}/kubeconform"

if ! command -v helm >/dev/null 2>&1 && [ ! -x "${HELM_BIN}" ]; then
  mkdir -p "${HELM_CACHE_DIR}"
  archive="$(mktemp)"
  curl -fsSL -o "${archive}" \
    "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
  echo "${HELM_SHA256}  ${archive}" | sha256sum -c -
  tar -xzf "${archive}" -C "${HELM_CACHE_DIR}"
  rm -f "${archive}"
fi

if ! command -v kubeconform >/dev/null 2>&1 && [ ! -x "${KUBECONFORM_BIN}" ]; then
  mkdir -p "${KUBECONFORM_CACHE_DIR}"
  archive="$(mktemp)"
  curl -fsSL -o "${archive}" \
    "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz"
  echo "${KUBECONFORM_SHA256}  ${archive}" | sha256sum -c -
  tar -xzf "${archive}" -C "${KUBECONFORM_CACHE_DIR}" kubeconform
  rm -f "${archive}"
fi

HELM="$(command -v helm || echo "${HELM_BIN}")"
KUBECONFORM="$(command -v kubeconform || echo "${KUBECONFORM_BIN}")"

echo "==> helm lint (base values)"
"${HELM}" lint .

for env in "${ENVIRONMENTS[@]}"; do
  echo "==> helm lint (values-${env}.yaml)"
  "${HELM}" lint . -f values.yaml -f "values-${env}.yaml"

  echo "==> kubeconform (values-${env}.yaml)"
  "${HELM}" template echo-web . -f values.yaml -f "values-${env}.yaml" \
    | "${KUBECONFORM}" -strict -summary -kubernetes-version "$KUBE_VERSION" -
done

echo "==> all checks passed"
