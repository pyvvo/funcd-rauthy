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
- **Left as upstream**: the admin UI (layout kept, colors remapped), the FedCM test page, the backend's
  plain 429 and "blocked" pages, and the e-mails (backend templates, themed server-side).

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

Open `http://localhost:5173/auth/v1/account`; the dev admin is in `config.toml`. Vite proxies
`/auth/v1/dev` by prefix, so `/auth/v1/device` comes from the backend's build: run `just build-ui`
and rebuild the backend to see a change there.

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
