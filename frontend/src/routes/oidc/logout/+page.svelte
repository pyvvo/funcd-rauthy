<script module lang="ts">
    // funcd layout: markup and styles of this page are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
    import FuncdAlert from '$lib5/funcd/FuncdAlert.svelte';
</script>

<script lang="ts">
    import { getCsrfToken, purgeStorage, saveCsrfToken } from '$utils/helpers';
    import Button from '$lib5/button/Button.svelte';
    import { useI18n } from '$state/i18n.svelte';
    import Main from '$lib5/Main.svelte';
    import ContentCenter from '$lib5/ContentCenter.svelte';
    import LangSelector from '$lib5/LangSelector.svelte';
    import type { LogoutParams } from '$api/types/logout.ts';
    import Template from '$lib5/Template.svelte';
    import { IS_DEV, TPL_CSRF_TOKEN } from '$utils/constants';
    import { useParam } from '$state/param.svelte';
    import ThemeSwitch from '$lib5/ThemeSwitch.svelte';
    import { formDataFromObj } from '$api/fetch';

    let t = useI18n();
    let err = '';
    let isLoading = $state(false);

    let csrfToken = $state('');
    let logoutData: LogoutParams = $state({
        post_logout_redirect_uri: useParam('post_logout_redirect_uri').get(),
        id_token_hint: useParam('id_token_hint').get(),
        state: useParam('state').get(),
    });

    $effect(() => {
        if (csrfToken) {
            saveCsrfToken(csrfToken);
        }
    });

    $effect(() => {
        if (logoutData.id_token_hint) {
            handleLogout();
        }
    });

    function handleCancel() {
        window.location.replace('/auth/v1/');
    }

    async function handleLogout() {
        isLoading = true;
        let csrfToken = getCsrfToken();
        purgeStorage();

        let url = '/auth/v1/oidc/logout';
        if (IS_DEV) {
            url = '/auth/v1/dev/logout';
        }

        await fetch(url, {
            method: 'POST',
            headers: {
                'Content-type': 'application/x-www-form-urlencoded',
                'x-csrf-token': csrfToken,
            },
            // manual necessary during dev to avoid CORS issues when using the DEV vs static UI
            redirect: IS_DEV ? 'manual' : 'follow',
            body: formDataFromObj(logoutData),
        });

        // the fetch should always return a 302 and redirect automatically on success
        handleCancel();
    }
</script>

<svelte:head>
    <title>{t?.logout.logout || 'Logout'}</title>
</svelte:head>

<Template id={TPL_CSRF_TOKEN} bind:value={csrfToken} />

<FuncdAuthShell title={t.logout.logout} subtitle={t.logout.confirmMsg}>
    <div class="stack">
        <div class="actions">
            <Button level={2} onclick={handleCancel} width="100%">
                {t.common.cancel}
            </Button>
            <Button onclick={handleLogout} {isLoading} width="100%">
                {t.logout.logout}
            </Button>
        </div>

        {#if err}
            <FuncdAlert color="error">{err}</FuncdAlert>
        {/if}
    </div>
</FuncdAuthShell>

<style>
    .stack {
        display: flex;
        flex-direction: column;
        gap: 16px;
    }

    .actions {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 12px;
    }
</style>
