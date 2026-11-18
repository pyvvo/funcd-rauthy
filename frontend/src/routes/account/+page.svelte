<script module lang="ts">
    // funcd layout: markup and styles of this page are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
</script>

<script lang="ts">
    import AccMain from '$lib5/account/AccMain.svelte';
    import { redirectToLogin } from '$utils/helpers';
    import Main from '$lib5/Main.svelte';
    import ContentCenter from '$lib5/ContentCenter.svelte';
    import { useI18n } from '$state/i18n.svelte';
    import { type UserResponse } from '$api/types/user';
    import { fetchGet } from '$api/fetch';
    import type { WebIdResponse } from '$api/types/web_id.ts';
    import { useSession } from '$state/session.svelte';
    import type { SessionInfoResponse } from '$api/types/session.ts';

    let t = useI18n();
    let session = useSession('account');

    let user: undefined | UserResponse = $state();
    let webIdData: undefined | WebIdResponse = $state();
    let isReady = $state(false);

    $effect(() => {
        let s = session.get();
        if (s) {
            fetchInfo(s);
        }
    });

    async function fetchInfo(s: SessionInfoResponse) {
        const userId = s.user_id;
        if (userId) {
            let res = await Promise.all([
                fetchGet<UserResponse>(`/auth/v1/users/${userId}`),
                fetchGet<WebIdResponse>(`/auth/v1/users/${userId}/webid/data`),
            ]);

            if (res[0].body) {
                user = res[0].body;
            } else {
                redirectToLogin('account');
            }

            if (res[1].body) {
                webIdData = res[1].body;
            } else if (res[1].status === 404) {
                webIdData = {
                    user_id: userId,
                    expose_email: false,
                };
            } else {
                // now it can only be a 405 -> webid is not enabled -> do nothing
            }

            isReady = true;
        } else {
            console.error('no user_id in session');
        }
    }
</script>

<svelte:head>
    <!--
    for some reason, t can be undefined in the svelte:head section even though it never is
    inside the component, even during init and before the very first render
    -->
    <title>{t?.account.account || 'Account'} {user?.email}</title>
</svelte:head>

<FuncdAuthShell controls={false} maxWidth="66rem">
    <div id="funcd-account">
        {#if isReady && session && user}
            <AccMain bind:user bind:webIdData />
        {/if}
    </div>
</FuncdAuthShell>

<style>
    /*
     * The account dashboard (lib/account, upstream) restyled from here, so its
     * components stay unforked: it flows inside the funcd card, its tabs become
     * funcd pills, and its theme / language / Admin UI / logout row becomes the
     * header's feature pill. The id outranks the components' scoped styles.
     */
    #funcd-account {
        position: relative;
    }

    #funcd-account :global(.wrapper) {
        height: auto;
        max-width: none;
    }

    #funcd-account :global(.wide) {
        height: auto;
        min-height: 34rem;
        padding: 0;
        gap: 32px;
        align-items: stretch;
        border-radius: 0;
        background: none;
    }

    #funcd-account :global(.info) {
        flex: 0 0 auto;
        padding-right: 32px;
        border-right: 1px solid var(--fd-divider);
    }

    #funcd-account :global(.wide > .container) {
        flex: 1;
        min-width: 0;
        max-height: none;
        margin: 0;
    }

    #funcd-account :global(.inner),
    #funcd-account :global(.innerPhone) {
        width: auto;
        max-height: none;
        padding: 20px 0 0;
        overflow: visible;
    }

    /* the shell zeroes rauthy's label margins; the dashboard forms get funcd's field rhythm back */
    #funcd-account :global(:is(.inner, .innerPhone) .label) {
        margin: 12px 0 4px;
    }

    #funcd-account :global(:is(.inner, .innerPhone) div.label) {
        font-size: 14px;
        font-weight: 500;
        color: var(--fd-text-high);
    }

    /* PreferredUsername: a read-only field with its Edit button inside, at input metrics */
    #funcd-account :global(.value[data-required]) {
        height: 36px;
        padding: 0 3px 0 12px;
        align-items: center;
        background: var(--fd-input-bg);
        border: 1px solid var(--fd-border);
        border-radius: var(--fd-radius-md);
    }

    #funcd-account :global(.value[data-required='true']) {
        border-color: var(--fd-error);
    }

    #funcd-account :global(.value[data-required] .name) {
        padding: 0;
    }

    #funcd-account :global(.value[data-required] .btn) {
        margin: 0;
    }

    #funcd-account :global(.value[data-required] button) {
        height: 28px;
        padding: 0 12px;
        font-size: 13px;
        border-radius: var(--fd-radius-md);
    }

    #funcd-account :global(.redirectHome[data-absolute='true']) {
        top: -20px;
        left: -20px;
    }

    /* info column: Mantine text sizes, dimmed labels */
    #funcd-account :global(:is(.row > .label, .rowPhone > .labelPhone)) {
        font-size: 13px;
        color: var(--fd-dimmed);
    }

    #funcd-account :global(.value) {
        font-size: 14px;
        color: var(--fd-text-high);
    }

    #funcd-account :global(:is(.row, .rowPhone)) {
        margin-bottom: 6px;
    }

    /* the generated initials avatar -> funcd Avatar: round, primary light variant */
    #funcd-account :global(form.avatar) {
        width: 96px !important;
        height: 96px;
        border-radius: 50%;
        background-color: var(--fd-primary-soft) !important;
        overflow: hidden;
    }

    #funcd-account :global(form.avatar label) {
        width: 100% !important;
        height: 100%;
    }

    #funcd-account :global(form.avatar .font-large) {
        font-family: var(--fd-font);
        font-size: 32px;
        font-weight: 700;
        color: var(--fd-primary);
    }

    #funcd-account :global(.headerPhone h3) {
        margin: 0;
        font-size: 20px;
        font-weight: 700;
        color: var(--fd-text-high);
    }

    /* tabs -> funcd Tabs, variant pills */
    #funcd-account :global(.tabs) {
        padding: 6px;
        column-gap: 4px;
        row-gap: 4px;
        border-radius: var(--fd-radius-xl) !important;
        background: var(--fd-pill-list-bg);
        box-shadow: var(--fd-pill-list-shadow);
    }

    #funcd-account :global(.tabs .tab) {
        display: block;
        padding: 6px 12px;
        font-family: var(--fd-font);
        font-size: 14px;
        font-weight: 500;
        line-height: 1.4;
        color: var(--fd-pill-text);
        background: transparent;
        border-radius: var(--fd-radius-xl);
    }

    #funcd-account :global(.tabs .tab:hover) {
        color: var(--fd-pill-text);
        background: var(--fd-pill-hover);
    }

    #funcd-account :global(.tabs .tab[data-selected='true']) {
        color: var(--fd-pill-active-text);
        background: var(--fd-pill-active-bg);
    }

    /* theme / language / Admin UI / logout -> the header's feature pill */
    #funcd-account :global(.bottomLeft) {
        position: fixed;
        top: 14px;
        right: 24px;
        bottom: auto;
        left: auto;
        z-index: 101;
        padding: 6px;
        gap: 2px;
        border-radius: var(--fd-radius-xl);
        background: var(--fd-surface);
        box-shadow: var(--fd-shadow-bar);
    }

    #funcd-account :global(.bottomBarPhone) {
        margin-top: 20px;
        padding: 12px 0 0;
        gap: 2px;
        border-top: 1px solid var(--fd-divider);
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) > .container button),
    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) .adminLink a),
    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) .btn),
    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) button.l3d) {
        height: 30px;
        min-width: 30px;
        margin: 0;
        padding: 0 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        font-family: var(--fd-font);
        font-size: 13px;
        font-weight: 500;
        color: var(--fd-icon);
        background: transparent;
        border: none;
        border-radius: var(--fd-radius-xl);
        outline: none;
        text-decoration: none;
        transition:
            background-color 0.1s ease,
            color 0.1s ease;
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) > .container button) {
        padding: 0;
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) .btn) {
        padding: 0 8px 0 10px;
        gap: 2px;
        text-transform: uppercase;
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) > .container button:hover),
    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) .adminLink a:hover),
    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) .btn:hover) {
        color: var(--fd-icon-hover);
        background: var(--fd-hover);
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) button.l3d) {
        color: var(--fd-error);
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) button.l3d:hover) {
        background: var(--fd-error-soft);
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) :is(.icon, svg)) {
        width: 16px;
        height: 16px;
        margin: 0;
        color: inherit;
    }

    #funcd-account :global(:is(.bottomLeft, .bottomBarPhone) button > div) {
        color: inherit;
    }

    #funcd-account :global(.adminLink) {
        font-size: 13px;
    }

    #funcd-account :global(.optPopover) {
        text-transform: uppercase;
    }
</style>
