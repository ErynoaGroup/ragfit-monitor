set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Standard Erynoa health & readiness check.
doctor: ci-quick

# Fast local CI gate: leak-guard, upstream-base verification, branding & header verification, plugin policy.
ci-quick:
    ./ragfit/scripts/leak-guard.sh
    ./ragfit/scripts/verify-upstream-base.sh HEAD
    ./ragfit/scripts/verify-branding.sh
    ./ragfit/scripts/check-plugins.sh

# Build lightweight OCI container image via Nix dockerTools.buildLayeredImage.
image:
    nix build .#container

# Alias for container image build.
build-image: image
