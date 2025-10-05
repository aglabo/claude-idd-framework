# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**claude-idd-framework** is a documentation-based development framework for AI coding agents (Claude Code). It provides unified development standards, writing rules, custom slash commands, and custom agents to enhance AI-assisted development workflows.

This repository focuses on documentation and configuration rather than traditional code. The primary purpose is to establish consistent development practices across projects using Claude Code.

## Repository Structure

```bash
.claude/
├── commands/             # Custom slash commands for Claude Code
│   ├── idd-commit-message.md  # Generate Conventional Commits messages
│   ├── idd-issue.md           # Create structured GitHub Issues
│   ├── idd-pr.md              # Generate Pull Request drafts
│   ├── sdd.md                 # Spec-Driven Development workflow
│   ├── serena.md              # Serena MCP integration
│   └── validate-debug.md      # 6-stage quality validation workflow

└── agents/               # Custom agents for Claude Code
    ├── bdd-coder.md                # BDD implementation with strict Red-Green-Refactor
    ├── commit-message-generator.md # Conventional Commits message generation
    ├── issue-generator.md          # Structured GitHub Issue drafts
    └── pr-generator.md             # Pull Request draft generation

docs/
├── writing-rules/        # Writing guidelines (generic)
│   ├── 01-writing-rules.md           # Prohibited patterns & project-specific notation
│   ├── 02-frontmatter-guide.md       # Frontmatter metadata rules
│   ├── 03-document-template.md       # Document templates
│   ├── 04-custom-slash-commands.md   # Slash command authoring guide
│   └── 05-custom-agents.md           # Agent authoring guide

└── for-AI-dev-standards/ # AI development standards (project-specific)
    ├── 01-setup-and-onboarding.md         # Environment setup & onboarding
    ├── 02-core-principles.md              # Core principles & MCP mandatory rules
    ├── 03-mcp-tools-usage.md              # MCP tools complete guide
    ├── 04-code-navigation.md              # Project navigation & code search
    ├── 05-bdd-workflow.md                 # BDD workflow & Red-Green-Refactor cycle
    ├── 06-coding-conventions.md           # Coding conventions & MCP patterns
    ├── 07-test-implementation.md          # Test implementation & BDD hierarchy
    ├── 08-quality-assurance.md            # Quality gates & automated checks
    ├── 09-document-quality-assurance.md   # Document quality criteria
    ├── 10-templates-and-standards.md      # Source code templates & JSDoc rules
    └── 11-bdd-implementation-details.md   # atsushifx-style BDD implementation details

configs/                  # Configuration files (reference only)
```

## Essential Commands

### Git Hooks Setup

```bash
# Install lefthook hooks (required after initial clone)
pnpm run prepare
```

### Git Hooks

This repository uses **lefthook** for Git hooks:

- **pre-commit**: Runs gitleaks to prevent committing secrets
- **prepare-commit-msg**: Auto-generates commit message suggestions via `scripts/prepare-commit-msg.sh`
- **commit-msg**: Validates commit messages with commitlint (Conventional Commits format)

## Key Development Practices

### 1. MCP Tools are Mandatory

**ALL development tasks MUST use MCP tools (lsmcp, serena-mcp) for:**

- Understanding project structure and existing code patterns
- Searching symbols, files, and patterns
- Analyzing impact of changes before implementation
- Verifying code integrity after changes

Before editing ANY file, use MCP tools to understand existing patterns and conventions.

### 2. Documentation Standards

#### Writing Rules (Critical)

- **NEVER** use bullet points with bold emphasis (`- **Item**: description`)
  - Use headings instead (`### Item`)
- **Parentheses**: Always use half-width `()` not full-width `()`
- **No excessive decoration**: Avoid emojis, exclamation marks (except README.md overview)
- **No verbose preambles**: Avoid phrases like "以下に説明します" (explained below)
- **Objective tone**: Technical writing should be factual, not subjective

#### Frontmatter Requirements

All Markdown files must include YAML frontmatter with:

```yaml
---
header:
  - src: [filename]
  - @(#): [brief description]
title: claude-idd-framework
description: [document purpose]
version: 1.0.0
created: YYYY-MM-DD
authors:
  - atsushifx
changes:
  - YYYY-MM-DD: [change description]
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

#### Document Quality Checklist

Before completing any documentation work, verify:

1. **Heading hierarchy**: h1 → h2 → h3 (no skipping levels)
2. **Sentence quality**: Clear, concise, appropriate length
3. **Markdown syntax**: Code blocks have language tags, consistent list formatting
4. **Frontmatter**: All required fields present and properly formatted
5. **Project-specific rules**: Half-width parentheses, unified technical terms, proper link format

### 3. Custom Tools Workflow

#### Custom Slash Commands

Use these commands directly in Claude Code:

- `/idd-commit-message`: Generate Conventional Commits messages from staged changes
- `/idd-issue [feature|bug|enhancement|task] "title"`: Create structured GitHub Issues
- `/idd-pr`: Generate Pull Request drafts from branch changes
- `/sdd [init|req|spec|tasks|coding|commit]`: Spec-Driven Development workflow
- `/validate-debug`: Run 6-stage comprehensive quality validation

#### Custom Agents

Launch these agents via the Task tool for specialized workflows:

- `bdd-coder`: Strict BDD implementation (Red-Green-Refactor, 1 message = 1 test)
- `commit-message-generator`: Conventional Commits message generation
- `issue-generator`: Structured GitHub Issue draft creation
- `pr-generator`: Pull Request draft generation

### 4. BDD Development (if applicable to future code)

If implementing code in this repository, follow **atsushifx-style BDD**:

**Mandatory principles:**

- **1 message = 1 test**: Never implement multiple tests in a single iteration
- **3-layer BDD structure**: Given/Feature → When → Then
- **RED-GREEN-REFACTOR**: Must verify RED before GREEN, GREEN before REFACTOR

**BDD hierarchy:**

```typescript
describe('Given: prerequisite/Feature', () => {
  describe('When: action/condition', () => {
    it('Then: [tag] - expected result', () => {
      // Arrange (Given details)
      // Act (When details)
      // Assert (Then details)
    });
  });
});
```

**Required tags for Then clauses:**

- `[正常]`: Normal/success cases
- `[異常]`: Error/exception cases
- `[エッジケース]`: Edge cases/boundary values

### 5. Onboarding Process

When starting work in this repository:

```bash
# 1. Update MCP tool memory with current codebase
"lsmcp のメモリを、現在のコードベース/ドキュメントを読んで更新して"
"serena-mcp のメモリを、現在のコードベース/ドキュメントを読んで更新して"

# 2. Read core documentation
Read docs/writing-rules/01-writing-rules.md
Read docs/for-AI-dev-standards/README.md
Read docs/for-AI-dev-standards/02-core-principles.md

# 3. Verify available custom tools
/help
```

## Architecture Highlights

### Documentation-Centric Design

Unlike typical code repositories, this project's "implementation" consists of:

- **Writing Rules** (`docs/writing-rules/`): Generic documentation guidelines applicable across projects
- **AI Dev Standards** (`docs/for-AI-dev-standards/`): AI-specific development standards, MCP tool usage patterns, BDD workflows
- **Custom Tools** (`.claude/`): Reusable slash commands and agents that extend Claude Code capabilities

### MCP Tool Integration

This framework assumes and requires MCP (Model Context Protocol) tools:

- **lsmcp**: Language Server MCP for symbol search, LSP operations, code navigation
- **serena-mcp**: Structured code analysis, symbol indexing, pattern search

All development workflows are designed around MCP tool usage for understanding existing code before making changes.

### Quality-First Approach

Multiple layers of quality assurance:

1. **Git hooks**: Pre-commit secret scanning, commit message validation
2. **Document quality gates**: Manual checklists in `09-document-quality-assurance.md`
3. **Validation workflows**: `/validate-debug` command for comprehensive checks

## Important Constraints

### Tool Independence

- Documentation must remain tool-agnostic where possible
- Avoid hardcoding specific IDE or editor features
- MCP tools are the exception (explicitly required for AI development)

### File Editing Restrictions

- **DO NOT EDIT**: Generated outputs, cache directories, dependency folders
- **EDIT FREELY**: Documentation in `docs/`, custom tools in `.claude/`, configuration in `configs/`

### Commit Message Format

All commits must follow Conventional Commits:

```
type(scope): subject

body

footer
```

Use `/idd-commit-message` or the `commit-message-generator` agent to generate compliant messages.

## Common Workflows

### Creating New Documentation

1. Read `docs/writing-rules/01-writing-rules.md` for prohibited patterns
2. Use `docs/writing-rules/03-document-template.md` as template
3. Follow frontmatter guide in `docs/writing-rules/02-frontmatter-guide.md`
4. Verify against quality checklist in `docs/for-AI-dev-standards/09-document-quality-assurance.md`

### Creating Custom Slash Commands

1. Read `docs/writing-rules/04-custom-slash-commands.md` for authoring rules
2. Create file in `.claude/commands/[name].md`
3. Include proper frontmatter with `allowed-tools`, `argument-hint`, `description`
4. Implement as Python snippet (standard library only)

### Creating Custom Agents

1. Read `docs/writing-rules/05-custom-agents.md` for authoring rules
2. Create file in `.claude/agents/[name].md`
3. Include frontmatter with `name`, `description`, `tools`, `model: inherit`
4. Structure: Agent Overview → Activation Conditions → Core Functionality → Integration Guidelines

## Troubleshooting

### MCP Tool Errors

```bash
# Verify project root path
"プロジェクトルートのパスを確認して"

# Rebuild symbol index
"lsmcp でシンボルインデックスを再構築して"

# Re-run onboarding
"serena-mcp でオンボーディングを再実行して"
```

### Documentation Quality Issues

1. Read `docs/for-AI-dev-standards/09-document-quality-assurance.md` for quality criteria
2. Read `docs/writing-rules/01-writing-rules.md` for prohibited patterns
3. Manually verify checklist items in quality assurance doc

### Custom Tool Errors

```bash
# Check command help
/[command-name] help

# Read command documentation
Read .claude/commands/[command-name].md
Read .claude/agents/[agent-name].md

# Verify frontmatter configuration
# Check allowed-tools, argument-hint, etc.
```

## See Also

- **README.md**: Basic repository overview
- **docs/for-AI-dev-standards/README.md**: AI development standards index
- **docs/writing-rules/README.md**: Writing guidelines index
- **CONTRIBUTING.md**: Contribution guidelines
