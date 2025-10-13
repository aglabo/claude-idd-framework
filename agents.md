---
header:
  - src: agents.md
  - "@(#)": CLAUDEエージェント運用ガイド
title: claude-idd-framework
description: CLAUDEエージェントが作業を開始する前後に参照すべき資料と必須手順をまとめたチェックリスト
version: 1.0.0
created: 2025-10-12
authors:
  - atsushifx
changes:
  - 2025-10-12: CLAUDE.mdとメモリ資料を反映してチェックリストを刷新
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

# エージェント運用ガイド

## 参照必須ドキュメント
- `CLAUDE.md`: リポジトリ全体の開発方針、MCP利用原則、ドキュメント品質基準を最優先で確認する。
- `.serena/memories/`: コードスタイル、ドキュメント品質、タスク完了条件、MCP利用例などの詳細な基準をすべて確認し、該当内容を作業に反映する。
- `.lsmcp/memories/`: プロジェクト概要と`scripts/xcp.sh`の最新実装状況を把握し、参照すべきアーティファクトを確認する。
- `handover.md`: 現在の課題、未完了作業、引き継ぎ事項を把握し、セッション中の優先順位を明確にする。
- 上記資料は作業中も常に参照できる状態に保ち、更新点がないか適宜再確認する。

## CLAUDE.mdの要点
- MCPツール (lsmcp、serena-mcp) の利用は全作業で必須であり、検索や編集前に必ず活用する。
- ドキュメントはプロジェクト固有の書き方に従い、禁止パターン (強調付き箇条書き、全角括弧など) を避ける。
- シェルスクリプトやコマンド整備はBDDとSDD手順に合わせ、`scripts/xcp.sh`を参照実装として扱う。
- Gitフック (lefthook) や`/validate-debug`を通じた品質ゲートを前提とし、コミット前後に必ず確認する。
- `docs/`配下の規約類、`.claude/commands/`と`.claude/agents/`の実装スタイルを把握してから作業する。

## .serena/memoriesの活用
- `code_style_and_conventions.md`: 禁止表現、フロントマター形式、コミットメッセージ規約、BDD原則を順守する。
- `document_quality_standards.md`: 見出し階層、文体、Markdown記法のチェックリストを作業開始前に確認し、完了時に全項目を満たす。
- `codebase_structure.md`: ディレクトリ構造と各ファイルの役割を把握し、編集対象の位置付けを明確にする。
- `custom_tools_authoring.md`: `.claude/commands/`と`.claude/agents/`を編集する際のフロントマター・実装ルールを参照する。
- `task_completion_checklist.md`および`suggested_commands.md`: タスク完了手順や推奨コマンドを基準として品質確認を行う。
- `project_purpose_and_tech_stack.md`と`xcp_implementation_status.md`: プロジェクト目的、技術スタック、参照実装の進捗を常に把握する。
- `xcp_symbol_map.md`: `scripts/xcp.sh`のシンボル構造を確認し、関連タスクの影響範囲を把握する。

## .lsmcp/memoriesの活用
- `project_overview.md`: プロジェクト全体像と主要ドキュメントの配置を理解する。
- `xcp_implementation_status.md`: `scripts/xcp.sh`のタスク進行状況、テストカバレッジ、直近の更新内容を確認する。
- 必要に応じてMCPの検索機能で関連仕様を再確認し、過去のワークフローと整合性を取る。

## 作業前チェックリスト
- 対象ファイルと関連資料をMCPツールで調査し、既存パターンや依存関係を把握する。
- `.serena/memories/`と`.lsmcp/memories/`に未読更新がないか確認し、必要箇所を読み直す。
- 対応タスクに関する`handover.md`の指示と未解決事項を整理し、作業範囲を明確化する。
- 編集対象がドキュメントの場合はフロントマター項目の有無を確認し、不足があれば補完する。

## 作業中の原則
- 変更内容はSDDおよびBDDの手順に従って段階的に進め、テストやドキュメント更新を同期させる。
- ローカル変更は必要最小限に留め、既存ファイルの意図しない差分を発生させない。
- MCPツールを活用して影響範囲を継続的に確認し、関連ファイルや規約との不整合を防ぐ。
- ドキュメント更新時は`document_quality_standards.md`のチェック項目を適用しながら記述する。

## 作業完了時の確認事項
- `.serena/memories/task_completion_checklist.md`に列挙されたフロントマター、表記、MCP利用チェックをすべて満たしているか再確認する。
- コード変更時は必要なテストや検証コマンドを実行し、結果を記録する。
- 作成・更新した内容が`CLAUDE.md`と各メモリの方針に一致していることを確認し、差異がある場合は理由を明記する。
- コミット前にGitフックの実行結果を確認し、問題があれば修正してから再実行する。
- 必要に応じて追加のメモリ更新やドキュメント追記を行い、次の作業者が参照できる状態に整える。
