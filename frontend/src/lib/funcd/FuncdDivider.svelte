<script lang="ts">
    // Mantine Divider with a centered label ("or continue with").
    let { label }: { label?: string } = $props();
</script>

<div class="divider" role="separator" aria-label={label}>
    {#if label}
        <span>{label}</span>
    {/if}
</div>

<style>
    .divider {
        margin: 20px 0 16px;
        display: flex;
        align-items: center;
        gap: 10px;
        font-size: 12px;
        color: var(--fd-dimmed);
    }

    .divider::before,
    .divider::after {
        content: '';
        flex: 1;
        height: 1px;
        background: var(--fd-divider);
    }
</style>
