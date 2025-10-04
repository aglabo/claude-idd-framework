# 🤝 Contribution Guidelines
<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->

Thank you for considering contributing to the claude-idd-framework project!
We hope your collaboration will help us build a better TypeScript logger library.

<!-- textlint-enable -->

## 📝 How to contribute

### 1. Report an Issue

- Please use [Issues](https://github.com/aglabo/claude-idd-framework/issues) to report bugs or suggest features.
- Add enough details (steps, expected behavior, actual behavior).
- For questions or discussions, feel free to use [Discussions](https://github.com/aglabo/claude-idd-framework/discussions).

### 2. Submit a Pull Request

- Fork the repository and create a new branch like `feature/your-feature-name`.
- Make your changes and commit them clearly.
  - Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
  - Make one commit per change if possible, and rebase later to clean history.
- Write a clear title and description for your pull request.

## 🔧 Project environment

### Setup

```bash
git clone https://github.com/aglabo/claude-idd-framework.git
cd claude-idd-framework
./scripts/install-dev-tools.ps1
./scripts/install-doc-tools.ps1
pnpm install
```

### Testing

When you make changes, please run these commands to ensure everything works:

```bash
# Type checking (highest priority)
pnpm run check:types

# 4-tier test system
pnpm run test:develop      # Unit tests
pnpm run test:functional   # Functional tests
pnpm run test:ci           # Integration tests
pnpm run test:e2e          # E2E tests

# Code quality
pnpm run lint:all

# Format checking
pnpm run check:dprint

# Build verification
pnpm run build
```

### Code style and format

We use these tools to maintain code quality:

- TypeScript: Strict type checking
- ESLint: TypeScript/JavaScript linting
- dprint: Code formatting
- textlint: Documentation proofreading
- markdownlint-cli2: Markdown file linting
- cspell: Spell checking
- lefthook: Git hook management for quality gates

## 📜 Code of Conduct

All contributors must follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## 📚 References

- [GitHub Docs: Setting guidelines for repository contributors](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)

---

## 📬 Create an Issue, PR or Discussion

- [Report a Bug](https://github.com/aglabo/claude-idd-framework/issues/new?template=bug_report.yml)
- [Request a Feature](https://github.com/aglabo/claude-idd-framework/issues/new?template=feature_request.yml)
- [Ask Questions & Discuss](https://github.com/aglabo/claude-idd-framework/discussions)
- [Create a Pull Request](https://github.com/aglabo/claude-idd-framework/compare)

---

## 🤖 Powered by

This project is supported by our AI chat bots:

- **Elpha** - Cool and precise assistant
- **Kobeni** - Gentle and supportive helper
- **Tsumugi** - Cheerful and energetic supporter

Together, we make your contribution experience better ✨
