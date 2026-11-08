# Samrat's blog

A Hugo blog using the [Whiteplain](https://github.com/taikii/whiteplain) theme,
written in [Obsidian](https://obsidian.md/) and deployed with GitHub + Cloudflare Pages.

## Structure

```
content/
  _index.md              # home page intro
  blog/
    _index.md            # /blog/ section
    *.md                 # standalone blog posts
  gameengine/
    _index.md            # /gameengine/ series hub
    write-a-game-engine.md
  about/
    _index.md            # /about/ page
layouts/                 # local overrides of the theme's templates
static/                  # optional favicon / social share image
archetypes/              # front matter templates for new posts
hugo.toml                # site configuration
```

Posts are grouped into a series through the `series` front matter field. The
theme automatically renders a series box on each post and generates a page at
`/series/<series-name>/`. The `/gameengine/` section is the curated hub for the
game engine series.

The home page lists all posts. `/blog/` is available as a container for
standalone posts but is intentionally not in the header navigation. The theme's
demo uses the same pattern with its `posts/` folder.

## Local development

```bash
hugo server -D
```

Open <http://localhost:1313/>. `-D` includes drafts.

Build the production site with:

```bash
hugo --gc --minify --cleanDestinationDir
```

The output is written to `public/` (git-ignored).

## Adding content

New standalone blog post:

```bash
hugo new content blog/my-post.md
```

New post in the game engine series:

```bash
hugo new content gameengine/02-renderer.md
```

Both commands pick up the matching archetype in `archetypes/`. Posts start as
`draft = true`; change it to `false` (or keep using `hugo server -D`) when ready
to publish.

### Front matter

```toml
+++
date = '2026-11-08T18:14:11+05:45'
draft = false
title = 'Write a Game Engine'
slug = 'write-a-game-engine'   # optional, defaults to the filename
description = 'Short summary used for SEO and social cards.'
tags = ['odin', 'game-engine']
categories = ['Game Engine']
series = ['Creating a Game Engine']
weight = 1                     # controls ordering inside the section
+++
```

The `series` value must match across posts for them to appear together in the
series box and on the series page.

### Pages

- **About** — edit `content/about/_index.md`. Author details and social links come
  from `[params.author]` in `hugo.toml`.

## Obsidian

The repository root is an Obsidian vault (`.obsidian/` is git-ignored). If the
vault feels noisy because it also indexes `themes/` and `public/`, open the
`content/` folder as the vault instead — Hugo only reads Markdown from there.

Mermaid code blocks render as diagrams in the browser. `layouts/partials/head_custom.html`
loads Mermaid only on pages that contain a `mermaid` code block, and
`layouts/_default/_markup/render-codeblock-mermaid.html` converts the block into
a diagram element.

## Theme notes

The theme is a git submodule at `themes/whiteplain`.

`layouts/_default/single.html` is a local override of the theme's single-page
template. It fixes the series lookup: current Hugo versions keep spaces in
taxonomy keys, while the upstream theme assumes hyphenated keys. Keep this
override in mind when updating the theme.

## Deploying to Cloudflare Pages

1. Push this repo to GitHub.
2. In the Cloudflare dashboard, go to **Workers & Pages → Create → Pages →
   Connect to Git** and select the repo.
3. Use these build settings:

   | Setting | Value |
   | --- | --- |
   | Framework preset | Hugo |
   | Build command | `git submodule update --init --recursive && hugo --gc --minify` |
   | Build output directory | `public` |
   | Root directory | `/` |

4. Add an environment variable `HUGO_VERSION = 0.169.0` (or whatever version
   you use locally).
5. Set the real domain in `hugo.toml` → `baseURL` before the first production
   deploy. Cloudflare preview URLs will still work, but absolute links, RSS, and
   social cards use `baseURL`.

The theme is a git submodule, hence the `git submodule update` step in the build
command.

## Things to customize

- `baseURL` in `hugo.toml` — currently `https://example.com/`.
- `title` / `copyright` / `[params.author]` in `hugo.toml`.
- `static/favicon.ico` and `static/images/share.png` if you want a favicon and
  social card; then uncomment `favicon` / `logo` in `hugo.toml`.
- `static/css/custom.css` and `static/js/custom.js` for theme overrides.
- The home intro in `content/_index.md` and the About page.
