# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

**devenv-4-iom** is a pure Bash toolkit for managing Kubernetes-based development environments for IOM (Intershop Order Management). It generates Kubernetes manifests from templates and orchestrates them via `kubectl` and `docker`. There is no build system — no Maven, Gradle, or npm.

## Key Files

- `bin/devenv-cli.sh` — Main CLI entrypoint (~4000 lines), handles all commands
- `bin/template_engine.sh` — Renders `.yml.template` files by substituting variables
- `bin/template-variables` — Default values for all template variables
- `templates/` — Kubernetes manifest templates (`iom.yml`, `postgres.yml`, `mailsrv.yml`, etc.)
- `doc/` — Comprehensive user documentation (read these before making changes)

## CLI Usage

```bash
bin/devenv-cli.sh [CONFIG-FILE] COMMAND [SUBCOMMAND] [ARGS]
```

Core commands: `get`, `info`, `create`, `delete`, `apply`, `dump`, `log`

Examples:
```bash
bin/devenv-cli.sh get config
bin/devenv-cli.sh create cluster
bin/devenv-cli.sh apply deployment
bin/devenv-cli.sh log iom -f
```

## Configuration System

Two-tier config (never commit user files):
- `devenv.project.properties` — version-controlled project defaults
- `devenv.user.properties` — local overrides (gitignored)

Template variables are defined with defaults in `bin/template-variables`. The template engine substitutes these into `templates/*.template` files when generating Kubernetes manifests.

## Architecture

```
User command → devenv-cli.sh
  → load project + user .properties files
  → merge with defaults from bin/template-variables
  → template_engine.sh expands *.yml.template → rendered YAML
  → kubectl/docker commands execute against the cluster
```

Kubernetes resources created per IOM instance: namespace, postgres pod, mailpit pod, IOM deployment (single container + dbaccount init container), and services.

## Testing

Unit tests (`test/run-unit-tests.sh`) verify template rendering without a cluster. Integration tests (`test/run-integration-tests.sh`) require a live Kubernetes cluster — Rancher Desktop is the primary supported platform. See `test/README.md` for setup instructions.

## External Dependencies

The scripts require these tools to be installed: `bash`, `kubectl`, `docker`, `jq`, `git`.

## Release Branches

- `main` — stable releases
- `develop` — integration branch
- Feature branches: `chore/`, `feat/`, `fix/` prefixes
