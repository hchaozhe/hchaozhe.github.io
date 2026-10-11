# Jekyll theme

Adapted from Flexible-Jekyll [github repo](https://github.com/artemsheludko/flexible-jekyll)

## Local preview

The site is built by GitHub Pages on every push to `master`. The `Gemfile` pins the
same `github-pages` gem, so the local preview matches what goes live.

### One-time setup

- **Windows:** install Ruby+Devkit from [rubyinstaller.org](https://rubyinstaller.org/)
  (run `ridk install` when prompted), then use **Git Bash** for the commands below.
- **macOS:** install Ruby with Homebrew (`brew install ruby`) and put it on your `PATH`
  as Homebrew instructs. The system Ruby is too old.

Then, from the repo root:

```sh
gem install bundler
bundle install
```

### Preview

```sh
./scripts/preview.sh            # http://localhost:4000, reloads the browser on save
./scripts/preview.sh --drafts   # also show _drafts/ and future-dated posts
./scripts/preview.sh --build    # one-off build into _site/ to inspect the output
```

Changes to `_config.yml` need a restart (Ctrl+C, then run again).

### Writing posts: one sentence per line

In `_posts/`, each sentence goes on its own line: a line ends if and only if a sentence
ends (`。！？`, or `. ! ?` in English). Leave a blank line between paragraphs as usual.
Lists, headings, tables, quotes, code and HTML are left alone. The layouts drop the
line breaks after Chinese punctuation, so the rendered page has no stray spaces.

```sh
ruby scripts/sentence-lines.rb           # reformat all posts
ruby scripts/sentence-lines.rb --check   # only report posts that need it
```

A pre-commit hook rejects posts that break the rule. Enable it once per clone:

```sh
git config core.hooksPath scripts/hooks
```

### Publish

Preview the site, then commit and push to `master`. GitHub Pages rebuilds the site automatically.

### Styles

`assets/css/main.css` is the stylesheet the site loads. The `assets/css/scss/` sources
were compiled into it by the original theme's gulp pipeline (`gulpfile.js`), which
depends on an outdated Node toolchain. Edit `main.css` directly for now.

## License

GNU General Public License v3.0
