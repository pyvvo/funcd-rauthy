<script lang="ts">
    // funcd Tabs, variant `pills`: a raised pill list where the active tab is
    // tinted with the primary color. Used as a two-way choice (passkey / password).
    let {
        options,
        value,
        disabled = false,
        onSelect,
    }: {
        options: { value: string; label: string }[];
        value?: string;
        disabled?: boolean;
        onSelect: (value: string) => void;
    } = $props();
</script>

<div class="list" role="tablist">
    {#each options as option (option.value)}
        <button
            type="button"
            role="tab"
            class="tab"
            aria-selected={value === option.value}
            data-active={value === option.value || undefined}
            {disabled}
            onclick={() => onSelect(option.value)}
        >
            {option.label}
        </button>
    {/each}
</div>

<style>
    .list {
        padding: 6px;
        display: grid;
        grid-auto-columns: minmax(0, 1fr);
        grid-auto-flow: column;
        gap: 4px;
        border-radius: var(--fd-radius-xl);
        background: var(--fd-pill-list-bg);
        box-shadow: var(--fd-pill-list-shadow);
    }

    .tab {
        padding: 8px 12px;
        font-family: var(--fd-font);
        font-size: 14px;
        font-weight: 500;
        color: var(--fd-pill-text);
        background: transparent;
        border: 2px solid transparent;
        border-radius: var(--fd-radius-xl);
        cursor: pointer;
        transition:
            background-color 0.1s ease,
            color 0.1s ease;
    }

    .tab:hover {
        background: var(--fd-pill-hover);
    }

    .tab[data-active] {
        color: var(--fd-pill-active-text);
        background: var(--fd-pill-active-bg);
    }

    .tab[data-active]:hover {
        background: var(--fd-pill-active-hover);
    }

    .tab:focus-visible {
        outline: 2px solid var(--fd-primary);
        outline-offset: 2px;
    }

    .tab:disabled {
        cursor: not-allowed;
        opacity: 0.6;
    }
</style>
