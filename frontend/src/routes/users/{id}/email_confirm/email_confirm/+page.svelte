<script module lang="ts">
    // funcd layout: markup and styles of this page are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
</script>

<script lang="ts">
    import LangSelector from '$lib5/LangSelector.svelte';
    import Button from '$lib5/button/Button.svelte';
    import Main from '$lib5/Main.svelte';
    import ContentCenter from '$lib5/ContentCenter.svelte';
    import { useI18n } from '$state/i18n.svelte';
    import Template from '$lib5/Template.svelte';
    import { TPL_EMAIL_NEW, TPL_EMAIL_OLD } from '$utils/constants.js';
    import ThemeSwitch from '$lib5/ThemeSwitch.svelte';

    let t = useI18n();

    let emailOld = $state('old@mail.org');
    let emailNew = $state('new@mail.org');
</script>

<svelte:head>
    <title>{t.emailChange.title || 'E-Mail Change Confirm'}</title>
</svelte:head>

<Template id={TPL_EMAIL_OLD} bind:value={emailOld} />
<Template id={TPL_EMAIL_NEW} bind:value={emailNew} />

<FuncdAuthShell title={t.emailChange.title}>
    <div class="stack">
        <p>{t.emailChange.textChanged}:</p>
        <div class="change">
            <span class="mail">{emailOld}</span>
            <span class="to">{t.emailChange.to}</span>
            <span class="mail">{emailNew}</span>
        </div>
        <p class="dimmed">{t.emailChange.textLogin}</p>
        <Button onclick={() => window.location.replace('/auth/v1/account')} width="100%">
            {t.authorize.login}
        </Button>
    </div>
</FuncdAuthShell>

<style>
    .stack {
        display: flex;
        flex-direction: column;
        gap: 16px;
    }

    .change {
        padding: 12px 16px;
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 6px 10px;
        border-radius: var(--fd-radius-md);
        background: var(--fd-hover);
    }

    .mail {
        font-weight: 600;
        color: var(--fd-text-high);
        overflow-wrap: anywhere;
    }

    .to,
    .dimmed {
        color: var(--fd-dimmed);
    }
</style>
