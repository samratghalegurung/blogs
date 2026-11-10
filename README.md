# Samrat's blog

A Hugo blog using the [Black & Light](https://github.com/davidhampgonsalves/hugo-black-and-light-theme)
theme, written in [Obsidian](https://obsidian.md/) and deployed with GitHub + Cloudflare Workers.

## Structure

```
content/
  _index.md              # homepage intro
  blog/
    _index.md            # /blog/ section
    *.md                 # standalone blog posts
  gameengine/
    _index.md            # /gameengine/ series hub
    *.md                 # series posts
  series/
    creating-a-game-engine/
      _index.md          # series intro
  about.md               # /about/ page
layouts/                 # local overrides of the theme's templates
static/                  # optional favicons / social images
archetypes/              # front matter templates for new posts
hugo.toml                # site configuration
```

The homepage lists every post in a content section, oldest first. Root-level
pages such as `about.md` are excluded from that list.

Posts are grouped into a series through the `series` front matter field. The
post template adds a "Part of the series" link, and the series page at
`/series/<series-name>/` lists its posts in chronological order.

## Local development

```bash
hugo server -D
```

Open <http://localhost:1313/>. `-D` includes drafts.

Build the production site with:

```bash
hugo build --gc --minify --cleanDestinationDir
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

### Images

Images pasted into `content/gameengine/` next to `_index.md` are published at
the section root, e.g. `/gameengine/Pasted%20image%2020261110144359.png`. From a
post at `/gameengine/<post>/`, reference them with that absolute path.

For automatic relative image links, convert the post into a page bundle:

```text
content/gameengine/draw/
  index.md
  Pasted image 20261110144359.png
```

Then `![](Pasted%20image%2020261110144359.png)` works because Hugo publishes the
image alongside the page.

### Pages

- **About** — edit `content/about.md`.
- **Homepage** — edit `content/_index.md`.

## Obsidian

The repository root is an Obsidian vault (`.obsidian/` is git-ignored). If the
vault feels noisy because it also indexes `themes/` and `public/`, open the
`content/` folder as the vault instead — Hugo only reads Markdown from there.

Mermaid code blocks render as diagrams in the browser. `layouts/partials/header.html`
loads Mermaid only on pages that contain a `mermaid` code block, and
`layouts/_default/_markup/render-codeblock-mermaid.html` converts the block into
a diagram element.

## Theme notes

The theme is a git submodule at `themes/black-and-light`. It is licensed under
GPL-3.0; check the license before redistributing the theme code itself.

Local overrides:

- `layouts/partials/header.html` — forces the light palette, fixes the language
  attribute, adds favicons, and conditionally loads Mermaid.
- `layouts/index.html` — homepage intro and chronological post list.
- `layouts/_default/list.html` — section and term lists (oldest first).
- `layouts/_default/terms.html` — taxonomy term overview pages.
- `layouts/_default/single.html` — series link and chronological Previous/Next.
- `layouts/_default/_markup/render-codeblock-mermaid.html` — Mermaid block output.

Black & Light is text-oriented and caps the body at `700px`. To widen it, add a
`body { max-width: ... }` rule after the theme styles in
`layouts/partials/header.html`.

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
8. Set the real site URL in `hugo.toml` → `baseURL` **or** add a Cloudflare
   environment variable `BASE_URL = https://your-domain/`. `build.sh` passes
   `BASE_URL` to Hugo as `--baseURL` when it is set.

`build.sh` installs Hugo `0.169.0` and runs
`hugo build --gc --minify --cleanDestinationDir`. The theme is a submodule, so
the script also runs `git submodule update --init --recursive`.

The Cloudflare build cache is optional. To enable it, the project needs both
`package.json` and `package-lock.json`, and the cache must be enabled in
**Settings → Build → Build cache**. This project currently has no Node.js
dependencies, so the cache is disabled by default.

## Things to customize

- `baseURL` in `hugo.toml` — set to `https://samratghale.com.np/`. You can
  override it for a preview by setting `BASE_URL` in Cloudflare, since
  `build.sh` passes it through. Navigation links are relative, but canonical
  URLs, RSS, and the sitemap use `baseURL`.
- `title`, `author`, `copyright`, and `[params] sitename` / `description` in
  `hugo.toml`.
- The header menu is `[[menu.main]]` in `hugo.toml`.
- Set `disableWebFonts = true` in `[params]` to avoid loading Google Fonts.
- Replace the favicons in `static/` if you want your own.
- The homepage intro in `content/_index.md` and the About page.
