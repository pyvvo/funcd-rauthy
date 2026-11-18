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
set -euo pipefail

UPSTREAM="${1:?usage: funcd/check.sh <upstream-tag>}"

pages=(
    'frontend/src/routes/oidc/authorize/+page.svelte'
    'frontend/src/routes/users/register/+page.svelte'
    'frontend/src/routes/users/password_reset/+page.svelte'
    'frontend/src/routes/users/{id}/reset/reset/+page.svelte'
    'frontend/src/routes/users/{id}/email_confirm/email_confirm/+page.svelte'
)

allow='^(funcd/.*'
allow+='|frontend/svelte\.config\.js'
allow+='|frontend/src/css/(funcd|global)\.css'
allow+='|frontend/src/lib/funcd/.*'
allow+='|frontend/static/assets/(fonts/.*|favicon\.svg|rauthy_(dark|light)\.svg)'
allow+='|frontend/src/routes/(oidc/authorize|users/register|users/password_reset'
allow+='|users/\{id\}/reset/reset|users/\{id\}/email_confirm/email_confirm)/\+page\.svelte'
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

if [ "$fail" -ne 0 ]; then
    exit 1
fi
echo "funcd guard: ok"
