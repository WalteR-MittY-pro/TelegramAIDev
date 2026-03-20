# TelegramAIDev

用于评估并改进 `CJMP` 的 AI 辅助开发效率，并持续对比 `KMP` 与 `flutter` 在构建 Telegram-like 商业应用 MVP 时的交付效率、质量与摩擦点。

## Goal

这个仓库的目标不是单纯做一个 demo，而是建立一套可重复的 AI delivery 对比方法：

- 用同一组 Telegram-like 产品切片对比 `CJMP`、`KMP`、`flutter`
- 记录真实交付中的效率、质量、工具摩擦和返工成本
- 持续补齐 `CJMP` 的 AI engineering infrastructure
- 给 CJMP 项目工具链提出用户体验改进建议

## Start Here

建议先看这些文件：

1. [AGENTS.md](/Users/haifengsong/code-base/telegram/TelegramAIDev/AGENTS.md)
2. [docs/requirements/telegram-commercial-mvp.md](/Users/haifengsong/code-base/telegram/TelegramAIDev/docs/requirements/telegram-commercial-mvp.md)
3. [docs/design/telegram-commercial-mvp.md](/Users/haifengsong/code-base/telegram/TelegramAIDev/docs/design/telegram-commercial-mvp.md)
4. [docs/acceptance/telegram-commercial-mvp.md](/Users/haifengsong/code-base/telegram/TelegramAIDev/docs/acceptance/telegram-commercial-mvp.md)
5. [reports/ai-infra-needs.md](/Users/haifengsong/code-base/telegram/TelegramAIDev/reports/ai-infra-needs.md)

## Repository Layout

- [docs](/Users/haifengsong/code-base/telegram/TelegramAIDev/docs): requirement、design、acceptance 和各 framework delivery setup
- [reports/comparison](/Users/haifengsong/code-base/telegram/TelegramAIDev/reports/comparison): `CJMP`、`KMP`、`flutter` 的 round 记录与对比总览
- [reports/cjmp-issues](/Users/haifengsong/code-base/telegram/TelegramAIDev/reports/cjmp-issues): `CJMP` 框架或工具链问题
- [.agents/skills](/Users/haifengsong/code-base/telegram/TelegramAIDev/.agents/skills): repo-shared Codex skills
- [.codex](/Users/haifengsong/code-base/telegram/TelegramAIDev/.codex): repo-local Codex config、profiles、roles
- [apps](/Users/haifengsong/code-base/telegram/TelegramAIDev/apps): 各框架应用实现目录

## Current Shared Skills

关键共享技能包括：

- [android-emulator-deploy-run](/Users/haifengsong/code-base/telegram/TelegramAIDev/.agents/skills/android-emulator-deploy-run/SKILL.md): Android emulator/device 的 doctor、devices、boot、deploy、run、uninstall、logs 等生命周期操作
- [android-emulator-acceptance](/Users/haifengsong/code-base/telegram/TelegramAIDev/.agents/skills/android-emulator-acceptance/SKILL.md): Android acceptance 交互，包括 `dump-ui`、`find`、`tap`、`type`、`screenshot`
- [delivery-run-metrics](/Users/haifengsong/code-base/telegram/TelegramAIDev/.agents/skills/delivery-run-metrics/SKILL.md): round 计时与比较记录
- [ai-efficiency-friction-check](/Users/haifengsong/code-base/telegram/TelegramAIDev/.agents/skills/ai-efficiency-friction-check/SKILL.md): 交付轮次后的 friction 归纳

## Notes

- 这个仓库当前重点是 AI engineering infrastructure 和 comparison artifacts.
