---
name: multi-agent-implementation-plan
description: >-
  Splits an implementation plan into work packages and assigns each to a
  parallel Grok 4.7 subagent (code, tests, or docs). Each verified wave updates
  Diátaxis docs in the same change and the orchestrator commits per golden-rule.
  Use when the user wants many Grok agents, a multi-agent implementation,
  parallel subagents, or a plan fanned out across slices.
---

# Multi-agent implementation plan

Split a plan into **work packages** and run one Grok 4.7 agent per package. Packages may implement GDScript, add tests, or (only if asked) write docs. Markdown chapters are optional, not the default.

When speaking to the user, say **Grok 4.7**. Tool slug: `grok-4.7-high-fast`.

Package cards and prompt skeletons: [reference.md](reference.md). Examples: [examples.md](examples.md).

## Workflow

```
- [ ] Clarify: implement-now vs plan-only; what “done” means (usually project smoke + GUT)
- [ ] Lock interfaces (contract): names, signatures, non-goals, package list
- [ ] Do not spawn agents until that lock exists (chat + todos is enough; a file is optional)
- [ ] Wave 1: parallel Tasks only if write paths do not overlap
- [ ] Later waves: dependent packages after the previous wave is verified **and committed**
- [ ] Stitch API/name drift
- [ ] Same-change Diátaxis docs: every engine/ or games/ wave **must** change docs/ or games/<game>/docs/ (hard gate)
- [ ] New behavior → add or update a reference (or how-to) page in the owning tree; inventory-only source-layout is not enough
- [ ] If code landed: godot smoke + GUT for touched tests
- [ ] If engine/ or games/ code changed and no doc did, or verify fails: do not commit
- [ ] If verify passes: orchestrator commits that wave (owned paths + matching docs)
```

## 1. Clarify

Ask at most 1–2 questions that change execution:

- Implement now vs plan-only (no code yet)
- What verifies “done” (default: `godot --path . --headless --quit-after 1` and GUT under `res://tests` for touched areas)

This tree is `engine/` (shared `RefCounted` / `class_name`) and `games/<game>/` (`sim/` + `app/`). Contract: [`docs/explanation/architecture.md`](../../../docs/explanation/architecture.md). Engine docs live in `docs/`, game docs in `games/<game>/docs/`; read [documentation.mdc](../../rules/documentation.mdc) for context paths.

## 2. Contract (orchestrator)

Lock enough that two agents cannot fork the design:

- Type / function names and key signatures
- Non-goals
- Package list: goal, **owned write paths**, forbidden paths, verify command

The contract can stay in the orchestrator prompt and todos. Write a short file only when writers need a shared lock on disk.

**Do not spawn agents until the lock exists.**

## 3. Fan-out

One `Task` per package (`generalPurpose`, `grok-4.7-high-fast`). Prompt from [reference.md](reference.md).

- **Parallel** in one turn only if owned paths are disjoint.
- **Sequential waves** when package B imports types package A must land first (see [examples.md](examples.md)).

Each agent: owned paths only; Headless First for sim/engine; GUT tests for new behavior. Package cards **always** include matching doc owned writes (`docs/` for engine, `games/<game>/docs/` for games). **Agents do not `git commit`** (they would race). The orchestrator commits after stitch.

## 4. Stitch, docs, verify, commit

After each wave:

1. Diff owned paths; fix overlapping edits and signature drift against the contract.
2. Confirm new types have tests where required and stay within the headless boundary.
3. **Same-change docs** (required when `engine/` or `games/` code changed, not only at the end). Always invoke [update-docs](../update-docs/SKILL.md):
   - Update every Diátaxis page whose `related_code` lists a file this wave touched; set `last_reviewed` to today.
   - New/removed source or scene → [`docs/reference/source-layout.md`](../../../docs/reference/source-layout.md).
   - New type, engine feature or game mechanic → update or **add** a reference (or how-to) page in `docs/` or `games/<game>/docs/`; architecture or state-flow changes need a Mermaid diagram. Inventory-only `source-layout.md` is not enough ([documentation.mdc](../../rules/documentation.mdc)).
   - New/removed/retitled doc → [`docs/index.md`](../../../docs/index.md) or `games/<game>/docs/index.md`.
   - **Hard gate:** if `git diff --name-only` lists any `engine/` or `games/` code path and no `docs/` or `games/*/docs/` path, the wave is incomplete. Fix docs. **Do not commit.**
4. If code changed: [run-build-and-tests](../run-build-and-tests/SKILL.md) — smoke + GUT.
5. Append **Locked decisions** to the contract (or todos) so the next wave does not re-fork.
6. **Commit** (orchestrator only):
   - Docs hard gate failed or verify failed → **do not commit**.
   - Verify passed → one git commit for this wave: owned paths + matching docs this wave changed.
   - One logical change; message focuses on **why** (match recent `git log` style).
   - Explicit `git add` paths. Never `git add .`. Never `.godot/`. No secrets. No push.
   - Parallel packages in one wave → **one** commit after stitch.
   - Sequential waves → one commit per wave so the next wave starts from a clean tree.

This skill **is** the user’s request to commit each verified wave. [golden-rule.mdc](../../rules/golden-rule.mdc) §5 overrides waiting for a second “please commit”.

A later docs-only wave is a leftover sweep, not the first time docs are written.
