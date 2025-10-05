---
header:
  - src: agent-validation-examples.md
  - @(#): Agent Validation Examples
title: agla-logger
description: カスタムエージェント検証実装の具体例とサンプルコード
version: 1.0.0
created: 2025-10-05
authors:
  - atsushifx
changes:
  - 2025-10-05: 初版作成 - custom-agents.md から検証コード移動
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## カスタムエージェント検証実装例

このドキュメントは、Claude Code 向けカスタムエージェントの品質検証を実装するための具体的なコード例を提供します。
Python 標準ライブラリのみを使用し、外部依存を最小化しています。

## 検証プロセス概要

カスタムエージェントの品質検証は以下の 3 つのフェーズで構成されます:

1. Phase 1: 基本検証 (ファイル存在・フロントマター存在)
2. Phase 2: フロントマター検証 (YAML 構文・必須フィールド)
3. Phase 3: エージェント固有検証 (ag-logger 標準準拠・名前一貫性)

## Phase 1: 基本検証

### ファイル存在確認

エージェントファイルが存在するかを確認します。

```python
import os

file_path = ".claude/agents/[agent-file].md"
if not os.path.exists(file_path):
    print("Error: Agent file not found")
    exit(1)

print(f"✓ Agent file found: {file_path}")
```text

実行方法:

```bash
python -c "
import os
file_path = '.claude/agents/bdd-coder.md'
if not os.path.exists(file_path):
    print('Error: Agent file not found')
else:
    print(f'✓ Agent file found: {file_path}')
"
```text

期待される出力:

```text
✓ Agent file found: .claude/agents/bdd-coder.md
```text

### フロントマター存在確認

ファイルが正しくフロントマターで始まっているかを確認します。

```python
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if not content.startswith('---'):
    print("Error: Frontmatter not found")
    exit(1)

print("✓ Frontmatter found")
```text

実行方法:

```bash
python -c "
with open('.claude/agents/bdd-coder.md', 'r', encoding='utf-8') as f:
    content = f.read()
if not content.startswith('---'):
    print('Error: Frontmatter not found')
else:
    print('✓ Frontmatter found')
"
```text

期待される出力:

```text
✓ Frontmatter found
```text

## Phase 2: フロントマター検証

### YAML 構文検証

フロントマター部分の YAML 構文が正しいかを検証します。

```python
import yaml

# フロントマター抽出 (簡易版)
frontmatter_content = content.split('---')[1]

try:
    frontmatter = yaml.safe_load(frontmatter_content)
    print("✓ YAML syntax valid")
except yaml.YAMLError as e:
    print(f"Error: Invalid YAML syntax - {e}")
    exit(1)
```text

実行方法:

```bash
python << 'EOF'
import yaml

with open('.claude/agents/bdd-coder.md', 'r', encoding='utf-8') as f:
    content = f.read()

frontmatter_content = content.split('---')[1]

try:
    frontmatter = yaml.safe_load(frontmatter_content)
    print("✓ YAML syntax valid")
except yaml.YAMLError as e:
    print(f"Error: Invalid YAML syntax - {e}")
EOF
```text

期待される出力:

```text
✓ YAML syntax valid
```text

### 必須フィールド確認

Claude Code 必須フィールドとプロジェクト必須フィールドの存在を確認します。

```python
# Claude Code 必須フィールド
required_claude_fields = ['name', 'description']
# ag-logger プロジェクト必須フィールド
required_project_fields = ['title', 'version', 'created', 'authors']

# Claude Code フィールド確認
for field in required_claude_fields:
    if field not in frontmatter:
        print(f"Error: Missing Claude Code field: {field}")
        exit(1)
    print(f"✓ Claude Code field found: {field}")

# プロジェクトフィールド確認
for field in required_project_fields:
    if field not in frontmatter:
        print(f"Error: Missing project field: {field}")
        exit(1)
    print(f"✓ Project field found: {field}")
```text

実行方法:

```bash
python << 'EOF'
import yaml

with open('.claude/agents/bdd-coder.md', 'r', encoding='utf-8') as f:
    content = f.read()

frontmatter_content = content.split('---')[1]
frontmatter = yaml.safe_load(frontmatter_content)

required_claude_fields = ['name', 'description']
required_project_fields = ['title', 'version', 'created', 'authors']

for field in required_claude_fields:
    if field not in frontmatter:
        print(f"Error: Missing Claude Code field: {field}")
    else:
        print(f"✓ Claude Code field found: {field}")

for field in required_project_fields:
    if field not in frontmatter:
        print(f"Error: Missing project field: {field}")
    else:
        print(f"✓ Project field found: {field}")
EOF
```text

期待される出力:

```text
✓ Claude Code field found: name
✓ Claude Code field found: description
✓ Project field found: title
✓ Project field found: version
✓ Project field found: created
✓ Project field found: authors
```text

## Phase 3: エージェント固有検証

### model フィールド検証 (ag-logger 標準)

ag-logger プロジェクトでは、model フィールドは常に `inherit` である必要があります。

```python
model_value = frontmatter.get('model', 'inherit')
if model_value != 'inherit':
    print(f"Warning: Model should be 'inherit' for ag-logger project, found: {model_value}")
else:
    print(f"✓ Model field is 'inherit' (ag-logger standard)")
```text

実行方法:

```bash
python << 'EOF'
import yaml

with open('.claude/agents/bdd-coder.md', 'r', encoding='utf-8') as f:
    content = f.read()

frontmatter_content = content.split('---')[1]
frontmatter = yaml.safe_load(frontmatter_content)

model_value = frontmatter.get('model', 'inherit')
if model_value != 'inherit':
    print(f"Warning: Model should be 'inherit' for ag-logger project, found: {model_value}")
else:
    print(f"✓ Model field is 'inherit' (ag-logger standard)")
EOF
```text

期待される出力:

```text
✓ Model field is 'inherit' (ag-logger standard)
```text

### 名前一貫性確認

ファイル名とエージェント名 (name フィールド) が一致しているかを確認します。

```python
import os

filename = os.path.basename(file_path).replace('.md', '')
agent_name = frontmatter.get('name', '')

if filename != agent_name:
    print(f"Error: Filename '{filename}' does not match agent name '{agent_name}'")
    exit(1)

print(f"✓ Filename matches agent name: {agent_name}")
```text

実行方法:

```bash
python << 'EOF'
import os
import yaml

file_path = '.claude/agents/bdd-coder.md'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

frontmatter_content = content.split('---')[1]
frontmatter = yaml.safe_load(frontmatter_content)

filename = os.path.basename(file_path).replace('.md', '')
agent_name = frontmatter.get('name', '')

if filename != agent_name:
    print(f"Error: Filename '{filename}' does not match agent name '{agent_name}'")
else:
    print(f"✓ Filename matches agent name: {agent_name}")
EOF
```text

期待される出力:

```text
✓ Filename matches agent name: bdd-coder
```text

## 統合検証スクリプト

すべての検証フェーズを統合したスクリプト例:

```python
import os
import yaml
import sys

def validate_agent(file_path):
    """カスタムエージェントファイルの包括的検証"""

    # Phase 1: 基本検証
    print("=== Phase 1: 基本検証 ===")

    if not os.path.exists(file_path):
        print(f"✗ Error: Agent file not found: {file_path}")
        return False
    print(f"✓ Agent file found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if not content.startswith('---'):
        print("✗ Error: Frontmatter not found")
        return False
    print("✓ Frontmatter found")

    # Phase 2: フロントマター検証
    print("\n=== Phase 2: フロントマター検証 ===")

    try:
        frontmatter_content = content.split('---')[1]
        frontmatter = yaml.safe_load(frontmatter_content)
        print("✓ YAML syntax valid")
    except (IndexError, yaml.YAMLError) as e:
        print(f"✗ Error: Invalid YAML - {e}")
        return False

    required_claude_fields = ['name', 'description']
    required_project_fields = ['title', 'version', 'created', 'authors']

    for field in required_claude_fields:
        if field not in frontmatter:
            print(f"✗ Error: Missing Claude Code field: {field}")
            return False
        print(f"✓ Claude Code field found: {field}")

    for field in required_project_fields:
        if field not in frontmatter:
            print(f"✗ Error: Missing project field: {field}")
            return False
        print(f"✓ Project field found: {field}")

    # Phase 3: エージェント固有検証
    print("\n=== Phase 3: エージェント固有検証 ===")

    model_value = frontmatter.get('model', 'inherit')
    if model_value != 'inherit':
        print(f"⚠ Warning: Model should be 'inherit' for ag-logger project, found: {model_value}")
    else:
        print(f"✓ Model field is 'inherit' (ag-logger standard)")

    filename = os.path.basename(file_path).replace('.md', '')
    agent_name = frontmatter.get('name', '')

    if filename != agent_name:
        print(f"✗ Error: Filename '{filename}' does not match agent name '{agent_name}'")
        return False
    print(f"✓ Filename matches agent name: {agent_name}")

    print("\n=== 検証結果 ===")
    print("✓ All validations passed")
    return True

# 使用例
if __name__ == "__main__":
    agent_file = sys.argv[1] if len(sys.argv) > 1 else ".claude/agents/bdd-coder.md"
    success = validate_agent(agent_file)
    sys.exit(0 if success else 1)
```text

実行方法:

```bash
# 統合スクリプトとして保存
cat > validate_agent.py << 'EOF'
[上記のスクリプトをここに貼り付け]
EOF

# 実行
python validate_agent.py .claude/agents/bdd-coder.md
```text

期待される出力:

```text
=== Phase 1: 基本検証 ===
✓ Agent file found: .claude/agents/bdd-coder.md
✓ Frontmatter found

=== Phase 2: フロントマター検証 ===
✓ YAML syntax valid
✓ Claude Code field found: name
✓ Claude Code field found: description
✓ Project field found: title
✓ Project field found: version
✓ Project field found: created
✓ Project field found: authors

=== Phase 3: エージェント固有検証 ===
✓ Model field is 'inherit' (ag-logger standard)
✓ Filename matches agent name: bdd-coder

=== 検証結果 ===
✓ All validations passed
```text

## 検証レポート形式

検証結果を構造化されたレポートとして出力する例:

```python
def generate_validation_report(file_path, validation_results):
    """検証レポート生成"""
    from datetime import datetime

    print("=" * 50)
    print("Agent Quality Validation Report")
    print("=" * 50)
    print(f"File: {file_path}")
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    checks = [
        ("Frontmatter Validation", validation_results.get('frontmatter', False)),
        ("Structure Validation", validation_results.get('structure', False)),
        ("Naming Convention Validation", validation_results.get('naming', False)),
        ("ag-logger Standard Compliance", validation_results.get('ag_logger', False)),
        ("Documentation Completeness", validation_results.get('docs', False)),
    ]

    for check_name, passed in checks:
        status = "✓" if passed else "✗"
        print(f"[{status}] {check_name}")

    print()
    all_passed = all(result for _, result in checks)
    print(f"Overall Status: {'PASS' if all_passed else 'FAIL'}")
    print(f"Issues Found: {sum(1 for _, result in checks if not result)}")
    print("=" * 50)
```text

## 注意事項

### 前提条件

- Python 3.6 以上
- PyYAML ライブラリ (標準ライブラリではないが、一般的にインストール済み)

### 制約事項

- フロントマター抽出は簡易実装のため、複雑な構造には対応していません
- エラーハンドリングは基本的なもののみ実装しています
- 本番環境での使用前に、適切なテスト・検証を実施してください

### カスタマイズポイント

- required_claude_fields: プロジェクト要件に応じて追加
- required_project_fields: ag-logger 固有要件の調整
- model 値検証: 他のプロジェクトでは不要な場合がある

## See Also

- [カスタムエージェント記述ルール](../writing-rules/custom-agents.md): エージェント作成の基本ルール
- [品質保証システム](../rules/03-quality-assurance.md): プロジェクト全体の品質基準
- [Writing Examples README](README.md): Examples ディレクトリ全体概要

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
