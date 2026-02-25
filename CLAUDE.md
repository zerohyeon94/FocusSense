# CLAUDE.md

This file provides guidance to Claude Code when working with the FocusSense repository.

## Project Overview

FocusSense is an iOS study timer app that measures user focus in real-time using the device camera. It uses a **hybrid approach** combining Vision Framework (70%) and CoreML (30%) for drowsiness detection.

### Core Principle
> **"Determine focus by presence + eye state, NOT camera direction"**
>
> Users looking at a monitor while coding should be considered **focused**.
> They don't need to face the phone camera directly.

## Repository Structure

```
FocusSense/
├── iOS/    - SwiftUI iOS app (Swift, Xcode 15+, iOS 17+)
├── ML/     - ML training pipeline (Python, PyTorch → CoreML)
└── Web/    - Landing page (React 19, TypeScript, Vite)
```

Each sub-project has its own `CLAUDE.md` with project-specific guidance.
Read the relevant sub-project `CLAUDE.md` before making changes.

## Git Worktree Workflow

This project uses **git worktrees** to enable parallel development across features.

### Worktree Rules

- **Branch naming**: `feature/<name>`, `fix/<name>`, `docs/<name>`
- **NEVER create branches prefixed with `claude/`** — those are reserved for Claude Code internal sessions and must not be manually created
- Each worktree is an independent working directory; changes are isolated until merged

### Creating a New Worktree

```bash
# Create a new feature branch worktree
git worktree add ../<worktree-name> -b feature/<name>

# List active worktrees
git worktree list

# Remove a worktree after merging
git worktree remove ../<worktree-name>
git branch -d feature/<name>
```

### Worktree Tips

- Work only within your worktree's directory — do not cross-edit other worktrees
- Always branch from `main` or `develop`, never from a `claude/` branch
- PRs should target `develop`; `main` is for releases only

## Branch Strategy

```
main        ← production releases only
develop     ← integration branch (default PR target)
feature/*   ← new features
fix/*       ← bug fixes
docs/*      ← documentation only changes
```

## Commit Style

```
feat: add calibration reset button
fix: correct EAR threshold for low-light conditions
docs: update ML training instructions
refactor: extract eye state logic into helper
```

## General Code Style

- Avoid over-engineering; implement only what is asked
- Do not add comments, docstrings, or type annotations to code you did not change
- Do not add error handling for impossible scenarios
- Follow the existing style of each sub-project (see per-project CLAUDE.md)

## Console Log Conventions (iOS)

- `✅` success, `❌` failure, `⚠️` warning
- `🔄` reset, `👋` return detected, `🚶` away
