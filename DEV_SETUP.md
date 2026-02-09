# Developer Setup

Use Ruby 3.3.x for this repo. macOS system Ruby 2.6 cannot run Rails 8.1 in this project.

## Requirements

- Ruby `3.3.1` (or newer `3.3.x`)
- Bundler `2.5.9` (pinned in `Gemfile.lock`)
- PostgreSQL

## Preferred: Homebrew Ruby (macOS arm64)

```bash
brew install ruby@3.3
echo 'export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
ruby -v
bundle -v
```

You can also use a version manager if you prefer:

### Option A: rbenv

```bash
brew install rbenv ruby-build
eval "$(rbenv init - zsh)"
rbenv install 3.3.1
```

`rbenv` will use the repo's `.ruby-version` automatically.

### Option B: mise

```bash
brew install mise
mise install ruby@3.3.1
```

## Project bootstrap

```bash
bin/setup --skip-server
```

`bin/setup` will:
- verify Ruby version is new enough,
- install Bundler `2.5.9` if missing,
- run `bundle install`,
- run `bin/rails db:prepare`.

## Daily commands

```bash
bundle install
bin/rails db:migrate
bin/rails test
```
