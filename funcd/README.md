# funcd-rauthy

rauthy with every user-facing page in funcd's look. The `funcd-ui` branch is an upstream tag
(now `v0.37.2`) plus this series; nothing else of rauthy is forked.

## What the series changes

- **Design layer**: `frontend/src/css/funcd.css` holds funcd-frontend's tokens (`mantine.theme.ts`:
  primary `#6c5ce7`, primary-tinted neutrals, radius scale; `theme.css`: the page tint) and re-expresses
  every rauthy theme variable in them, so the admin UI gets funcd colors too. Roboto ships self-hosted.
- **Shell**: `frontend/src/lib/funcd/FuncdAuthShell.svelte` draws funcd's header (the mark and the
  wordmark in the text color, as on the docs site; a feature pill for language and theme) and one card.
- **Pages in the shell**: login (`oidc/authorize`), registration, password-reset request, password set /
  activation, e-mail change confirmation, home, logout, device authorization, login revoke, the error
  pages (`lib/Error.svelte`), the OIDC and upstream-provider callbacks, and the account dashboard. The
  dashboard is restyled from its route, so `lib/account` stays upstream's.
- **E-mails**: written in [MJML](https://mjml.io) under `funcd/email/src` and compiled into rauthy's
  askama templates (`templates/email/*.html`, see "Mails" below). The client theme rauthy passes in is
  not used: the values are written out, since mail clients drop CSS variables. The funcd lockup is a PNG
  served from the issuer (`<issuer>assets/funcd-email.png`); a mail client that cannot reach the issuer
  shows its alt text. The subject and heading prefix and the sender name are config: set
  `EMAIL_SUB_PREFIX` and `SMTP_FROM`.
- **Left as upstream**: the admin UI (layout kept, colors remapped), the FedCM test page, the backend's
  plain 429 and "blocked" pages, and the admin's custom mails (their own inline HTML).

Each page keeps upstream's instance `<script>` byte-identical; funcd's imports sit in a separate
`<script module>`. Auth logic is never forked, and a rebase conflicts only on markup.

## The guard

```bash
./funcd/check.sh v0.37.2
```

It fails on a changed file outside the allowlist, on any drift of a page's instance script from the
tag, and on an added static asset without `.br`/`.gz` siblings (rauthy serves the precompressed file
to browsers and returns 404 without it).

## Build

The backend builds on Linux only. Node 22 builds the UI, as upstream's `node:22` image does.

```bash
just build-wasm
just build-ui
cargo build --release
```

## Image

`funcd/image/build.sh` builds `ghcr.io/pyvvo/funcd-rauthy:<rauthy version>-funcd.<commit>` the way
upstream's `just build` does: in a builder container (`funcd/image/builder.Dockerfile`) it builds the UI
and the release binaries for amd64 and arm64, then wraps them in upstream's distroless runtime image with
funcd's labels (`funcd/image/Dockerfile`). Run it on a committed tree; it needs a Docker daemon with
enough memory for the release profile's full LTO (a 16 GiB VM is plenty).

```bash
DOCKER="docker --context colima-funcd-build" funcd/image/build.sh
DOCKER="docker --context colima-funcd-build" funcd/image/build.sh --push
```

Without `--push` it loads the build host's platform into Docker. With it, each platform's image is
pushed by digest and `funcd/image/index.sh` tags one index of both; that needs `docker login ghcr.io`
with a token that has `write:packages`. `ARCH=amd64` or `ARCH=arm64` builds one platform only: loading
needs the host's, and a push of one platform leaves the tag to `index.sh` and writes its digest to
`$DIGEST_DIR/<arch>`. The script skips the UI build when the committed frontend sources are unchanged
since the last one, so a rebuild does not relink the binaries.

## Licence

rauthy is licensed under Apache-2.0 (`LICENSE`), which allows this modified version to be published
and distributed. In return, every upstream file the fork changes carries a notice saying so, the image
ships `LICENSE` and `licenses/`, and the name "rauthy" only says where this comes from: funcd-rauthy is
not rauthy's official distribution and is not endorsed by its author. The self-hosted Roboto fonts are
under the SIL Open Font License 1.1 (`funcd/licenses/Roboto-OFL-1.1.txt`). The funcd mark and
wordmark are The funcd Authors'.

## Releases and CI

Releases come from GitHub Actions, as in the other funcd repositories; a local build is only for
development.

- **`funcd-ci.yml`**, on PRs and on `funcd-ui`: the guard (with the mail templates' freshness), the UI
  build, prettier and svelte-check on the fork's frontend files (upstream's own files carry type errors
  at the tag), and upstream's contract tests.
- **`funcd-pr-title.yml`**: PRs are squash-merged with their title as the commit message, so the title
  must be a conventional commit.
- **`funcd-release.yml`**: release-please (`funcd/release-please-config.json`) keeps a release PR open
  on `funcd-ui`. Merging it tags `funcd-rauthy-v<version>`, writes `funcd/CHANGELOG.md`, and runs
  `funcd-image.yml`.
- **`funcd-image.yml`**: builds each platform at the same time on a runner of its own architecture
  (`ubuntu-latest`, `ubuntu-24.04-arm`) with `ARCH=<arch> funcd/image/build.sh --push`, then tags
  `ghcr.io/pyvvo/funcd-rauthy:<version>` with `funcd/image/index.sh`. To try a change to the build
  without a release, run it by hand: `gh workflow run funcd-image.yml -f version=<tag> -f ref=<ref>`.

Release tags carry the `funcd-rauthy-` prefix so they never meet upstream's `v<version>` tags. After a
rebase onto a new upstream tag, the last release commit is no longer in the history: set
`last-release-sha` in the release-please config to the new upstream tag's commit for the next release.

## Develop

The backend runs in a container built from `funcd/dev/Dockerfile`, the UI in vite with hot reload.
The dev config sends mail, and rauthy stops when no SMTP server answers, so mailpit runs beside it.

```bash
docker build -t funcd-rauthy-dev funcd/dev
docker network create rauthy-net
docker run -d --name rauthy-mail --network rauthy-net --network-alias mailpit -p 8025:8025 axllent/mailpit
docker run --rm -v "$PWD":/work -v rauthy-target:/target -e CARGO_TARGET_DIR=/target -w /work funcd-rauthy-dev cargo build
docker run -d --name rauthy-dev --network rauthy-net -p 8080:8080 -e SMTP_URL=mailpit -e SMTP_PORT=1025 \
  -v "$PWD":/work -v rauthy-target:/target -w /work funcd-rauthy-dev /target/debug/rauthy serve
cd frontend && npm ci && npm run dev
```

Open `http://localhost:5173/auth/v1/account`; the dev admin is in `config.toml`, and mailpit shows the
mails at `http://localhost:8025`. Vite proxies
`/auth/v1/dev` by prefix, so `/auth/v1/device` comes from the backend's build: run `just build-ui`
and rebuild the backend to see a change there.

## Mails

Each mail is one MJML document in `funcd/email/src`, with the shared head (fonts, colors, button styles)
and the logo in `src/partials`. `build.mjs` compiles them with MJML in strict mode and without web-font
links, checks that every askama `{{ }}` and `{% %}` survives, and writes `templates/email/<name>.html`.
The generated files are committed, so the backend builds without Node; never edit them by hand.

```bash
cd funcd/email
npm ci
npm run build
```

The logo is `funcd/email/logo.svg` (funcd-frontend's mark and wordmark), rendered at 3x into
`frontend/static/assets/funcd-email.png` (`resvg --zoom 3 funcd/email/logo.svg <png>`). It carries a
thin white halo: in dark mode, Outlook turns the mail's backgrounds grey but never recolors images, so a
plain black logo drops to about 2.8:1 contrast there (checked in Outlook.com on 2026-11-18); on the
light tint the halo does not show.

Fields that can be empty are wrapped in `<mj-raw>{%- if !field.is_empty() -%}</mj-raw>`, so they leave
no gap. The text mails (`*.txt`) and `base.html` stay upstream's; no funcd mail extends `base.html`.
When upstream changes a mail, port the change to its `.mjml` file: the backend build then checks every
field against the Rust struct.

## Checks

```bash
cd frontend
npm run check
node --test tests/password-reset.node.mjs
node --test tests/webauthn-auth.node.mjs
node --test tests/redirect-uri.node.mjs
```

`npm run check` reports 28 errors in upstream files on `v0.37.2` too; the series adds none. The
contract tests need a Chromium: `npx playwright install`, or set `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`
to an installed Chrome.

## Rebase on a new upstream tag

```bash
git fetch upstream --tags
git rebase --onto <new-tag> v0.37.2 funcd-ui
./funcd/check.sh <new-tag>
```

Resolve conflicts in the markup only; take upstream's side of every instance script.
