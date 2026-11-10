#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Builds the Hugo site for Cloudflare Workers.
# Based on https://gohugo.io/host-and-deploy/deploy-to-cloudflare/
#------------------------------------------------------------------------------

# Exit on error, undefined variables, or pipe failures.
set -euo pipefail

# Pin the Hugo version used by the site.
HUGO_VERSION=0.169.0

# Set the build time zone (matches the content's +05:45 timezone).
TZ=Asia/Kathmandu

# Use the cache directory that Cloudflare preserves between builds.
HUGO_CACHEDIR="${PWD}/.cache/hugo"

cleanup() {
  if [[ -n "${build_temp_dir:-}" && -d "${build_temp_dir}" ]]; then
    rm -rf "${build_temp_dir}"
  fi
}

trap cleanup EXIT SIGINT SIGTERM

main() {
  export TZ
  export HUGO_CACHEDIR

  # Create a temporary directory for downloads.
  build_temp_dir=$(mktemp -d)

  # Install Hugo.
  echo "Installing Hugo ${HUGO_VERSION}..."
  mkdir -p "${HOME}/.local/hugo"
  curl -sfL --output-dir "${build_temp_dir}" -O \
    "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz"
  tar -C "${HOME}/.local/hugo" -xf "${build_temp_dir}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz"
  export PATH="${HOME}/.local/hugo:${PATH}"

  echo "Hugo: $(hugo version)"

  # Configure Git.
  echo "Configuring Git..."
  git config --global core.quotepath false

  # Fetch full Git history if the checkout is shallow.
  if [[ $(git rev-parse --is-shallow-repository) == true ]]; then
    echo "Fetching full Git history..."
    git fetch --unshallow
  fi

  # The Whiteplain theme is a Git submodule.
  if [[ -f .gitmodules ]]; then
    echo "Initializing Git submodules..."
    git submodule update --init --recursive
  fi

  # Build the project.
  echo "Building the project..."
  HUGO_ARGS=(--gc --minify --cleanDestinationDir)
  if [[ -n "${BASE_URL:-}" ]]; then
    echo "Using BASE_URL=${BASE_URL}"
    HUGO_ARGS+=(--baseURL "${BASE_URL}")
  fi
  hugo build "${HUGO_ARGS[@]}"
}

main "$@"
