#!/bin/bash
# Setup script for Codex environment
# Installs packages needed for testing build scripts
set -e

# Update package list and install shellcheck for linting
sudo apt-get update
sudo apt-get install -y shellcheck

