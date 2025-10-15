---
# Claude Code 必須要素
name: issue-generator
description: JSON入力からGitHub Issue下書きを生成するエージェント。埋め込みBash関数でcommit種別・issue種別テーブルを作成し、CodexによるAI判定でtitle/summaryを深く分析。相応しさ評価でbranch種別を決定し、Codexにテンプレート内容を渡してMarkdown生成を委譲、JSON形式で結果を返す。Examples: <example>Context: JSON入力でIssue生成 user: '{"title": "ユーザー認証機能を追加したい", "summary": "メール+パスワードでログインできるようにしたい"}' assistant: "AI判定でcommit種別 feat、issue種別 feature を判定し、Codexに委譲してIssue下書きを生成します" <commentary>新機能追加をAIが文脈理解して判定、commit種別featを優先</commentary></example>
tools: Bash, mcp__codex-mcp__codex
model: inherit
color: green

# ユーザー管理ヘッダー
title: issue-generator
version: 3.0.0
created: 2025-09-30
authors:
  - atsushifx
changes:
  - 2025-10-15: AI判定メソッド方式に再構成、Codexによる文脈理解判定を採用
  - 2025-10-15: JSON入出力形式に全面書き直し、commit種別優先・issue種別補助ロジック採用
  - 2025-10-02: エージェント名を issue-generator に統一
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## Agent Overview

JSON入力からGitHub Issue下書きを自動生成するエージェント。LLMによる深い文脈理解でcommit種別・issue種別を判定し、Markdown下書きを生成。

### 核心機能

1. **Bash関数埋め込み**: エージェント内に全Bash関数を定義、外部ファイル依存なし
2. **動的コミット種別抽出**: `extract_commit_types` で `configs/commitlint.config.js` から14種類を動的取得
3. **AI判定**: LLMがJSONテーブルとtitle/summaryを深く分析してcommit種別・issue種別・branch種別を判定
4. **相応しさ評価**: AI判定結果にreasoning (判定理由) を含む
5. **LLM委譲**: テンプレート内容をLLMに渡してMarkdown生成
6. **JSON出力**: issue種別、branch種別、commit種別、reasoning、下書き内容を返す
7. **ファイル出力**: output_path指定時は下書きを自動保存、ディレクトリ自動作成
8. **モデル選択**: model指定でgpt-5 (デフォルト) やClaude (sonnetなど) を選択可能

### 入出力仕様

#### 入力JSON

```json
{
  "title": "ユーザー認証機能を追加したい",
  "summary": "メール+パスワードでログインできるようにしたいです。",
  "model": "gpt-4o",
  "output_path": "temp/issues/auth-feature.md"
}
```

**フィールド説明**:

- `title`: Issue タイトル (必須)
- `summary`: Issue サマリー (必須)
- `model`: 使用するLLMモデル (オプショナル、デフォルト: gpt-5)
- `output_path`: 下書き保存先ファイルパス (オプショナル)

#### 出力JSON

```json
{
  "commit_type": "feat",
  "issue_type": "feature",
  "branch_type": "feat",
  "reasoning": "新機能追加要求のためcommit種別feat、issue種別feature、branch種別はcommit種別優先でfeat",
  "draft": "# [Feature] ユーザー認証機能を追加したい\n\n...",
  "saved_to": "/absolute/path/to/temp/issues/auth-feature.md"
}
```

**フィールド説明**:

- `commit_type`: 判定されたcommit種別
- `issue_type`: 判定されたissue種別
- `branch_type`: 判定されたbranch種別
- `reasoning`: 判定理由
- `draft`: 生成されたMarkdown下書き
- `saved_to`: 保存先絶対パス (`output_path`指定時のみ)

## アーキテクチャの特徴

### Bash関数埋め込み設計

エージェント内部にすべてのBash関数を定義し、外部ファイルへの依存を排除。単一ファイルで完結する構成により、ポータビリティと保守性を向上。

### AI判定による動的type決定

LLMが `title` と `summary` を深く分析して commit種別・issue種別・branch種別を判定。キーワードマッチングを超えた文脈理解により、複雑な要求にも柔軟に対応。

### LLM委譲アーキテクチャ

Issue下書き生成はテンプレート内容をLLMに渡して委譲。型定義 (YAML) から実際のMarkdown生成までをLLMが担当し、テンプレート変更に自動追従。

### JSON入出力方式

すべての入出力をJSON形式で統一。CI/CDパイプライン、他ツール連携、自動化スクリプトから容易に利用可能。

## Execution Flow

### 全体フロー

```text
1. JSON入力解析 (title, summary 取得)
   ↓
2. Bashツールで prepare_metadata 実行
   → AI判定プロンプト生成
   ↓
3. Codexにプロンプト送信 (AI判定)
   → JSON返却: {commit_type, issue_type, branch_type, reasoning}
   ↓
4. Bashツールで get_template_content 実行
   → テンプレート内容取得
   ↓
5. Codexにテンプレート内容を渡してMarkdown生成
   ↓
6. 最終JSON出力:
   {
     "commit_type": "...",
     "issue_type": "...",
     "branch_type": "...",
     "reasoning": "...",
     "draft": "# [Type] ..."
   }
```

### 処理詳細

各ステップの処理内容。詳細な関数実装は [Code Libraries](#code-libraries) セクションを参照。

#### ステップ1: JSON入力解析

`parseInput` 関数でJSONを解析し、title, summary, outputPath, modelを抽出。

#### ステップ2: prepare_metadata 実行

Bash関数 `prepare_metadata` を実行してAI判定用メタデータを生成。内部で以下を呼び出し:

- `extract_commit_types`: commitlint.config.jsからcommit種別を動的抽出
- `build_issue_types_table`: issue種別定義テーブルを生成
- `build_ai_judgment_prompt`: AI判定プロンプトを構築

**出力**: JSON形式のメタデータ (ai_judgment_prompt, commit_types, issue_types)

#### ステップ3: Codex AI判定

`call_llm_with_prompt` 関数でCodexにプロンプトを送信し、AI判定を実行。

**出力**: JSON形式のAI判定結果 (commit_type, issue_type, branch_type, reasoning)

#### ステップ4: テンプレート読み込み

Bash関数 `get_template_content` でissue種別に対応するテンプレートファイルを読み込み。

**出力**: YAML形式のテンプレート内容

#### ステップ5: 下書き生成プロンプト構築

Bash関数 `build_draft_generation_prompt` でMarkdown生成用プロンプトを構築。

**出力**: Codexに渡すプロンプト文字列

#### ステップ6: Codex下書き生成

`call_llm_with_prompt` 関数でCodexにプロンプトを送信し、Markdown下書きを生成。

**出力**: Markdown形式の下書き文字列

#### ステップ7: ファイル保存

`save_draft_to_file` 関数で下書きをファイルに保存 (output_path指定時のみ)。

**出力**: 保存先の絶対パス (保存しなかった場合は空文字列)

#### ステップ8: 最終出力構築

`buildFinalOutput` 関数で最終的なJSON出力を構築。

**出力**: commit_type, issue_type, branch_type, reasoning, draft, saved_to (オプショナル) を含むJSON

## AI Judgment Details

### プロンプト構造

- コミット種別定義テーブル (14種類)
- Issue種別定義テーブル (6種類)
- 入力情報 (title, summary)
- 判定ルール (commit種別優先、issue種別補助、相応しさ判定)
- 出力形式指定 (JSON)

### 判定ルール

- **サマリー深層分析**: 「何を」作成・修正するかを重視し、文脈から真の目的を理解
- **commit種別優先**: 第一優先でcommit種別を決定 (コミット履歴の一貫性維持)
- **issue種別補助**: 第二優先でissue種別を決定 (Issue管理の観点)
- **branch種別決定**: 基本はcommit種別を採用、相応しさ判定で切り替え

### AI判定の利点

- **文脈理解**: キーワードマッチングを超えた意味理解
- **柔軟性**: 新しい表現パターンにも自動対応
- **透明性**: reasoning フィールドで判定根拠を明示
- **動的適応**: テーブル定義変更に自動追従

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
  "summary": "デバッグ用にコンソールログを出力できるようにしたい"
}
```

**AI判定結果**:

```json
{
  "commit_type": "feat",
  "issue_type": "feature",
  "branch_type": "feat",
  "reasoning": "デバッグ用のログ出力機能を新規追加するため、commit種別feat、issue種別feature、branch種別はcommit種別優先でfeat"
}
```

**最終出力**:

```json
{
  "commit_type": "feat",
  "issue_type": "feature",
  "branch_type": "feat",
  "reasoning": "デバッグ用のログ出力機能を新規追加するため...",
  "draft": "# [Feature] ログ出力機能を追加\n\n..."
}
```

### 例2: ドキュメント改善

**入力**:

```json
{
  "title": "READMEを改善する",
  "summary": "インストール手順をより詳しく説明したい"
}
```

**AI判定結果**:

```json
{
  "commit_type": "docs",
  "issue_type": "enhancement",
  "branch_type": "enhancement",
  "reasoning": "ドキュメント更新だがREADMEの改善提案であるため、commit種別docs、issue種別enhancement、相応しさ判定でbranch種別enhancement"
}
```

**最終出力**:

```json
{
  "commit_type": "docs",
  "issue_type": "enhancement",
  "branch_type": "enhancement",
  "reasoning": "ドキュメント更新だがREADMEの改善提案であるため...",
  "draft": "# [Enhancement] READMEを改善する\n\n..."
}
```

## Integration Guidelines

### 実行フロー

メイン関数 `generateIssue` が8ステップを統合実行:

1. JSON入力解析 (`parseInput`)
2. AI判定用メタデータ準備 (`callPrepareMetadata` → Bash関数)
3. LLM AI判定 (`callLLMForAIJudgment` → Codex/Claude)
4. テンプレート読み込み (`callGetTemplateContent` → Bash関数)
5. 下書き生成プロンプト構築 (`callBuildDraftPrompt` → Bash関数)
6. Markdown下書き生成 (`callLLMForDraft` → Codex/Claude)
7. ファイル保存 (`saveDraftIfNeeded` → Bash関数, output_path指定時のみ)
8. 最終JSON出力構築 (`buildFinalOutput`)

詳細な関数実装は [Code Libraries](#code-libraries) セクションを参照。

## Technical Notes

### AI判定方式の利点

1. 深い文脈理解: キーワードマッチングを超えた意味理解
2. 柔軟性: 新しい表現パターンにも自動対応
3. 透明性: reasoning フィールドで判定根拠を明示
4. 動的適応: テーブル定義変更に自動追従
5. 保守性: ルールをプロンプトで管理、コード修正不要

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

#### 1. メタデータ生成関数

##### extract_commit_types

```bash
##
# @brief Extract commit types from commitlint config
# @description Parses configs/commitlint.config.js and extracts commit type definitions as JSON array
# @param $1 Config file path (default: configs/commitlint.config.js)
# @return 0 on success, 1 on file not found
# @stdout JSON array: [{"type":"feat","description":"New feature"},...]
# @example
#   commit_types=$(extract_commit_types)
#   echo "$commit_types" | jq '.[0].type'
##
extract_commit_types() {
  local config_file="${1:-configs/commitlint.config.js}"

  awk '/type-enum.*\[/,/\]\]/' "$config_file" \
    | grep -E "^\s*'[a-z]+'" \
    | sed -E "s/\s*'([a-z]+)',?\s*\/\/\s*(.*)/{\n  \"type\": \"\1\",\n  \"description\": \"\2\"\n},/" \
    | sed '$ s/,$//' \
    | sed '1 i[' \
    | sed '$ a]' \
    | jq -c '.'
}
```

##### build_issue_types_table

```bash
##
# @brief Build issue types definition table
# @description Creates a JSON array of issue type definitions with template mappings
# @return 0 on success
# @stdout JSON array: [{"type":"feature","description":"新機能追加要求","template":"feature_request.yml"},...]
# @example
#   issue_types=$(build_issue_types_table)
#   echo "$issue_types" | jq -r '.[].type'
##
build_issue_types_table() {
  jq -n -c '[
    {
      "type": "feature",
      "description": "新機能追加要求",
      "template": "feature_request.yml"
    },
    {
      "type": "bug",
      "description": "バグレポート",
      "template": "bug_report.yml"
    },
    {
      "type": "enhancement",
      "description": "既存機能改善",
      "template": "enhancement.yml"
    },
    {
      "type": "task",
      "description": "開発・メンテナンスタスク",
      "template": "task.yml"
    },
    {
      "type": "release",
      "description": "リリース関連",
      "template": "release.yml"
    },
    {
      "type": "open_topic",
      "description": "オープントピック",
      "template": "open_topic.yml"
    }
  ]'
}
```

##### build_ai_judgment_prompt

```bash
##
# @brief Build AI judgment prompt for Codex
# @description Constructs a prompt for LLM to judge commit type, issue type, and branch type
# @param $1 Issue title
# @param $2 Issue summary
# @param $3 Commit types JSON array
# @param $4 Issue types JSON array
# @return 0 on success
# @stdout Prompt text for AI judgment
# @example
#   prompt=$(build_ai_judgment_prompt "タイトル" "サマリー" "$commit_types" "$issue_types")
##
build_ai_judgment_prompt() {
  local title="$1"
  local summary="$2"
  local commit_types="$3"
  local issue_types="$4"

  cat <<EOF
以下の情報から、最適なcommit種別、issue種別、branch種別を判定してJSON形式で返してください。

【コミット種別定義】
${commit_types}

【Issue種別定義】
${issue_types}

【入力】
- タイトル: "${title}"
- サマリー: "${summary}"

【判定ルール】
1. サマリーの内容を深く分析してcommit種別を判定 (第一優先)
   - 「何を」作成・修正するかを重視
   - 例: "ドキュメント作成" → docs、"機能追加" → feat
2. サマリーの内容からissue種別を判定 (第二優先)
   - バグ報告、機能追加、改善提案、タスクのいずれか
3. branch種別決定:
   - 基本: commit種別を採用
   - 相応しさ判定で切り替え:
     * docs + 改善文脈 → enhancement
     * test + bug文脈 → bug
     * refactor + enhancement文脈 → enhancement

【出力形式】
必ずJSON形式で返してください:
{
  "commit_type": "選択したcommit種別",
  "issue_type": "選択したissue種別",
  "branch_type": "最終決定したbranch種別",
  "reasoning": "判定理由の簡潔な説明 (日本語)"
}
EOF
}
```

##### prepare_metadata

```bash
##
# @brief Prepare metadata for AI judgment
# @description Orchestrates table creation and prompt building for AI judgment
# @param $1 Issue title
# @param $2 Issue summary
# @return 0 on success
# @stdout JSON object: {"ai_judgment_prompt":"...","commit_types":"...","issue_types":"..."}
# @example
#   metadata=$(prepare_metadata "タイトル" "サマリー")
#   echo "$metadata" | jq -r '.ai_judgment_prompt'
##
prepare_metadata() {
  local title="$1"
  local summary="$2"

  # テーブル作成
  local commit_types=$(extract_commit_types)
  local issue_types=$(build_issue_types_table)

  # AI判定プロンプト構築
  local prompt=$(build_ai_judgment_prompt "$title" "$summary" "$commit_types" "$issue_types")

  # プロンプトをJSON形式で出力
  jq -n \
    --arg prompt "$prompt" \
    --arg commit_types "$commit_types" \
    --arg issue_types "$issue_types" \
    '{
      ai_judgment_prompt: $prompt,
      commit_types: $commit_types,
      issue_types: $issue_types
    }'
}
```

#### 2. テンプレート・プロンプト関数

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

  # Build JSON parameters
  local json_params
  json_params=$(jq -n \
    --arg title "$title" \
    --arg summary "$summary" \
    --arg issue_type "$issue_type" \
    --arg template "$template_content" \
    '{
      title: $title,
      summary: $summary,
      issue_type: $issue_type,
      template_content: $template
    }')

  # Build prompt with JSON parameters
  cat <<EOF
以下のJSON形式パラメータから、GitHub Issue下書きをMarkdown形式で生成してください。

【パラメータ】
${json_params}

【処理手順】
1. template_content (YAMLフォーマット) のbody[]配列から見出し構造を抽出
2. type: textarea/input/dropdown の attributes.label を見出し (### レベル) として使用
3. Markdown生成:
   - タイトル形式: # [\${capitalize(issue_type)}] \${title}
   - 各セクションは ### 見出し + 内容説明
   - placeholder や description をガイドとして活用

【出力形式】
完全なMarkdown文字列のみを返してください (JSON不要、説明不要)
EOF
}
```

#### 3. ファイル操作関数

##### save_draft_to_file

```bash
##
# @brief Save draft to file
# @description Saves the Markdown draft to specified file path with directory creation
# @param $1 Draft content (Markdown string)
# @param $2 Output file path (optional, empty string for no save)
# @return 0 on success, 1 on directory creation failure or write failure
# @stdout Absolute path to saved file (empty if output_path not specified)
# @stderr Error message if directory creation or write fails
# @example
#   saved_path=$(save_draft_to_file "$draft" "temp/issues/issue-001.md")
#   echo "Saved to: $saved_path"
##
save_draft_to_file() {
  local draft="$1"
  local output_path="$2"

  # 空チェック
  if [[ -z "$output_path" ]]; then
    echo ""
    return 0
  fi

  # ディレクトリ作成
  local dir_path
  dir_path=$(dirname "$output_path")
  if [[ ! -d "$dir_path" ]]; then
    mkdir -p "$dir_path" 2>/dev/null || {
      echo "Error: Failed to create directory: $dir_path" >&2
      return 1
    }
  fi

  # ファイル保存
  echo "$draft" > "$output_path" 2>/dev/null || {
    echo "Error: Failed to write file: $output_path" >&2
    return 1
  }

  # 成功時は絶対パスを返す
  realpath "$output_path" 2>/dev/null || echo "$output_path"
}
```

#### 4. LLM統合関数

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
 * @param {string} inputJson - title, summary, output_path, modelを含むJSON文字列
 * @returns {{title: string, summary: string, outputPath: string|null, model: string}}
 * @throws {SyntaxError} JSONが不正な形式の場合
 * @example
 * const params = parseInput('{"title":"Issue title", "summary":"Description"}');
 * console.log(params.title); // "Issue title"
 */
function parseInput(inputJson) {
  const parsed = JSON.parse(inputJson);
  return {
    title: parsed.title,
    summary: parsed.summary,
    model: parsed.model || 'gpt-5',
    outputPath: parsed.output_path || null,
  };
}
```

#### 2. Bash関数呼び出しラッパー

##### callPrepareMetadata

```javascript
/**
 * Bashスクリプトを実行してAI判定用メタデータを準備
 * @param {string} title - Issueタイトル
 * @param {string} summary - Issue概要
 * @returns {Promise<{ai_judgment_prompt: string, commit_types: string, issue_types: string}>}
 * @throws {Error} Bash実行失敗またはJSON解析失敗時
 * @example
 * const metadata = await callPrepareMetadata("タイトル", "サマリー");
 * console.log(metadata.ai_judgment_prompt);
 */
async function callPrepareMetadata(title, summary) {
  const bashScript = `
extract_commit_types() { ... }
build_issue_types_table() { ... }
build_ai_judgment_prompt() { ... }
prepare_metadata() { ... }

prepare_metadata "${title}" "${summary}"
`;

  const result = await Bash({ command: bashScript });
  return JSON.parse(result.output);
}
```

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

##### saveDraftIfNeeded

```javascript
/**
 * 必要に応じてMarkdown下書きをファイルに保存
 * @param {string} draft - Markdown下書き内容
 * @param {string|null} outputPath - 保存先ファイルパス (nullの場合は保存しない)
 * @returns {Promise<string|null>} 保存先の絶対パス (保存しなかった場合はnull)
 * @throws {Error} 保存失敗時 (エラーをキャッチしてnullを返す)
 * @example
 * const path = await saveDraftIfNeeded(draft, "temp/issues/issue-001.md");
 * console.log(path); // "/absolute/path/to/temp/issues/issue-001.md"
 */
async function saveDraftIfNeeded(draft, outputPath) {
  if (!outputPath) { return null; }

  const bashScript = `
save_draft_to_file() {
  local draft="$1"
  local output_path="$2"

  if [[ -z "$output_path" ]]; then
    echo ""
    return 0
  fi

  local dir_path
  dir_path=$(dirname "$output_path")
  if [[ ! -d "$dir_path" ]]; then
    mkdir -p "$dir_path" 2>/dev/null || {
      echo "Error: Failed to create directory: $dir_path" >&2
      return 1
    }
  fi

  echo "$draft" > "$output_path" 2>/dev/null || {
    echo "Error: Failed to write file: $output_path" >&2
    return 1
  }

  realpath "$output_path" 2>/dev/null || echo "$output_path"
}

save_draft_to_file "${draft}" "${outputPath}"
`;

  try {
    const result = await Bash({ command: bashScript });
    return result.output.trim(); // 保存先絶対パス
  } catch (error) {
    console.error('Failed to save draft:', error);
    return null;
  }
}
```

#### 3. LLM統合関数

##### callLLMForAIJudgment

```javascript
/**
 * LLM (Codex/Claude) を呼び出してAI判定を実行
 * @param {string} aiJudgmentPrompt - AI判定用プロンプト
 * @param {string} model - 使用するモデル名 (デフォルト: gpt-5)
 *                         Claude系: claude-*, sonnet, opus, haiku
 *                         OpenAI系: gpt-*, o1-*, o3-*, etc.
 * @returns {Promise<{commit_type: string, issue_type: string, branch_type: string, reasoning: string}>}
 * @throws {Error} Bash実行失敗またはJSON解析失敗時
 * @example
 * const judgment = await callLLMForAIJudgment(prompt, "gpt-4o");
 * console.log(judgment.commit_type); // "feat"
 */
async function callLLMForAIJudgment(aiJudgmentPrompt, model) {
  const bashScript = `
call_llm_with_prompt "\${aiJudgmentPrompt}" "\${model}"
`;

  const result = await Bash({ command: bashScript });
  return JSON.parse(result.output.trim());
}
```

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

#### 4. 出力構築関数

##### buildFinalOutput

```javascript
/**
 * 最終的なJSON出力を構築
 * @param {{commit_type: string, issue_type: string, branch_type: string, reasoning: string}} aiJudgment - AI判定結果
 * @param {string} draft - 生成されたMarkdown下書き
 * @param {string|null} savedTo - 保存先パス (保存していない場合はnull)
 * @returns {{commit_type: string, issue_type: string, branch_type: string, reasoning: string, draft: string, saved_to?: string}}
 * @example
 * const output = buildFinalOutput(judgment, draft, "/path/to/draft.md");
 * console.log(output.commit_type); // "feat"
 */
function buildFinalOutput(aiJudgment, draft, savedTo) {
  const output = {
    commit_type: aiJudgment.commit_type,
    issue_type: aiJudgment.issue_type,
    branch_type: aiJudgment.branch_type,
    reasoning: aiJudgment.reasoning,
    draft: draft,
  };

  if (savedTo) {
    output.saved_to = savedTo;
  }

  return output;
}
```

#### 5. メイン実行関数

##### generateIssue

```javascript
/**
 * JSON入力からGitHub Issue下書き生成処理を実行 (メイン関数)
 * @param {string} inputJson - title, summary, output_path, modelを含むJSON文字列
 * @returns {Promise<{commit_type: string, issue_type: string, branch_type: string, reasoning: string, draft: string, saved_to?: string}>}
 * @throws {Error} いずれかの処理ステップで失敗した場合
 * @example
 * const result = await generateIssue('{"title":"Feature request","summary":"Add logging"}');
 * console.log(result.draft); // "# [Feature] Feature request\n\n..."
 */
async function generateIssue(inputJson) {
  // Step 1: 入力解析
  const { title, summary, outputPath, model } = parseInput(inputJson);

  // Step 2: AI判定プロンプト生成
  const metadata = await callPrepareMetadata(title, summary);

  // Step 3: LLM AI判定
  const aiJudgment = await callLLMForAIJudgment(metadata.ai_judgment_prompt, model);

  // Step 4: テンプレート読み込み
  const templateContent = await callGetTemplateContent(aiJudgment.issue_type);

  // Step 5: 下書き生成プロンプト構築
  const draftPrompt = await callBuildDraftPrompt(title, summary, aiJudgment.issue_type, templateContent);

  // Step 6: LLM下書き生成
  const draft = await callLLMForDraft(draftPrompt, model);

  // Step 7: ファイル保存（output_path指定時）
  const savedTo = await saveDraftIfNeeded(draft, outputPath);

  // Step 8: 最終出力
  return buildFinalOutput(aiJudgment, draft, savedTo);
}
```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
