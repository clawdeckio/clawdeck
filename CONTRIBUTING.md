# Contributing to PokéDeck

Thank you for your interest in contributing to PokéDeck! 🦞

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/clawdeck.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Run tests: `bin/ci`
6. Commit with a clear message
7. Push and open a Pull Request

## Branding and Identifiers

- Use **PokéDeck** for user-facing copy (UI text, docs prose, examples shown to users).
- Keep infrastructure identifiers as `clawdeck*` for now (repo slug, filesystem paths, DB names, service labels).
- Keep canonical external URL examples as `https://clawdeck.io` until an intentional domain cutover.
- See [`docs/BRANDING_IDENTIFIERS.md`](docs/BRANDING_IDENTIFIERS.md) for full policy.

## Development Setup

```bash
bundle install
bin/rails db:prepare
bin/dev
```

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
