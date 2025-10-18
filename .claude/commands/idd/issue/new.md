---
# Claude Code 必須要素
allowed-tools:
  Bash(
    ls:*, basename:*, sed:*, jq:*, echo:*, cat:*, stat:*,
    source:*, xargs:*, head:*, git:*
  ),
  Read(*),
  mcp__serena-mcp__*,
  mcp__lsmcp__*
argument-hint: <title>(optional)
description: 新しくIssueを作成する

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  libs_dir: .claude/commands/_libs

# ag-logger プロジェクト要素
title: /idd:issue:new
version: 1.0.0
created: 2025-10-16
authors:
  - atsushifx
changes:
  - 2025-10-16: 初版作成 - Issue一覧表示とセッション準備機能を実装
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

---

## See Also

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
