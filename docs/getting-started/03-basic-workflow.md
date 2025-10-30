---
header:
  - src: docs/getting-started/03-basic-workflow.md
  - "@(#)": Basic workflow guide covering three fundamental operations, recommended workflows, and troubleshooting
title: claude-idd-framework
description: Comprehensive basic workflow guide with Issue creation, commit message generation, PR creation, and troubleshooting for claude-idd-framework
version: 1.0.0
created: 2025-10-30
authors:
  - atsushifx
changes:
  - 2025-10-30: Initial skeleton creation with heading structure
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

# 基本的なワークフロー

## 1. 基本操作

### 1.1 Issue の作成

#### Issue 作成コマンドの実行

新しい Issue を作成するには、`/claude-idd-framework:idd:issue:new` コマンドを実行します。

このコマンドは対話形式で Issue のタイトルとサマリーを AI が生成し、Issue タイプを自動判定します。生成された Issue ドラフトは `temp/idd/issues/new-YYYYMMDD-HHMMSS-[type]-[title].md` 形式で保存されます。

#### Issue の編集

作成した Issue ドラフトを編集するには、`/claude-idd-framework:idd:issue:edit` コマンドを実行します。

このコマンドは codex-mcp を使用して対話的に Issue の内容を編集します。タイトル、サマリー、本文、ラベルなどを追加・修正できます。

#### GitHub への Push

編集が完了した Issue ドラフトを GitHub にプッシュするには、`/claude-idd-framework:idd:issue:push` コマンドを実行します。

このコマンドは Issue を GitHub に作成し、発行された Issue 番号でファイル名を更新します (例: `42-20251030-120000-feature-user-login.md`)。既存 Issue の更新にも対応しています。

#### ブランチの作成

Issue からブランチを作成するには、`/claude-idd-framework:idd:issue:branch new` コマンドでブランチ提案を生成し、`/claude-idd-framework:idd:issue:branch commit` コマンドで実際にブランチを作成します。

ブランチ名は Issue のタイトルとドメインから自動生成されます (例: `feat-42/auth/user-login`)。ドメインは `--domain` オプションで明示的に指定することもできます。

### 1.2 コミットメッセージの生成

#### 変更のステージング

コミットメッセージを生成する前に、変更をステージングします。

`git add` コマンドで変更をステージングエリアに追加します。`/claude-idd-framework:idd-commit-message` コマンドはステージングされた変更を分析して適切なメッセージを生成します。

#### メッセージ生成コマンドの実行

ステージングが完了したら、`/claude-idd-framework:idd-commit-message` コマンドを実行します。

このコマンドは `git diff --staged` でステージングされた変更を分析し、Conventional Commits 形式のメッセージを生成します。変更の性質 (feature、fix、docs など) を自動判定し、適切なスコープと説明を含めます。

#### 生成されたメッセージの確認

生成されたコミットメッセージを確認し、必要に応じて編集します。

メッセージは `type(scope): subject` 形式で生成されます。内容が適切であれば、そのままコミットに使用できます。メッセージの編集が必要な場合は、対話形式で修正できます。

### 1.3 Pull Request の作成

#### PR 生成コマンドの実行

ブランチでの作業が完了したら、`/claude-idd-framework:idd-pr` コマンドを実行します。

このコマンドはブランチの変更履歴を分析し、Pull Request のタイトル、サマリー、テスト計画を含むドラフトを生成します。ベースブランチからの差分を自動検出し、適切な説明を作成します。

#### PR ドラフトの確認

生成された PR ドラフトの内容を確認します。

ドラフトには変更の概要 (Summary)、テスト計画 (Test plan)、関連 Issue へのリンクが含まれます。必要に応じて内容を編集し、レビュアーに伝えたい情報を追加できます。

#### GitHub への作成

ドラフトの内容が適切であれば、`gh pr create` コマンドまたは GitHub の Web インターフェースを使用して Pull Request を作成します。

生成されたドラフトをそのまま使用することで、一貫性のある PR 説明を維持できます。PR 作成後は、レビュープロセスに従って進めます。

## 2. 推奨ワークフロー

### 2.1 Issue-Driven Development (IDD)

#### IDD の概念

Issue-Driven Development (IDD) は、すべての作業を GitHub Issue として管理する開発手法です。

機能追加、バグ修正、ドキュメント更新など、すべてのタスクを Issue として記録し、Issue 番号を使ってブランチ、コミット、Pull Request を紐付けます。これにより、変更の意図と経緯を明確に追跡できます。

#### 実践例

実際の IDD ワークフローの例を示します。

Issue 作成 → ブランチ作成 (`feat-42/auth/user-login`) → 実装とコミット → Pull Request 作成 → レビューとマージの流れで進めます。各ステップで Issue 番号を参照することで、作業の文脈を維持します。

#### GitHub Issues との連携

claude-idd-framework は GitHub Issues と緊密に連携します。

`/claude-idd-framework:idd:issue:push` コマンドでローカル Issue を GitHub にプッシュし、`/claude-idd-framework:idd:issue:load` コマンドで既存 Issue をローカルに取り込めます。双方向の同期により、チーム開発でも一貫性を保てます。

### 2.2 BDD 開発サイクル (全コード開発で必須)

claude-idd-framework では、BDD (Behavior-Driven Development) が全コード開発で必須です。テスト、実装、ドキュメントのすべてに BDD 原則を適用します。

#### Red-Green-Refactor サイクル

BDD 開発は Red-Green-Refactor サイクルに従います。

RED フェーズで失敗するテストを書き、GREEN フェーズで最小限の実装でテストを通過させ、REFACTOR フェーズでコード品質を向上させます。このサイクルを繰り返すことで、テストでカバーされた高品質なコードを作成します。

#### BDD 形式 JSDoc の追加

すべての関数に BDD 形式の JSDoc を追加します。

JSDoc には Given/When/Then 形式でテストケースを記述します。例: `@test {Given} 前提条件`, `@test {When} 操作内容`, `@test {Then:[正常]} 期待結果`。この形式により、コードの意図とテストケースが一体化します。

#### テスト駆動開発の実践

テスト駆動開発 (TDD) を実践します。

実装前にテストを書き、テストが RED であることを確認してから実装を開始します。テストファーストのアプローチにより、要件を明確にし、バグを早期に発見できます。すべてのコード変更には対応するテストが必要です。

### 2.3 テスト実行と Git Hooks

#### テスト実行コマンド

プロジェクトのテストを実行するには、テストランナーコマンドを使用します。

TypeScript プロジェクトでは `pnpm run test:develop` (Vitest)、シェルスクリプトでは `shellspec` を実行します。テストは BDD 階層 (Given/When/Then) で構成され、コード変更時に自動実行されます。

#### Lefthook による Git Hooks 統合

claude-idd-framework は lefthook を使用して Git Hooks を統合します。

`pnpm run prepare` コマンドで lefthook をインストールすると、pre-commit、prepare-commit-msg、commit-msg の各フックが自動設定されます。これにより、コミット時の品質チェックが自動化されます。

#### 各 Hook の目的

各 Git Hook には明確な目的があります。

pre-commit フックは gitleaks でシークレット検出を実行し、prepare-commit-msg フックは `scripts/prepare-commit-msg.sh` でコミットメッセージ候補を生成し、commit-msg フックは commitlint で Conventional Commits 形式を検証します。これらのフックにより、コミット品質が保証されます。

## 3. トラブルシューティング

### 3.1 コマンド実行エラー

コマンドが認識されない、または実行時にエラーが発生する場合の対処方法を説明します。

症状: `/claude-idd-framework:xxx` コマンドが "Unknown command" エラーを表示する。原因: プラグインが正しくロードされていない、または Claude Code が再起動されていない。解決方法: Claude Code を完全に再起動し、`/help` コマンドでカスタムコマンド一覧を確認します。それでも解決しない場合は、プラグインを再インストールします。

### 3.2 プラグイン関連の問題

プラグインのインストールや更新に関する問題の対処方法を説明します。

症状: プラグインインストール時に "Installation failed" エラーが発生する。原因: GitHub への接続エラー、または不正なリポジトリ URL。解決方法: ネットワーク接続を確認し、マーケットプレイス URL `https://github.com/aglabo/claude-idd-framework.git` が正確に入力されているか確認します。プロキシ設定が必要な環境では、Git のプロキシ設定を確認します。

### 3.3 MCP サーバー接続問題

MCP サーバー (codex-mcp、serena-mcp、lsmcp) への接続問題の対処方法を説明します。

症状: コマンド実行時に "MCP server connection failed" エラーが表示される。原因: MCP サーバーが起動していない、または設定が不正。解決方法: Claude Code の MCP 設定画面で各サーバーのステータスを確認します。サーバーが停止している場合は再起動し、設定ファイル (`.claude/mcp.json`) が正しいか確認します。

### 3.4 認証エラー

GitHub 認証に関する問題の対処方法を説明します。

症状: `/claude-idd-framework:idd:issue:push` コマンド実行時に "Authentication failed" エラーが発生する。原因: GitHub CLI (gh) の認証が未完了、またはトークンが無効。解決方法: `gh auth status` で認証状態を確認し、未認証の場合は `gh auth login` を実行します。トークンの権限スコープに `repo` が含まれているか確認します。

### 3.5 その他のエラー

その他の一般的なエラーの対処方法を説明します。

症状: Issue ドラフトファイルが見つからない、または読み取れない。原因: `temp/idd/issues/` ディレクトリが存在しない、またはファイル権限の問題。解決方法: ディレクトリを手動で作成 (`mkdir -p temp/idd/issues`) し、ファイル権限を確認します。それでも解決しない場合は、CLAUDE.md のトラブルシューティングセクションまたは GitHub Issues で報告してください。

## 4. ヘルプとサポート

### 4.1 ドキュメント

詳細なドキュメントは CLAUDE.md で提供されています。

CLAUDE.md にはカスタムコマンドの完全なリファレンス、カスタムエージェントの説明、MCP ツールの使用方法、開発のベストプラクティスが記載されています。ワークフローやトラブルシューティングの詳細情報が必要な場合は、まず CLAUDE.md を参照してください。

### 4.2 GitHub Issues

問題の報告や機能リクエストは GitHub Issues で受け付けています。

バグ報告、機能改善の提案、ドキュメントの改善要望など、すべてのフィードバックを歓迎します。Issue を作成する際は、再現手順、期待される動作、実際の動作を明確に記載してください。

### 4.3 コミュニティ

コミュニティサポートは GitHub Discussions で提供されています。

開発のヒント、ベストプラクティスの共有、質問と回答など、コミュニティメンバーとの交流に GitHub Discussions を活用してください。他のユーザーの経験から学び、知識を共有する場として活用できます。

## 5. 次のステップ

### 5.1 高度な機能の学習

基本操作を習得したら、高度な機能を学びましょう。

CLAUDE.md の各セクション (BDD ワークフロー、MCP ツール使用法、カスタムエージェント) を順に読み進めることで、claude-idd-framework の全機能を活用できるようになります。特に、BDD 開発サイクル、Spec-Driven Development (SDD) ワークフロー、複数段階の品質検証プロセスについて理解を深めることを推奨します。
