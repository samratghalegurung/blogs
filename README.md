# Samrat's blog

A Hugo blog using the [Paperesque](https://github.com/capnfabs/paperesque) theme,
written in [Obsidian](https://obsidian.md/) and deployed with GitHub + Cloudflare Workers.

## Structure

```
content/
  _index.md              # homepage: intro sidebar + displayed section
  blog/
    _index.md            # /blog/ section
    *.md                 # standalone blog posts
  gameengine/
    _index.md            # /gameengine/ series hub
    intro.md
  series/
    creating-a-game-engine/
      _index.md          # series intro (rendered by layouts/term.html)
  about.md               # /about/ page
layouts/                 # local overrides of the theme's templates
static/                  # optional favicons / social images
archetypes/              # front matter templates for new posts
hugo.toml                # site configuration
```

The homepage is configured in `content/_index.md` with
`display_section = "gameengine"`, so it shows the game engine posts with the
intro in the sidebar. The top-right links are configured with
`[[params.topmenu]]` in `hugo.toml`.

Posts are grouped into a series through the `series` front matter field. The
theme has no built-in series box, so `layouts/_partials/single-footer-customisation.html`
adds a "Part of the series" link to each post. The series page at
`/series/<series-name>/` is rendered by `layouts/term.html` and shows the series
intro from `content/series/<series-name>/_index.md`.

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
title = 'Intro'
slug = 'intro'                 # optional, defaults to the filename
description = 'Short summary used for SEO and social cards.'
tags = ['odin', 'game-engine']
categories = ['Game Engine']
series = ['Creating a Game Engine']
+++
```

The `series` value must match across posts for them to appear together on the
series page. Section and series lists are ordered by date, oldest first, so the
intro appears before later posts.

### Pages

- **About** — edit `content/about.md`.
- **Homepage** — edit `content/_index.md`. Its content renders in the sidebar;
  `display_section` selects which section's posts appear beside it.

## Obsidian

The repository root is an Obsidian vault (`.obsidian/` is git-ignored). If the
vault feels noisy because it also indexes `themes/` and `public/`, open the
`content/` folder as the vault instead — Hugo only reads Markdown from there.

Mermaid code blocks render as diagrams in the browser. `layouts/_partials/head-customisation.html`
loads Mermaid only on pages that contain a `mermaid` code block, and
`layouts/_default/_markup/render-codeblock-mermaid.html` converts the block into
a diagram element.

## Theme notes

The theme is a git submodule at `themes/paperesque` (branch `mainline`).

Local overrides:

- `layouts/term.html` — adds the series intro above the post list.
- `layouts/list.html` — orders section lists oldest-first by date.
- `layouts/single.html` — chronological Previous/Next links.
- `layouts/404.html` — required for Cloudflare's `not_found_handling = "404-page"`.
- `layouts/_partials/homepage_display_section.html` — fixes the theme's mismatched heading tag.
- `layouts/_partials/head-customisation.html` — conditional Mermaid loader.
- `layouts/_partials/single-footer-customisation.html` — "Part of the series" link.

Paperesque compiles its CSS and JavaScript with Hugo Pipes, so the standard
(non-extended) Hugo build is enough.

The site is pinned to Paperesque's light palette in
`layouts/_partials/head-customisation.html`, so it stays light even when the
operating system is in dark mode. Remove the `:root` block in that file to follow
the OS color scheme again.

## Deploying to Cloudflare (Workers)

This project uses the setup from
<https://gohugo.io/host-and-deploy/deploy-to-cloudflare/>. The files are already
included:

- `wrangler.jsonc` — Worker name, compatibility date, build command, and the
  `public/` asset directory.
- `build.sh` — installs the pinned Hugo version, initializes the theme
  submodule, and builds the site.
- `[caches]` in `hugo.toml` — stores processed images in the Cloudflare build
  cache.

1. Edit `wrangler.jsonc` and set `name` to your Worker project name. Keep
   `compatibility_date` at today's date in `YYYY-MM-DD` format.
2. Commit and push the repository to GitHub.
3. In the Cloudflare dashboard, press **Add** and select **Workers**.
4. Under **Ship something new**, press **Connect GitHub**, authorize Cloudflare,
   and select the repository.
5. On **Set up your application**:
   - **Project name**: the same name used in `wrangler.jsonc`.
   - **Build command**: leave blank.
   - **Deploy command**: `npx wrangler deploy`.
   - Open **Advanced settings** and add `SKIP_DEPENDENCY_INSTALL = true`.
6. Press **Deploy**.
7. Add your custom domain in the Worker's **Settings → Domains & Routes**.
8. Set the real site URL in `hugo.toml` → `baseURL` so absolute links, RSS, and
   social cards use the production domain.

`build.sh` installs Hugo `0.169.0` and runs
`hugo build --gc --minify --cleanDestinationDir`. The theme is a submodule, so
the script also runs `git submodule update --init --recursive`.

The Cloudflare build cache is optional. To enable it, the project needs both
`package.json` and `package-lock.json`, and the cache must be enabled in
**Settings → Build → Build cache**. This project currently has no Node.js
dependencies, so the cache is disabled by default.

For scheduled rebuilds (for example, if you later add `resources.GetRemote`),
see the deploy-hook section of the Hugo documentation linked above.

## Things to customize

- `baseURL` in `hugo.toml` — currently `https://example.com/`.
- `title` / `copyright` / `[params] author` in `hugo.toml`.
- Paperesque expects these files in `static/`: `favicon.ico`, `apple-touch-icon.png`,
  `favicon-32x32.png`, `favicon-16x16.png`, `site.webmanifest`, and
  `safari-pinned-tab.svg`. Add your own, or override
  `layouts/_partials/meta.html` and `layouts/baseof.html` to remove the links.
- Add custom CSS/JS through `layouts/_partials/head-customisation.html`.
- The homepage sidebar in `content/_index.md` and the About page.
- The main column is widened to `67.5rem` (1.5× Paperesque's `45rem`) in
  `layouts/_partials/head-customisation.html`. Change the `67.5rem` value there
  to adjust it.
- Floating footnote margin notes are disabled with `disableMarginNotes = true`
  because the wider column leaves less room for them on laptop screens.
- Paperesque's `fitfigure` shortcode still targets the theme's original column
  width. Normal Markdown images scale automatically; override the shortcode if
  you need its exact resize targets updated.
