# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository stores **converted Ansible playbooks** — the output of a PowerShell-to-Ansible conversion pipeline. Source PowerShell scripts live in `PS-Scripts/`, and converted playbooks are committed to `playbooks/` via pull requests.

The conversion pipeline is driven by Claude Code agents defined in `.claude/agents/`:

- **Orchestrator** (`orchestrator.md`) — end-to-end pipeline coordinator. Runs the Conversion Agent, then the AAP Runner, then updates the PR with test results. Strictly sequential with user gates between phases.
- **Conversion Agent** (`subagent-1-conversion-source-control.md`) — reads a `.ps1` file, converts it to an Ansible playbook, commits to a new branch, and opens a PR via GitHub MCP tools.
- **AAP Playbook Runner** (`aap-playbook-runner.md`) — creates an AAP Project + Job Template, runs the playbook against a test inventory, and reports results. Uses the AAP MCP server.

## Repository Structure

- `PS-Scripts/` — source PowerShell scripts (standalone and `xy-PS-scripts/` with versioned Windows Server datacenter provisioning scripts for 2019/2022/2025)
- `playbooks/` — converted Ansible playbooks (created by the conversion pipeline)
- `.claude/agents/` — agent definitions for the conversion pipeline
- `.claude/commands/dev.md` — `/dev` structured development workflow skill
- `.dev-plans/` — planning/implementation docs created by the `/dev` skill (gitignored)

## Agent Pipeline Flow

```
Orchestrator
  → Phase 1: Conversion Agent (branch → read PS1 → convert → commit → PR)
  → Gate: user confirms PR
  → Phase 2: AAP Runner (create project → sync → create template → launch job → poll results)
  → Gate: user reviews results
  → Update PR with execution results
```

All AAP API ID fields (credential, inventory, project, organization, execution_environment) must be passed as **numbers, not strings**.

## Conversion Rules

When converting PowerShell to Ansible:
- Use proper Ansible modules over `win_shell`/`win_command` calls where possible
- Every task must have a `name`
- Use `hosts: all`, `gather_facts: true`, `become` if needed
- 2-space YAML indentation
- Variables for environment-specific values
- Playbook output path: `playbooks/{scriptname}.yml`

## MCP Tools

This repo relies on the **GitHub MCP server** (`git-mcp-raghav-local`) for Git operations (branching, file reads, commits, PRs) and the **AAP MCP server** for Ansible Automation Platform operations (projects, job templates, job execution).
