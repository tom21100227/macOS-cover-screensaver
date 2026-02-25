<script lang="ts">
	import CoverGrid from './CoverGrid.svelte';
	import { allCovers } from '$lib/stores/covers';

	const gridCovers = $derived(
		$allCovers.map((c) => ({ id: c.id, url: c.url }))
	);

	const hasCovers = $derived(gridCovers.length > 0);
</script>

{#if hasCovers}
	<CoverGrid covers={gridCovers} />
{:else}
	<div class="empty">
		<div class="empty-grid">
			{#each Array(24) as _}
				<div class="placeholder"></div>
			{/each}
		</div>
		<div class="vignette"></div>
	</div>
{/if}

<style>
	.empty {
		position: fixed;
		inset: 0;
		background: #000;
		overflow: hidden;
	}

	.empty-grid {
		display: grid;
		grid-template-columns: repeat(8, 1fr);
		gap: 3px;
		padding: 0;
		height: 100%;
	}

	.placeholder {
		background: rgba(255, 255, 255, 0.03);
		aspect-ratio: 1;
	}

	.vignette {
		position: fixed;
		inset: 0;
		pointer-events: none;
		background: radial-gradient(
			ellipse at center,
			transparent 30%,
			rgba(0, 0, 0, 0.3) 60%,
			rgba(0, 0, 0, 0.85) 100%
		);
		z-index: 10;
	}
</style>
