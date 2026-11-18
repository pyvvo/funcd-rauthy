#!/usr/bin/env bash
# funcd fork guard. Run in CI on the funcd-ui branch, against the upstream tag
# the branch is rebased on:   funcd/check.sh v0.37.2
#
# 1. The branch only touches the funcd allowlist (styles, assets, the funcd
#    component folder, and the markup of the user-facing auth pages).
# 2. The instance <script> of every rewritten page is byte-identical to
#    upstream: auth logic (CSRF, PoW, WebAuthn, redirects) is never forked.
# 3. Every static asset we add ships .br/.gz siblings: rauthy's asset handler
#    serves `<path>.br` / `<path>.gz` to browsers and 404s without them.
# 4. The mail templates are what funcd/email/src compiles to (MJML); SKIP when
#    funcd/email has no node_modules (run `npm ci` there).
set -euo pipefail

UPSTREAM="${1:?usage: funcd/check.sh <upstream-tag>}"

pages=(
    'frontend/src/routes/+page.svelte'
    'frontend/src/routes/account/+page.svelte'
    'frontend/src/routes/device/+page.svelte'
    'frontend/src/routes/oidc/authorize/+page.svelte'
    'frontend/src/routes/oidc/callback/+page.svelte'
    'frontend/src/routes/oidc/logout/+page.svelte'
    'frontend/src/routes/providers/callback/+page.svelte'
    'frontend/src/routes/users/register/+page.svelte'
    'frontend/src/routes/users/password_reset/+page.svelte'
    'frontend/src/routes/users/{id}/reset/reset/+page.svelte'
    'frontend/src/routes/users/{id}/email_confirm/email_confirm/+page.svelte'
    'frontend/src/routes/users/{id}/revoke/revoke/+page.svelte'
    'frontend/src/lib/Error.svelte'
)

allow='^(funcd/.*'
allow+='|frontend/svelte\.config\.js'
allow+='|frontend/src/app\.html'
allow+='|frontend/src/css/(funcd|global)\.css'
allow+='|frontend/src/lib/funcd/.*'
allow+='|frontend/src/lib/Error\.svelte'
allow+='|frontend/static/assets/(fonts/.*|favicon\.svg|funcd-email\.png|rauthy_(dark|light)\.svg)'
allow+='|templates/email/(change_info|confirm_change|email_registered_already|event|login_location|otp'
allow+='|reset|reset_info)\.html'
allow+='|frontend/src/routes/(account/|device/|oidc/authorize/|oidc/callback/|oidc/logout/'
allow+='|providers/callback/|users/register/|users/password_reset/|users/\{id\}/reset/reset/'
allow+='|users/\{id\}/email_confirm/email_confirm/|users/\{id\}/revoke/revoke/)?\+page\.svelte'
allow+=')$'

fail=0

outside=$(git diff --name-only "$UPSTREAM"...HEAD | grep -Ev "$allow" || true)
if [ -n "$outside" ]; then
    echo "files outside the funcd allowlist:"
    echo "$outside" | sed 's/^/  /'
    fail=1
fi

instance_script() {
    awk '/^<script lang="ts">/{s=1} s; /^<\/script>/{if (s) exit}'
}

for p in "${pages[@]}"; do
    a=$(git show "$UPSTREAM:$p" | instance_script | sha256sum)
    b=$(instance_script < "$p" | sha256sum)
    if [ "$a" != "$b" ]; then
        echo "instance script differs from upstream: $p"
        fail=1
    fi
done

while IFS= read -r f; do
    case "$f" in
        *.png | *.webp | *.jpg | *.br | *.gz) continue ;;
    esac
    if [ ! -f "$f.br" ] || [ ! -f "$f.gz" ]; then
        echo "missing precompressed variant (.br/.gz) for $f"
        fail=1
    fi
done < <(git diff --name-only --diff-filter=A "$UPSTREAM"...HEAD -- frontend/static/assets)

if [ -d funcd/email/node_modules ] && command -v node >/dev/null; then
    if ! node funcd/email/build.mjs --check; then
        echo "mail templates are stale: run npm run build in funcd/email"
        fail=1
    fi
else
    echo "SKIP mail template check: no node or funcd/email/node_modules"
fi

if [ "$fail" -ne 0 ]; then
    exit 1
fi
echo "funcd guard: ok"
