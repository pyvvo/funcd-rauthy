<script lang="ts">
    // Mantine Alert, light variant: a tinted surface with an optional title.
    import { type Snippet } from 'svelte';

    let {
        color = 'primary',
        title,
        children,
    }: {
        color?: 'primary' | 'error';
        title?: string;
        children: Snippet;
    } = $props();
</script>

<div class="alert" data-color={color} role={color === 'error' ? 'alert' : 'status'}>
    {#if title}
        <div class="title">{title}</div>
    {/if}
    <div class="body">
        {@render children()}
    </div>
</div>

<style>
    .alert {
        padding: 12px 16px;
        border-radius: var(--fd-radius-md);
        font-size: 14px;
        line-height: 1.55;
        color: var(--fd-text);
        background: var(--fd-primary-soft);
        overflow-wrap: anywhere;
    }

    .alert[data-color='error'] {
        background: var(--fd-error-soft);
    }

    .title {
        margin-bottom: 2px;
        font-weight: 700;
        color: var(--fd-anchor);
    }

    .alert[data-color='error'] .title,
    .alert[data-color='error'] .body {
        color: var(--fd-error);
    }
</style>
