<script module lang="ts">
    // funcd layout: markup and styles of this page are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
</script>

<script lang="ts">
    import Button from '$lib5/button/Button.svelte';
    import Main from '$lib5/Main.svelte';
    import ContentCenter from '$lib5/ContentCenter.svelte';
    import { useI18n } from '$state/i18n.svelte';
    import Template from '$lib5/Template.svelte';
    import { TPL_ADMIN_BUTTON_HIDE, TPL_IS_REG_OPEN } from '$utils/constants';
    import ThemeSwitch from '$lib5/ThemeSwitch.svelte';
    import LangSelector from '$lib5/LangSelector.svelte';

    const btnWidth = '9rem';

    let t = useI18n();
    let hideAdminButton = $state(true);
    let isRegOpen = $state(false);

    function redirectToAdmin() {
        window.location.href = '/auth/v1/admin';
    }

    function redirectToAccount() {
        window.location.href = '/auth/v1/account';
    }

    function redirectToReg() {
        window.location.href = '/auth/v1/users/register';
    }
</script>

<svelte:head>
    <title>funcd</title>
</svelte:head>

<Template id={TPL_ADMIN_BUTTON_HIDE} bind:value={hideAdminButton} />
<Template id={TPL_IS_REG_OPEN} bind:value={isRegOpen} />

<FuncdAuthShell maxWidth="22rem">
    <div class="stack">
        <Button ariaLabel={t.index.accountLogin} onclick={redirectToAccount} width="100%">
            {t.index.accountLogin}
        </Button>
        {#if isRegOpen}
            <Button ariaLabel={t.index.register} level={2} onclick={redirectToReg} width="100%">
                {t.index.register}
            </Button>
        {/if}
        {#if !hideAdminButton}
            <Button ariaLabel={t.index.adminLogin} level={3} onclick={redirectToAdmin} width="100%">
                {t.index.adminLogin}
            </Button>
        {/if}
    </div>
</FuncdAuthShell>

<style>
    .stack {
        display: flex;
        flex-direction: column;
        gap: 12px;
    }
</style>
