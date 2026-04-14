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

- `reports/cjmp-issues/`: issues reporting to CJMP project to facilitate ease of use for AI engineering
- `reports/comparison/`: cross-framework comparison notes, efficiency findings, and parity-oriented analysis
- `.agents`/`.codex`/`.rules`/... : AI engineering infrastructure
- `apps`: apps developed with `CJMP`,`KMP`,`flutter`

### Non-artifact Locations

- `docs`: Development process artifacts, requirements->acceptance/design

## Shared Invariants

- Use GitHub issues to drive the project.
- Keep framework-agnostic product and UI designs separate from framework specific implementation details.

- Support application developers using CJMP.
- When Cangjie syntax documentation is needed, use Context7 to search the `hypheng/cjmp-ai-docs` repository, or use the local `cangjie-docs-navigator` skill.
- When CJMP-related content is needed, use Context7 to retrieve documentation from the `cjmp/zh-cn` directory in the `hypheng/cjmp-ai-docs` repository.