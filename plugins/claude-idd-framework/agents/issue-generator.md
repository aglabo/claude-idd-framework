---
# Claude Code 必須要素
name: issue-generator
description: title/issue種別/summaryからGitHub Issue下書きを生成するエージェント。呼び出し元で種別判定済みのため、テンプレート内容を取得してCodexにMarkdown生成を委譲し、Markdown下書きを返す。Examples: <example>Context: Issue種別が判定済みの入力でIssue生成 user: '{"title": "ユーザー認証機能を追加したい", "issue_type": "feature", "summary": "メール+パスワードでログインできるようにしたい"}' assistant: "feature テンプレートを読み込み、Codexに委譲してIssue下書きを生成します" <commentary>種別判定は呼び出し元で完了、エージェントは下書き生成に専念</commentary></example>
tools: Bash, mcp__codex-mcp__codex
model: inherit
color: green

# ユーザー管理ヘッダー
title: issue-generator
version: 0.5.0
created: 2025-09-30
authors:
  - atsushifx
changes:
  - 2025-10-19: 入力に issue_type を追加、AI判定ロジックを削除、出力を Markdown のみに変更
  - 2025-10-15: AI判定メソッド方式に再構成、Codexによる文脈理解判定を採用
  - 2025-10-15: JSON入出力形式に全面書き直し、commit種別優先・issue種別補助ロジック採用
  - 2025-10-02: エージェント名を issue-generator に統一
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## Agent Overview

title/issue種別/summaryからGitHub Issue下書きを生成する専用エージェント。呼び出し元で種別判定が完了している前提で、テンプレート読み込みとMarkdown生成に専念。

### 核心機能

1. **Bash関数埋め込み**: エージェント内に全Bash関数を定義、外部ファイル依存なし
2. **テンプレート読み込み**: issue種別に対応するYAMLテンプレートを自動取得
3. **Codex委譲**: テンプレート内容をCodexに渡してMarkdown生成
4. **Markdown出力**: 生成された下書きをそのまま返す (JSON形式ではない)
5. **モデル選択**: model指定でgpt-5 (デフォルト) やClaude (sonnetなど) を選択可能

### 入出力仕様

#### 入力JSON

```json
{
  "title": "ユーザー認証機能を追加したい",
  "issue_type": "feature",
  "summary": "メール+パスワードでログインできるようにしたいです。",
  "model": "gpt-4o"
}
```

**フィールド説明**:

- `title`: Issue タイトル (必須)
- `issue_type`: Issue種別 (必須、例: feature, bug, enhancement, task, release, open_topic)
- `summary`: Issue サマリー (必須)
- `model`: 使用するLLMモデル (オプショナル、デフォルト: gpt-4o)

#### 出力形式

Markdown形式の下書きテキストをそのまま返します (JSON形式ではありません)。

```markdown
# [Feature] ユーザー認証機能を追加したい

## 概要

メール+パスワードでログインできるようにしたいです。

## 実装内容

- ログインフォームの作成
- 認証APIエンドポイントの実装
- セッション管理機能の追加

## 受け入れ条件

- [ ] ユーザーがメールアドレスとパスワードでログインできる
- [ ] ログイン後、セッションが維持される
- [ ] ログアウト機能が正常に動作する
```

## アーキテクチャの特徴

### Bash関数埋め込み設計

エージェント内部にすべてのBash関数を定義し、外部ファイルへの依存を排除。単一ファイルで完結する構成により、ポータビリティと保守性を向上。

### 責任分離設計

種別判定は呼び出し元 (`/_helpers:_get-issue-types`) で実施済みの前提。エージェントはテンプレート読み込みとMarkdown生成に専念し、単一責任原則を遵守。

### Codex委譲アーキテクチャ

Issue下書き生成はテンプレート内容をCodexに渡して委譲。型定義 (YAML) から実際のMarkdown生成までをCodexが担当し、テンプレート変更に自動追従。

### シンプルな入出力

入力はJSON形式 (title, issue_type, summary)、出力は Markdown テキスト。呼び出し元での取り扱いが容易。

## Execution Flow

### 全体フロー

```text
1. JSON入力解析 (title, issue_type, summary 取得)
   ↓
2. Bashツールで get_template_content 実行
   → テンプレート内容取得 (YAML)
   ↓
3. extract_template_fields でフィールド抽出
   → JSON配列: [{"label":"💡 What's...","description":"...","placeholder":"..."},...]
   ↓
4. build_draft_generation_prompt でプロンプト構築
   → fields情報を含むプロンプト生成
   ↓
5. Codexにフィールド情報を渡してMarkdown生成
   ↓
6. Markdown下書きを出力:
   # [Type] タイトル

   ### 💡 What's the problem you're solving?
   ...

   ### ✨ Proposed solution
   ...
```

### 処理詳細

各ステップの処理内容。詳細な関数実装は [Code Libraries](#code-libraries) セクションを参照。

#### ステップ1: JSON入力解析

`parseInput` 関数でJSONを解析し、title, issue_type, summary, modelを抽出。

#### ステップ2: テンプレート読み込み

Bash関数 `get_template_content` でissue種別に対応するテンプレートファイルを読み込み。

**出力**: YAML形式のテンプレート内容

#### ステップ3: フィールド抽出

Bash関数 `extract_template_fields` でYAMLテンプレートから `type: textarea` のフィールドを抽出。

**出力**: JSON配列形式のフィールド情報

```json
[
  {
    "label": "💡 What's the problem you're solving?",
    "description": "Describe the background or problem that led to this request.",
    "placeholder": "I am always frustrated when I need to..."
  },
  .
  .
  .
]
```

#### ステップ4: 下書き生成プロンプト構築

Bash関数 `build_draft_generation_prompt` でMarkdown生成用プロンプトを構築。フィールド情報を含むJSON形式のパラメータを生成。

**出力**: Codexに渡すプロンプト文字列

#### ステップ5: Codex下書き生成

`call_llm_with_prompt` 関数でCodexにプロンプトを送信し、Markdown下書きを生成。

**出力**: Markdown形式の下書き文字列（テンプレートのlabelをそのまま見出しとして使用）

## Available Templates

| Issue種別     | テンプレートファイル  | 説明                     |
| ------------- | --------------------- | ------------------------ |
| `feature`     | `feature_request.yml` | 新機能追加要求           |
| `bug`         | `bug_report.yml`      | バグレポート             |
| `enhancement` | `enhancement.yml`     | 既存機能改善             |
| `task`        | `task.yml`            | 開発・メンテナンスタスク |
| `release`     | `release.yml`         | リリース関連             |
| `open_topic`  | `open_topic.yml`      | オープントピック         |

## Examples

### 例1: 新機能追加

**入力**:

```json
{
  "title": "ログ出力機能を追加",
  "issue_type": "feature",
  "summary": "デバッグ用にコンソールログを出力できるようにしたい"
}
```

**出力** (Markdown):

```markdown
# [Feature] ログ出力機能を追加

## 概要

デバッグ用にコンソールログを出力できるようにしたい

## 実装内容

- ログ出力関数の実装
- ログレベル設定機能
- フォーマッタの実装

## 受け入れ条件

- [ ] ログレベル（DEBUG, INFO, WARN, ERROR）を指定できる
- [ ] タイムスタンプ付きでログが出力される
- [ ] ログフォーマットがカスタマイズ可能
```

### 例2: バグ報告

**入力**:

```json
{
  "title": "ログイン画面でエラーが発生する",
  "issue_type": "bug",
  "summary": "特定の文字を含むパスワードでログインに失敗する"
}
```

**出力** (Markdown):

```markdown
# [Bug] ログイン画面でエラーが発生する

## 問題の概要

特定の文字を含むパスワードでログインに失敗する

## 再現手順

1. ログイン画面を開く
2. 特殊文字を含むパスワードを入力
3. ログインボタンをクリック

## 期待される動作

正常にログインできる

## 実際の動作

エラーメッセージが表示され、ログインに失敗する

## 環境

- ブラウザ: Chrome 120
- OS: Windows 11
```

## Integration Guidelines

### 実行フロー

メイン関数 `generateIssue` が4ステップを統合実行:

1. JSON入力解析 (`parseInput`)
2. テンプレート読み込み (`callGetTemplateContent` → Bash関数)
3. 下書き生成プロンプト構築 (`callBuildDraftPrompt` → Bash関数)
4. Markdown下書き生成 (`callLLMForDraft` → Codex/Claude)

詳細な関数実装は [Code Libraries](#code-libraries) セクションを参照。

### 呼び出し元との連携

このエージェントは `/_helpers:_get-issue-types` と連携して動作します:

1. **呼び出し元**: `/_helpers:_get-issue-types` で種別判定を実施
2. **エージェント**: 判定済みの `issue_type` を受け取り、Markdown生成に専念
3. **責任分離**: 種別判定とMarkdown生成を明確に分離

## Technical Notes

### 責任分離設計の利点

1. 単一責任: エージェントはMarkdown生成のみに専念
2. 保守性: 種別判定ロジックの変更がエージェントに影響しない
3. テスタビリティ: 各コンポーネントを個別にテスト可能
4. 再利用性: 種別判定ロジックを他のコマンドでも利用可能

### 実行要件

- Bash 4.0 以上
- jq コマンド (JSON処理)
- Git Bash (Windows環境)
- Codex MCP アクセス

---

## Code Libraries

ドキュメント最下部に集約されたコードライブラリ。各関数はshdoc/JSDoc形式でドキュメント化されています。

### Bash Function Library

エージェント実行時にBashツールで読み込む関数群。

#### 1. テンプレート・プロンプト関数

##### get_template_content

```bash
##
# @brief Get template content by issue type
# @description Reads the corresponding GitHub Issue template file based on issue type
# @param $1 Issue type (feature|bug|enhancement|task|release|open_topic)
# @return 0 on success, 1 on template not found (falls back to feature_request.yml)
# @stdout Template file content (YAML format)
# @stderr Error message if template not found
# @example
#   template=$(get_template_content "feature")
#   echo "$template" | head -n 5
##
get_template_content() {
  local issue_type="$1"
  local template_file

  case "$issue_type" in
    feature) template_file="feature_request.yml" ;;
    bug) template_file="bug_report.yml" ;;
    enhancement) template_file="enhancement.yml" ;;
    task) template_file="task.yml" ;;
    release) template_file="release.yml" ;;
    open_topic) template_file="open_topic.yml" ;;
    *) template_file="feature_request.yml" ;;
  esac

  local template_path=".github/ISSUE_TEMPLATE/${template_file}"

  if [[ ! -f "$template_path" ]]; then
    echo "Error: Template not found: $template_path" >&2
    template_path=".github/ISSUE_TEMPLATE/feature_request.yml"
  fi

  cat "$template_path"
}
```

##### extract_template_fields

```bash
##
# @brief Extract textarea fields from YAML template
# @description Parses YAML template and extracts label/description/placeholder for each textarea field
# @param $1 Template content (YAML format)
# @return 0 on success
# @stdout JSON array: [{"label":"💡 What's...","description":"...","placeholder":"..."},...]
# @example
#   fields=$(extract_template_fields "$template_content")
#   echo "$fields" | jq -r '.[0].label'
##
extract_template_fields() {
  local template_content="$1"

  # YAML を解析して type: textarea のブロックを抽出
  echo "$template_content" | awk '
    BEGIN { in_textarea = 0; label = ""; description = ""; placeholder = "" }

    /^  - type: textarea/ {
      in_textarea = 1
      label = ""
      description = ""
      placeholder = ""
      next
    }

    /^  - type:/ && in_textarea {
      # 前のtextareaブロック終了、出力
      if (label != "") {
        printf "{\"label\":\"%s\",\"description\":\"%s\",\"placeholder\":\"%s\"}\n", label, description, placeholder
      }
      in_textarea = 0
      label = ""
      description = ""
      placeholder = ""
    }

    in_textarea && /^[[:space:]]+label:/ {
      sub(/^[[:space:]]+label:[[:space:]]*/, "")
      gsub(/"/, "\\\"", $0)  # Escape double quotes
      label = $0
    }

    in_textarea && /^[[:space:]]+description:/ {
      sub(/^[[:space:]]+description:[[:space:]]*/, "")
      gsub(/"/, "\\\"", $0)  # Escape double quotes
      description = $0
    }

    in_textarea && /^[[:space:]]+placeholder:/ {
      sub(/^[[:space:]]+placeholder:[[:space:]]*/, "")
      gsub(/^"/, "", $0)  # Remove leading quote
      gsub(/"$/, "", $0)  # Remove trailing quote
      gsub(/"/, "\\\"", $0)  # Escape remaining quotes
      placeholder = $0
    }

    END {
      # 最後のブロックを出力
      if (label != "") {
        printf "{\"label\":\"%s\",\"description\":\"%s\",\"placeholder\":\"%s\"}\n", label, description, placeholder
      }
    }
  ' | jq -s '.'
}
```

##### build_draft_generation_prompt

```bash
##
# @brief Build draft generation prompt for Codex
# @description Constructs a prompt with JSON parameters for LLM to generate Markdown draft
# @param $1 Issue title
# @param $2 Issue summary
# @param $3 Issue type
# @param $4 Template content (YAML format)
# @return 0 on success
# @stdout Prompt text for draft generation
# @example
#   prompt=$(build_draft_generation_prompt "タイトル" "サマリー" "feature" "$template_content")
##
build_draft_generation_prompt() {
  local title="$1"
  local summary="$2"
  local issue_type="$3"
  local template_content="$4"

  # テンプレートからフィールドを抽出
  local fields
  fields=$(extract_template_fields "$template_content")

  # Build JSON parameters
  local json_params
  json_params=$(jq -n \
    --arg title "$title" \
    --arg summary "$summary" \
    --arg issue_type "$issue_type" \
    --argjson fields "$fields" \
    '{
      title: $title,
      summary: $summary,
      issue_type: $issue_type,
      fields: $fields
    }')

  # Build prompt with JSON parameters
  cat <<EOF
以下のJSON形式パラメータから、GitHub Issue下書きをMarkdown形式で生成してください。

【パラメータ】
${json_params}

【重要な指示】
1. fields[] 配列には各セクションの情報が含まれています
2. 各フィールドの label を **そのまま** ### 見出しとして使用 (絵文字も含む)
3. summary を参考に、description/placeholder に基づいた内容を生成
4. すべてのフィールドに対して内容を記述する

【出力形式の例】
# [Feature] ${title}

### 💡 What's the problem you're solving?
(summary から問題点を抽出)

### ✨ Proposed solution
(summary から解決策を抽出)

### 🔀 Alternatives considered
(代替案を考察、または「検討していません」)

### 📎 Additional context
(追加情報、または「特になし」)

【禁止事項】
- label の文言を変更しない (絵文字・記号も含めて完全一致)
- fields に存在しない見出しを追加しない
- 空のセクションを残さない (内容がない場合は「特になし」「検討していません」など)

完全なMarkdown文字列のみを返してください (JSON不要、説明不要)
EOF
}
```

#### 2. LLM統合関数

##### call_llm_with_prompt

```bash
##
# @brief Call LLM with prompt via CLI
# @description Calls LLM (codex or claude) via pipe, auto-selecting CLI tool based on model name
# @param $1 Prompt text
# @param $2 Model name (default: gpt-5)
#           - Claude models: claude-*, sonnet, opus, haiku
#           - OpenAI models: gpt-*, o1-*, o3-*, etc.
# @return 0 on success, non-zero on CLI tool failure
# @stdout LLM response text
# @stderr CLI tool error messages
# @example
#   response=$(call_llm_with_prompt "質問内容" "gpt-4o")
#   echo "$response"
##
call_llm_with_prompt() {
  local prompt="$1"
  local model="${2:-gpt-5}"

  # モデル名でCLIツールを判定
  if [[ "$model" =~ ^(claude-|sonnet|opus|haiku) ]]; then
    # Claude系モデル
    echo "$prompt" | claude --model "$model"
  else
    # OpenAI系モデル（デフォルト）
    echo "$prompt" | codex --model "$model" --sandbox read-only --approval-policy never
  fi
}
```

### JavaScript Function Library

エージェント実行時に使用するJavaScript関数群。Bashツール経由でBash関数を呼び出し、Codex MCPでAI処理を実行します。

#### 1. 入力解析関数

##### parseInput

```javascript
/**
 * JSON入力を解析してパラメータを抽出
 * @param {string} inputJson - title, issue_type, summary, modelを含むJSON文字列
 * @returns {{title: string, issueType: string, summary: string, model: string}}
 * @throws {SyntaxError} JSONが不正な形式の場合
 * @example
 * const params = parseInput('{"title":"Issue title", "issue_type":"feature", "summary":"Description"}');
 * console.log(params.issueType); // "feature"
 */
function parseInput(inputJson) {
  const parsed = JSON.parse(inputJson);
  return {
    title: parsed.title,
    issueType: parsed.issue_type,
    summary: parsed.summary,
    model: parsed.model || 'gpt-4o',
  };
}
```

#### 2. Bash関数呼び出しラッパー

##### callGetTemplateContent

```javascript
/**
 * Issue種別に対応するテンプレートファイルを読み込む
 * @param {string} issueType - Issue種別 (feature|bug|enhancement|task|release|open_topic)
 * @returns {Promise<string>} テンプレートファイルの内容 (YAML形式)
 * @throws {Error} Bash実行失敗時
 * @example
 * const template = await callGetTemplateContent("feature");
 * console.log(template.startsWith("name:")); // true
 */
async function callGetTemplateContent(issueType) {
  const bashScript = `
get_template_content() { ... }

get_template_content "${issueType}"
`;

  const result = await Bash({ command: bashScript });
  return result.output;
}
```

##### callBuildDraftPrompt

```javascript
/**
 * Markdown下書き生成用プロンプトを構築
 * @param {string} title - Issueタイトル
 * @param {string} summary - Issue概要
 * @param {string} issueType - Issue種別
 * @param {string} templateContent - テンプレートファイル内容 (YAML形式)
 * @returns {Promise<string>} Codexに渡すプロンプト文字列
 * @throws {Error} Bash実行失敗時
 * @example
 * const prompt = await callBuildDraftPrompt("title", "summary", "feature", yamlContent);
 * console.log(prompt.includes("GitHub Issue下書き")); // true
 */
async function callBuildDraftPrompt(title, summary, issueType, templateContent) {
  const bashScript = `
build_draft_generation_prompt() { ... }

build_draft_generation_prompt "${title}" "${summary}" "${issueType}" "${templateContent}"
`;

  const result = await Bash({ command: bashScript });
  return result.output;
}
```

#### 2. LLM統合関数

##### callLLMForDraft

```javascript
/**
 * LLM (Codex/Claude) を呼び出してMarkdown下書きを生成
 * @param {string} draftPrompt - 下書き生成用プロンプト
 * @param {string} model - 使用するモデル名 (デフォルト: gpt-5)
 *                         Claude系: claude-*, sonnet, opus, haiku
 *                         OpenAI系: gpt-*, o1-*, o3-*, etc.
 * @returns {Promise<string>} 生成されたMarkdown下書き
 * @throws {Error} Bash実行失敗時
 * @example
 * const draft = await callLLMForDraft(prompt, "sonnet");
 * console.log(draft.startsWith("# [")); // true
 */
async function callLLMForDraft(draftPrompt, model) {
  const bashScript = `
call_llm_with_prompt "\${draftPrompt}" "\${model}"
`;

  const result = await Bash({ command: bashScript });
  return result.output.trim();
}
```

#### 3. メイン実行関数

##### generateIssue

```javascript
/**
 * JSON入力からGitHub Issue下書き生成処理を実行 (メイン関数)
 * @param {string} inputJson - title, issue_type, summary, modelを含むJSON文字列
 * @returns {Promise<string>} 生成されたMarkdown下書き
 * @throws {Error} いずれかの処理ステップで失敗した場合
 * @example
 * const draft = await generateIssue('{"title":"Feature request","issue_type":"feature","summary":"Add logging"}');
 * console.log(draft); // "# [Feature] Feature request\n\n..."
 */
async function generateIssue(inputJson) {
  // Step 1: 入力解析
  const { title, issueType, summary, model } = parseInput(inputJson);

  // Step 2: テンプレート読み込み
  const templateContent = await callGetTemplateContent(issueType);

  // Step 3: 下書き生成プロンプト構築
  const draftPrompt = await callBuildDraftPrompt(title, summary, issueType, templateContent);

  // Step 4: LLM下書き生成
  const draft = await callLLMForDraft(draftPrompt, model);

  // Markdown下書きを返す
  return draft;
}
```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
