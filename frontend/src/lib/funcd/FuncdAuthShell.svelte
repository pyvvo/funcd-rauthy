<script lang="ts">
    // Page shell for every user-facing auth page, in funcd's ergonomics:
    // a floating header bar (brand left, feature pill right, like funcd's
    // Header), one centered Paper card (card radius xl = 20px), and an
    // optional line below the card. It also restyles the rauthy primitives
    // rendered inside it (Input, InputPassword, Button levels, Options,
    // PasswordPolicy) to funcd's Mantine metrics, so the page files keep
    // using the upstream components and their logic unchanged.
    import { type Snippet } from 'svelte';
    import LangSelector from '$lib5/LangSelector.svelte';
    import ThemeSwitch from '$lib5/ThemeSwitch.svelte';
    import IconHome from '$icons/IconHome.svelte';
    import FuncdLogo from './FuncdLogo.svelte';
    import FuncdWordmark from './FuncdWordmark.svelte';

    let {
        title,
        subtitle,
        homeHref,
        homeLabel = 'Home',
        maxWidth = '26rem',
        controls = true,
        children,
        below,
    }: {
        title?: string;
        subtitle?: string;
        homeHref?: string;
        homeLabel?: string;
        maxWidth?: string;
        // false when the page renders its own language/theme controls (the account dashboard)
        controls?: boolean;
        children: Snippet;
        below?: Snippet;
    } = $props();
</script>

<div class="page">
    <header class="header">
        <div class="brand">
            <FuncdLogo size={30} />
            <FuncdWordmark width={88} />
        </div>
        {#if controls}
            <div class="featureBar">
                {#if homeHref}
                    <a class="actionIcon" href={homeHref} aria-label={homeLabel} title={homeLabel}>
                        <IconHome width="16" opacity={1} />
                    </a>
                {/if}
                <div class="lang">
                    <LangSelector openTop={false} />
                </div>
                <div class="actionIcon theme">
                    <ThemeSwitch />
                </div>
            </div>
        {/if}
    </header>

    <main class="main">
        <section class="card" style:max-width={maxWidth}>
            {#if title}
                <div class="cardHead">
                    <h1 class="title">{title}</h1>
                    {#if subtitle}
                        <p class="subtitle">{subtitle}</p>
                    {/if}
                </div>
            {/if}
            {@render children()}
        </section>
        {#if below}
            <div class="below">
                {@render below()}
            </div>
        {/if}
    </main>
</div>

<style>
    /* ---- shell ---------------------------------------------------------- */
    /* body is a fixed-height scrolling flex row: take the content's height, at least the viewport */
    .page {
        flex: 1;
        align-self: flex-start;
        min-height: 100dvh;
        width: 100%;
        display: flex;
        flex-direction: column;
        font-family: var(--fd-font);
        color: var(--fd-text);
        background: var(--fd-page);
    }

    .header {
        position: sticky;
        top: 5px;
        z-index: 100;
        height: 60px;
        margin: 5px 12px 0;
        padding-inline: 12px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        border-radius: var(--fd-radius-xl);
        -webkit-backdrop-filter: blur(10px);
        backdrop-filter: blur(10px);
    }

    .brand {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .featureBar {
        display: flex;
        align-items: center;
        gap: 2px;
        padding: 6px;
        border-radius: var(--fd-radius-xl);
        background: var(--fd-surface);
        box-shadow: var(--fd-shadow-bar);
    }

    /* funcd ActionIcon, variant default, size 30, radius xl */
    .actionIcon {
        width: 30px;
        height: 30px;
        display: grid;
        place-items: center;
        border-radius: var(--fd-radius-xl);
        color: var(--fd-icon);
        transition:
            background-color 0.1s ease,
            color 0.1s ease;
    }

    .actionIcon:hover {
        color: var(--fd-icon-hover);
        background: var(--fd-hover);
    }

    a.actionIcon,
    a.actionIcon:hover {
        text-decoration: none;
    }

    .theme :global(.container),
    .theme :global(button) {
        width: 30px;
        height: 30px;
        display: grid;
        place-items: center;
        color: inherit;
        border-radius: var(--fd-radius-xl);
    }

    .theme :global(.icon) {
        width: 16px;
        height: 16px;
        margin: 0;
        color: inherit;
    }

    .theme :global(.icon svg) {
        width: 16px;
        height: 16px;
    }

    .theme :global(button > div) {
        color: inherit;
    }

    /* language selector: rauthy Options in the feature pill */
    .lang :global(.btn) {
        height: 30px;
        padding: 0 8px 0 10px;
        align-items: center;
        gap: 2px;
        border-radius: var(--fd-radius-xl);
        color: var(--fd-icon);
        font-family: var(--fd-font);
        font-size: 13px;
        font-weight: 500;
        text-transform: uppercase;
        transition:
            background-color 0.1s ease,
            color 0.1s ease;
    }

    .lang :global(.btn:hover) {
        color: var(--fd-icon-hover);
        background: var(--fd-hover);
    }

    /* every rauthy Popover (language, timezone, passkey type) -> Mantine dropdown */
    .page :global([popover]) {
        padding: 4px;
        background: var(--fd-surface);
        border: 1px solid var(--fd-border);
        border-radius: var(--fd-radius-md);
        box-shadow:
            0 1px 3px rgba(0, 0, 0, 0.05),
            rgba(0, 0, 0, 0.05) 0 10px 15px -5px,
            rgba(0, 0, 0, 0.04) 0 7px 7px -5px;
    }

    /* the Options listbox inside the Popover carries a `.popover` class of its own */
    .page :global([role='listbox'].popover) {
        padding: 0;
        background: none;
        border: none;
        box-shadow: none;
    }

    .page :global(.optPopover) {
        padding: 6px 12px;
        font-family: var(--fd-font);
        font-size: 14px;
        color: var(--fd-text);
        border-radius: var(--fd-radius-sm);
    }

    .lang :global(.optPopover) {
        text-transform: uppercase;
    }

    .page :global(.optPopover:hover),
    .page :global(.optPopover[data-focus='true']) {
        color: var(--fd-text-high);
        background: var(--fd-hover);
    }

    .page :global(.optPopover[aria-selected='true']) {
        color: var(--fd-primary);
        font-weight: 500;
    }

    .main {
        flex: 1;
        padding: 32px 16px 48px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 16px;
    }

    /* funcd Paper card: surface, card radius, soft shadow, no border */
    .card {
        width: 100%;
        padding: 32px;
        border-radius: var(--fd-radius-xl);
        background: var(--fd-surface);
        box-shadow: var(--fd-shadow-card);
        font-size: 14px;
        line-height: 1.55;
    }

    @media (max-width: 30rem) {
        .card {
            padding: 24px 20px;
        }
    }

    .cardHead {
        margin-bottom: 24px;
    }

    .cardHead:last-child {
        margin-bottom: 0;
    }

    .title {
        margin: 0;
        font-family: var(--fd-font);
        font-size: 26px;
        font-weight: 700;
        line-height: 1.3;
        letter-spacing: normal;
        color: var(--fd-text-high);
    }

    .subtitle {
        margin: 6px 0 0;
        max-width: none;
        font-size: 14px;
        color: var(--fd-dimmed);
    }

    .below {
        font-size: 14px;
        color: var(--fd-dimmed);
        text-align: center;
    }

    /* ---- typography and links inside the card -------------------------- */
    .card :global(p) {
        margin: 0;
        max-width: none;
    }

    .card :global(a),
    .card :global(a:link),
    .card :global(a:visited),
    .below :global(a),
    .below :global(a:link),
    .below :global(a:visited) {
        color: var(--fd-anchor);
        text-decoration: none;
        font-family: var(--fd-font);
    }

    .card :global(a:hover),
    .below :global(a:hover) {
        color: var(--fd-anchor);
        text-decoration: underline;
    }

    .card :global(code) {
        padding: 1px 5px;
        border-radius: var(--fd-radius-sm);
        background: var(--fd-hover);
        font-size: 13px;
    }

    /* ---- fields: rauthy Input / InputPassword -> Mantine TextInput sm ---- */
    .card :global(label) {
        font-family: var(--fd-font);
        font-size: 14px;
        font-weight: 500;
        line-height: 1.55;
        color: var(--fd-text-high);
    }

    .card :global(.label) {
        margin: 0 0 4px;
        padding: 0;
    }

    .card
        :global(
            input:not([type='checkbox']):not([type='radio']):not([type='hidden']):not([type='file'])
        ) {
        width: 100%;
        height: 36px;
        margin: 0;
        padding: 0 12px;
        font-family: var(--fd-font);
        font-size: 14px;
        color: var(--fd-text-high);
        background: var(--fd-input-bg);
        border: 1px solid var(--fd-border);
        border-radius: var(--fd-radius-md);
        transition: border-color 100ms ease;
    }

    .card :global(input:hover),
    .card :global(input:focus) {
        color: var(--fd-text-high);
        background: var(--fd-input-bg);
    }

    .card :global(input:focus) {
        outline: none;
        border-color: var(--fd-primary);
    }

    .card :global(input.invalid),
    .card :global(input.invalid:focus) {
        border-color: var(--fd-error);
    }

    .card :global(input::placeholder) {
        color: var(--fd-placeholder);
    }

    .card :global(input:disabled) {
        opacity: 0.6;
        color: var(--fd-dimmed);
        background: var(--fd-disabled-bg);
        cursor: not-allowed;
    }

    .card :global(.error) {
        margin: 5px 0 0;
        padding: 0;
        font-size: 12px;
        line-height: 1.2;
        color: var(--fd-error);
    }

    .card :global(.container:has(> .input-row)) {
        margin: 0;
    }

    .card :global(.input-row .btn) {
        top: 9px;
        right: 8px;
        opacity: 1;
        color: var(--fd-icon);
    }

    .card :global(.input-row .clip) {
        right: 34px;
    }

    /* rauthy draws the eye-slash in its error color; funcd input icons are dimmed */
    .card :global(.input-row .btn svg) {
        width: 18px;
        height: 18px;
        color: var(--fd-icon);
        stroke: currentColor;
    }

    .card :global(.input-row button.invisible:hover svg) {
        color: var(--fd-icon-hover);
    }

    /* selects: rauthy Options with a border (timezone, passkey type) -> Mantine Select */
    .card :global(.tz .label) {
        margin: 0 0 4px;
        padding: 0;
        font-size: 14px;
        font-weight: 500;
        color: var(--fd-text-high);
    }

    .card :global(.tz .opts) {
        margin: 0;
    }

    .card :global(.tz button.invisible),
    .card :global(.tz .btn) {
        width: 100%;
    }

    .card :global(.btn[data-border='true']) {
        height: 36px;
        padding: 0 10px 0 12px;
        align-items: center;
        justify-content: space-between;
        font-family: var(--fd-font);
        font-size: 14px;
        color: var(--fd-text-high);
        background: var(--fd-input-bg);
        border: 1px solid var(--fd-border);
        border-radius: var(--fd-radius-md);
    }

    .card :global(.btn[data-border='true']:hover) {
        color: var(--fd-text-high);
        border-color: var(--fd-primary);
    }

    .card :global(.btn[data-border='true'] .btnText) {
        margin: 0;
    }

    .card :global(.input-row button.invisible > div) {
        color: var(--fd-icon);
    }

    .card :global(.input-row button.invisible:hover > div) {
        color: var(--fd-icon-hover);
    }

    /* ---- buttons: rauthy Button levels -> funcd Button variants --------- */
    .card :global(button.l1),
    .card :global(button.l2),
    .card :global(button.l3),
    .card :global(button.l1d),
    .card :global(button.l2d),
    .card :global(button.l3d) {
        height: 36px;
        padding: 0 18px;
        font-family: var(--fd-font);
        font-size: 14px;
        font-weight: 600;
        border-radius: var(--fd-radius-lg);
        box-shadow: none;
        outline: 2px solid transparent;
        outline-offset: 2px;
        transition:
            background-color 0.1s ease,
            color 0.1s ease,
            outline-color 0.1s ease,
            border-color 0.1s ease;
    }

    .card :global(button.l1:active),
    .card :global(button.l2:active),
    .card :global(button.l3:active),
    .card :global(button.l1d:active),
    .card :global(button.l2d:active),
    .card :global(button.l3d:active) {
        transform: scale(0.97);
    }

    /* filled */
    .card :global(button.l1) {
        color: var(--fd-on-primary);
        background: var(--fd-primary);
        border: 1px solid transparent;
    }

    .card :global(button.l1:hover) {
        box-shadow: none;
        background: var(--fd-primary-hover);
        outline-color: var(--fd-primary-hover);
    }

    .card :global(button.l1:active) {
        background: var(--fd-primary-active);
        outline-color: var(--fd-primary-active);
    }

    /* secondary */
    .card :global(button.l2) {
        color: var(--fd-primary);
        background: transparent;
        border: 1px solid var(--fd-primary);
    }

    .card :global(button.l2:hover) {
        box-shadow: none;
        background: var(--fd-primary-2);
        border-color: transparent;
        outline-color: var(--fd-primary-2);
    }

    /* subtle */
    .card :global(button.l3) {
        color: var(--fd-primary);
        background: transparent;
        border: 1px solid transparent;
    }

    .card :global(button.l3:hover) {
        color: #ffffff;
        box-shadow: none;
        background: var(--fd-primary-4);
        outline-color: var(--fd-primary-4);
    }

    /* danger levels (rauthy -1 / -2 / -3): the same variants in Mantine red */
    .card :global(button.l1d) {
        color: #ffffff;
        background: var(--fd-error);
        border: 1px solid transparent;
    }

    .card :global(button.l1d:hover) {
        box-shadow: none;
        background: color-mix(in srgb, var(--fd-error) 85%, #ffffff);
        outline-color: color-mix(in srgb, var(--fd-error) 85%, #ffffff);
    }

    .card :global(button.l2d) {
        color: var(--fd-error);
        background: transparent;
        border: 1px solid var(--fd-error);
    }

    .card :global(button.l2d:hover),
    .card :global(button.l3d:hover) {
        box-shadow: none;
        background: var(--fd-error-soft);
        outline-color: transparent;
    }

    .card :global(button.l3d) {
        color: var(--fd-error);
        background: transparent;
        border: 1px solid transparent;
    }

    .card :global(button.l1[aria-disabled='true']),
    .card :global(button.l2[aria-disabled='true']),
    .card :global(button.l3[aria-disabled='true']),
    .card :global(button.l1d[aria-disabled='true']),
    .card :global(button.l2d[aria-disabled='true']),
    .card :global(button.l3d[aria-disabled='true']) {
        color: var(--fd-disabled-fg);
        background: var(--fd-disabled-bg);
        border-color: transparent;
        outline-color: transparent;
        transform: none;
    }

    .card :global(button.l1[data-isloading='true']) {
        color: var(--fd-on-primary);
        background: var(--fd-primary);
    }

    .card :global(button .children) {
        gap: 8px;
    }

    /* ---- password policy: compact checklist ----------------------------- */
    .card :global(.policyContainer) {
        margin: 0;
        padding: 12px 16px;
        border-radius: var(--fd-radius-md);
        background: var(--fd-hover);
    }

    .card :global(.policyContainer b) {
        margin: 0;
        font-size: 13px;
        font-weight: 600;
        color: var(--fd-text-high);
    }

    .card :global(.policyContainer ul) {
        margin: 6px 0 0;
        display: grid;
        gap: 2px;
    }

    .card :global(.policyContainer li) {
        margin: 0;
        font-size: 12.5px;
        line-height: 1.6;
        color: var(--fd-text);
    }

    .card :global(.policyContainer li svg) {
        width: 14px;
        height: 14px;
        flex-shrink: 0;
    }

    .card :global(.policyContainer .used) {
        grid-column: 1 / -1;
        color: var(--fd-dimmed);
    }

    .card :global(.policyContainer .policyErr) {
        color: var(--fd-error);
    }
</style>
