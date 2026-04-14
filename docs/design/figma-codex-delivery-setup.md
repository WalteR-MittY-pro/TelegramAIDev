# Figma Codex Delivery Setup

## Goal

Set up Figma's MCP server as the shared design-context bridge for Codex in this repo, so design-grounded implementation work can use a real Figma tool surface instead of screenshots or ad hoc copy-paste.

## Project-Scoped Codex Config

This repo now carries a project-scoped Figma MCP entry in `.codex/config.toml`:

```toml
[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
required = false
startup_timeout_sec = 20
```

This keeps the repo-level server definition shared, while leaving authentication outside the repo.

## Authentication

Do not commit personal Figma tokens or user-specific login state into this repository.

Use Codex MCP OAuth login on your own machine:

```bash
codex mcp login figma
```

If the current Codex environment does not surface the project-scoped server automatically during login, add the same server in user config and then authenticate:

```bash
codex mcp add figma --url https://mcp.figma.com/mcp
codex mcp login figma
```

## Repo Design Context

This repo already carries a design-side Figma-oriented source artifact:

- `docs/design/figma-source/index.html`

That file includes the Figma HTML-to-design capture script and serves as the current local design board source for shared Telegram MVP screens and assets.

Use Figma MCP to support:

- inspecting canonical design context when implementing shared UI
- tracing screen, asset, and interaction intent back to design artifacts
- reducing framework-specific design drift across `CJMP`, `KMP`, and `flutter`

## Working Rules

- Keep framework-agnostic design decisions in `docs/design/` and `shared/design/`.
- Do not hardcode personal credentials in repo files.
- Treat Figma MCP as a design-context tool, not as a substitute for the requirement, design, and acceptance contracts already stored in this repo.
- If Figma MCP is unavailable in a delivery round where it would materially help, record that as setup friction instead of silently inventing missing design context.

## Recommended First Check

After authenticating, confirm that Codex can see the server:

```bash
codex mcp list
```

Then start a Codex session in this repo and verify the `figma` MCP server is available alongside any other configured servers.
