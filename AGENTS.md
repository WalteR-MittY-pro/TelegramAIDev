# Project Agent Rules

## Mission

This repo exists to improve `CJMP` AI-assisted development efficiency, with the goal of outperforming typical `KMP` and `flutter` workflows for building a Telegram-like commercial application.
The project should keep comparing those approaches on comparable slices, expose where `CJMP` falls short for AI-assisted delivery, and continuously improve the AI engineering layer around `CJMP`.

## Constraints

- A valid evaluation of AI-assisted development efficiency requires a professional product bar and a user experience close to Telegram for common flows.
- Do not let implementation cost explode.
- Do not plan features or functions unless they help expose, compare, or solve meaningful AI-efficiency problems.
- Do not over-polish beyond what is needed to support a credible Telegram-like commercial demo.

## Delivery Targets

- iterative improvement of the `CJMP` AI engineering layer
- accumulated comparison reports against `KMP` and `flutter`
- an accumulated issue list for `CJMP` framework and tooling problems
- a client-facing demo app representing the most Telegram-like viable version

### Artifact Locations

- `reports/cjmp-isses/`: issues reporting to CJMP project to facilitate ease of use for AI engineering
- `reports/comparison/`: cross-framework comparison notes, efficiency findings, and parity-oriented analysis
- `.agents`/`.codex`/`.rules`/... : AI engineering infrastructure
- `apps`: apps developed with `CJMP`,`KMP`,`flutter`

### Non-artifact Locations

- `docs`: Development progress artifacts, requirements->acceptance/design

## Shared Invariants

- Use GitHub issues to drive the project.
- Use local skills, mcp ... even if there are global ones, just to keep track and deliver them in the end.
- Keep framework-agnostic product and UI decisions separate from implementation details.

## Shared Workflow

1. Requirements
   - Write or update the requirement artifact first.
2. Acceptance And Design
   - Define acceptance scenarios and framework-agnostic design before implementation.
3. `requirement` GitHub Issues
   - Convert approved requirement slices into GitHub issues with the `requirement` tag.
   - These issues are the source of truth for implementation work.
4. Implementer Development
   - The Implementer develops the same slice for all three framework versions: `CJMP`, `KMP`, and `flutter`.
   - Delivery should stay comparable across the three implementations.
5. PR, Comparison, And CJMP Inefficiency Capture
   - Record comparison data such as time and token usage.
   - Write comparison results back to `reports/comparison/`.
   - If `CJMP` shows confirmed AI-efficiency friction or tooling inefficiency, create follow-up in `reports/cjmp-issues/`.
   - Open the delivery PR in the end.
6. Review
   - Review the PR only for serious problems or issues with clear user impact.
   - Focus on user experience, performance, security and privacy, test effectiveness, maintainability, and platform-specific risks.
7. Merge
   - Merge only after review passes and required comparison / inefficiency artifacts are written back.
