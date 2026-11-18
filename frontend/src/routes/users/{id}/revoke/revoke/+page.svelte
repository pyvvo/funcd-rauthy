<script module lang="ts">
    // funcd layout: markup and styles of this page are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
    import FuncdAlert from '$lib5/funcd/FuncdAlert.svelte';
</script>

<script lang="ts">
    import LangSelector from '$lib5/LangSelector.svelte';
    import Main from '$lib5/Main.svelte';
    import ContentCenter from '$lib5/ContentCenter.svelte';
    import { useI18n } from '$state/i18n.svelte';
    import ThemeSwitch from '$lib5/ThemeSwitch.svelte';
    import A from '$lib/A.svelte';

    let t = useI18n();
</script>

<svelte:head>
    <title>{t.userRevoke.title || 'Login Revoke'}</title>
</svelte:head>

<FuncdAuthShell title={t.userRevoke.title} subtitle={t.userRevoke.desc1}>
    <div class="stack">
        <FuncdAlert color="error">{t.userRevoke.desc2}</FuncdAlert>
        <A href="/auth/v1/account">Account</A>
    </div>
</FuncdAuthShell>

<style>
    .stack {
        display: flex;
        flex-direction: column;
        gap: 16px;
    }
</style>
