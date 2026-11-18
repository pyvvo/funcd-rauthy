<script module lang="ts">
    // funcd layout: markup and styles of this page are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
    import FuncdAlert from '$lib5/funcd/FuncdAlert.svelte';
</script>

<script lang="ts">
    import Button from '$lib/button/Button.svelte';
    import { IS_DEV, TPL_CLIENT_LOGO_UPDATED } from '$utils/constants';
    import Input from '$lib/form/Input.svelte';
    import LangSelector from '$lib/LangSelector.svelte';
    import Main from '$lib/Main.svelte';
    import ContentCenter from '$lib/ContentCenter.svelte';
    import { useI18n } from '$state/i18n.svelte.js';
    import Template from '$lib/Template.svelte';
    import { useParam } from '$state/param.svelte.js';
    import ThemeSwitch from '$lib/ThemeSwitch.svelte';
    import Form from '$lib/form/Form.svelte';
    import { fetchPost } from '$api/fetch';
    import ClientLogo from '$lib/ClientLogo.svelte';
    import { fetchSolvePow } from '$utils/pow';
    import type { RequestResetRequest } from '$api/types/authorize';

    let t = useI18n();

    let email_hint = useParam('email_hint');

    let clientLogoUpdated = $state(-1);
    let isLoading = $state(false);
    let err = $state('');
    let success = $state(false);

    async function onSubmit(form: HTMLFormElement, params: URLSearchParams) {
        isLoading = true;

        let email = params.get('email');
        if (!email) {
            console.error('email is empty');
            return;
        }
        let pow = (await fetchSolvePow()) || '';
        let payload: RequestResetRequest = { email, pow };

        let res = await fetchPost(form.action, payload);
        if (res.error) {
            err = res.error.message;
        } else {
            success = true;
        }

        isLoading = false;
    }
</script>

<svelte:head>
    <title>{t?.passwordReset.passwordReset || 'Password Reset'}</title>
</svelte:head>

<Template id={TPL_CLIENT_LOGO_UPDATED} bind:value={clientLogoUpdated} />

<FuncdAuthShell title={t.passwordReset.passwordReset} subtitle={t.authorize.passwordResetDesc}>
    <Form action="/auth/v1/users/request_reset" {onSubmit} withPowAs="pow">
        <div class="stack">
            <Input
                typ="email"
                name="email"
                autocomplete="email"
                label={t.common.email}
                placeholder={t.common.email}
                required
                value={email_hint.get()}
                width="100%"
            />

            <Button type="submit" {isLoading} width="100%">{t.authorize.passwordRequest}</Button>

            {#if success}
                <FuncdAlert>{t.authorize.passwordResetSuccess}</FuncdAlert>
            {:else if err}
                <FuncdAlert color="error">{err}</FuncdAlert>
            {/if}
        </div>
    </Form>
</FuncdAuthShell>

<style>
    .stack {
        display: flex;
        flex-direction: column;
        gap: 16px;
    }
</style>
