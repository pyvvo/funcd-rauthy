<script module lang="ts">
    // funcd layout: markup and styles of the error pages are funcd's; the instance
    // script below is upstream rauthy, unchanged, so rebases only conflict on
    // markup.
    import FuncdAuthShell from '$lib5/funcd/FuncdAuthShell.svelte';
</script>

<script lang="ts">
    import LangSelector from '$lib5/LangSelector.svelte';
    import Main from '$lib5/Main.svelte';
    import ContentCenter from '$lib5/ContentCenter.svelte';
    import { useI18n } from '$state/i18n.svelte.js';
    import Template from '$lib5/Template.svelte';
    import { TPL_ERROR_TEXT, TPL_STATUS_CODE } from '$utils/constants';
    import ThemeSwitch from '$lib5/ThemeSwitch.svelte';
    import Expandable from '$lib5/Expandable.svelte';

    let t = useI18n();

    let statusCode = $state('');
    let errorText = $state('');
    let errorDetails = $state('');
</script>

<Template id={TPL_STATUS_CODE} bind:value={statusCode} />
<Template id={TPL_ERROR_TEXT} bind:value={errorText} />

<FuncdAuthShell title={statusCode} subtitle={errorText}>
    {#if errorDetails}
        <Expandable>
            {#snippet summary()}
                {t.error.details}
            {/snippet}
            {#snippet details()}
                {errorDetails}
            {/snippet}
        </Expandable>
    {/if}
</FuncdAuthShell>
