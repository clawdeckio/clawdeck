# Contributing to PokéDeck

Thank you for your interest in contributing to PokéDeck! 🦞

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/pokedeck.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Run tests: `bin/ci`
6. Commit with a clear message
7. Push and open a Pull Request

## Development Setup

```bash
brew install ruby@3.3
export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"
bundle install
bin/rails db:prepare
bin/dev
```

For the full setup flow (including version-manager options), see `DEV_SETUP.md`.

## Code Style

- Follow existing code patterns
- Run `bin/rubocop` before committing
- Write tests for new features

## Pull Request Guidelines

- Keep PRs focused on a single change
- Update documentation if needed
- Add tests for new functionality
- Reference related issues in the PR description

## Reporting Issues

- Search existing issues first
- Include steps to reproduce
- Include Ruby/Rails versions
- Include relevant logs or screenshots

## Questions?

Open a Discussion or join our Discord.

---

Thank you for helping make PokéDeck better! 🦞
