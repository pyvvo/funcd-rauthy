<script module lang="ts">
    // funcd layout: markup and styles of this page are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
    import FuncdAlert from '$lib5/funcd/FuncdAlert.svelte';
</script>

<script lang="ts">
    import { onMount } from 'svelte';
    import { redirectToLogin } from '$utils/helpers';
    import LangSelector from '$lib5/LangSelector.svelte';
    import Input from '$lib5/form/Input.svelte';
    import Button from '$lib5/button/Button.svelte';
    import { TPL_DEVICE_USER_CODE_LENGTH } from '$utils/constants';
    import { fetchSolvePow } from '$utils/pow';
    import Main from '$lib5/Main.svelte';
    import ContentCenter from '$lib5/ContentCenter.svelte';
    import { useI18n } from '$state/i18n.svelte';
    import Template from '$lib5/Template.svelte';
    import { useParam } from '$state/param.svelte';
    import ThemeSwitch from '$lib5/ThemeSwitch.svelte';
    import type { SessionResponse } from '$api/types/session.ts';
    import { fetchGet, fetchPost } from '$api/fetch';
    import { PATTERN_ALNUM } from '$utils/patterns';
    import type { DeviceVerifyRequest, DeviceVerifyResponse } from '$api/types/device.ts';

    let t = useI18n();
    let session: undefined | SessionResponse = $state();

    let err = $state('');
    let isError = $state(false);
    let isLoading = $state(false);
    let userCodeLength = $state(8);

    let scopes: undefined | string[] = $state();
    let isAccepted = $state(false);
    let isDeclined = $state(false);

    let userCode = $state('');

    onMount(async () => {
        let param = useParam('code');
        let code = param.get() || '';
        userCode = code;

        let res = await fetchGet<SessionResponse>('/auth/v1/oidc/sessioninfo');
        if (res.body) {
            if (res.body.state != 'Auth') {
                redirectToLogin(`device?code=${code}`);
            }
            session = res.body;
        } else if (code) {
            redirectToLogin(`device?code=${code}`);
        } else {
            redirectToLogin('device');
        }
    });

    async function onSubmit(deviceAccepted: 'accept' | 'decline' | 'pending') {
        err = '';

        if (isError) {
            return;
        }
        if (userCode.length < userCodeLength) {
            err = t.common.errTooShort;
            return;
        }
        if (userCode.length > userCodeLength) {
            err = t.common.errTooLong;
            return;
        }
        isLoading = true;

        let pow = await fetchSolvePow();
        if (!pow) {
            err = 'PoW error - please contact your administrator';
            return;
        }
        let payload: DeviceVerifyRequest = {
            user_code: userCode,
            pow,
            device_accepted: deviceAccepted,
        };
        let res = await fetchPost<DeviceVerifyResponse>('/auth/v1/oidc/device/verify', payload);
        if (res.status === 200) {
            scopes = res.body?.scopes?.split(' ') || ['openid'];
        } else if (res.status === 202) {
            isAccepted = true;
            setTimeout(() => {
                window.location.replace('/auth/v1/account?v=devices');
            }, 2000);
        } else if (res.status === 204) {
            isDeclined = true;
        } else if (res.status === 404) {
            err = t.device.wrongOrExpired;
        } else {
            console.error(res);
            err = res.error?.message || '';
        }

        isLoading = false;
    }
</script>

<svelte:head>
    <title>{t?.device.title || 'Device Authorization'}</title>
</svelte:head>

<Template id={TPL_DEVICE_USER_CODE_LENGTH} bind:value={userCodeLength} />

{#if session}
    <FuncdAuthShell title={t.device.title}>
        <div class="stack">
            {#if scopes === undefined}
                <p>{t.device.desc.replace('{{count}}', userCodeLength.toString())}</p>

                <Input
                    name="userCode"
                    autocomplete="off"
                    label={t.device.userCode}
                    placeholder={t.device.userCode}
                    bind:value={userCode}
                    bind:isError
                    required
                    min={userCodeLength.toString()}
                    max={userCodeLength.toString()}
                    pattern={PATTERN_ALNUM}
                    width="100%"
                />

                <Button onclick={() => onSubmit('pending')} {isLoading} width="100%">
                    {t.device.submit}
                </Button>
            {:else if isAccepted}
                <FuncdAlert>
                    <p>{t.device.isAccepted}</p>
                    <p>{t.device.autoRedirectAccount}</p>
                </FuncdAlert>
            {:else if isDeclined}
                <FuncdAlert color="error">
                    <p>{t.device.isDeclined}</p>
                    <p>{t.device.closeWindow}</p>
                </FuncdAlert>
            {:else}
                <div>
                    <p>{t.device.descScopes}</p>
                    <ul class="scopes">
                        {#each scopes as scope}
                            <li><code>{scope}</code></li>
                        {/each}
                    </ul>
                </div>

                <div class="actions">
                    <Button level={-2} onclick={() => onSubmit('decline')} {isLoading} width="100%">
                        {t.device.decline}
                    </Button>
                    <Button onclick={() => onSubmit('accept')} {isLoading} width="100%">
                        {t.device.accept}
                    </Button>
                </div>
            {/if}

            {#if err}
                <FuncdAlert color="error">{err}</FuncdAlert>
            {/if}
        </div>
    </FuncdAuthShell>
{/if}

<style>
    .stack {
        display: flex;
        flex-direction: column;
        gap: 16px;
    }

    .scopes {
        margin: 8px 0 0;
        padding: 0;
        list-style: none;
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
    }

    .actions {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 12px;
    }
</style>
