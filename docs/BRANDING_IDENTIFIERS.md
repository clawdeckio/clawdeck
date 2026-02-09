# Branding vs Identifiers (PokéDeck)

This codebase is **branded** as **PokéDeck** (user-facing strings, page titles, marketing copy, docs).

However, there are still many internal identifiers that intentionally remain `clawdeck` / `ClawDeck` for now.

## Quick Rule

If it is visible to end users, use **PokéDeck**.
If it is an infrastructure identifier (module names, service labels, filesystem paths, DB names, domains), keep existing `clawdeck` values unless a dedicated migration is planned.

## Why keep `clawdeck` identifiers?

Renaming infra identifiers can be a breaking migration (domains, paths, service labels, database names, secrets,
SSL certs, deploy scripts, etc.). The current approach is:

- **Phase 1 (safe):** rebrand *user-facing* strings to PokéDeck.
- **Phase 2 (breaking):** optionally migrate infrastructure identifiers in a coordinated release.

## What should be PokéDeck now

Examples:

- Website/app page titles and `<meta>` application name
- Manifest `name` / `short_name`
- README + docs language
- Seeded/demo board names
- UI labels and copy

The guardrail script `script/check_user_facing_branding.sh` should stay green.

## What may stay ClawDeck for now

Examples (non-exhaustive):

- Rails module name: `module ClawDeck` (namespace)
- Service labels and process names (e.g. launchd `ai.openclaw.clawdeck`)
- Filesystem paths (`/var/www/clawdeck`, `/var/log/clawdeck`)
- Database names/users
- Domains/URLs (until a domain migration is planned)
- `clawdeck.io` remains the canonical public base URL until a coordinated `pokedeck` domain cutover
- Self-hosters can override generated public links with `PUBLIC_BASE_URL`

## When to migrate identifiers

Do this only when you are ready to handle the full blast radius:

- DNS + TLS certificates
- deploy scripts + service managers
- environment variables + secrets
- internal API URL generation defaults

Until then: treat `clawdeck` identifiers as implementation details, and keep PokéDeck as the user-facing brand.
