<script lang="ts">
	import { onMount } from 'svelte';

	interface Props {
		covers: { id: string; url: string }[];
	}

	let { covers }: Props = $props();

	let coverSize = $state(0);
	let coversPerRow = $state(8);
	let rowCount = $state(0);
	let rows: Array<{ id: string; url: string }[]> = $state([]);
	let ready = $state(false);
	const GAP = 3;

	function shuffle<T>(arr: T[]): T[] {
		const shuffled = [...arr];
		for (let i = shuffled.length - 1; i > 0; i--) {
			const j = Math.floor(Math.random() * (i + 1));
			[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
		}
		return shuffled;
	}

	function rotateArray<T>(arr: T[], n: number): T[] {
		const len = arr.length;
		const offset = ((n % len) + len) % len;
		return [...arr.slice(offset), ...arr.slice(0, offset)];
	}

	const shuffled = $derived(shuffle(covers));

	let setWidthPx = $derived((coverSize + GAP) * (coversPerRow + 1));
	let staggerPx = $derived(Math.floor(coverSize / 2));

	let flyDelays: number[][] = $state([]);
	let flyOffsets: { x: number; y: number }[][] = $state([]);

	function calculateGrid() {
		const vw = window.innerWidth;
		const vh = window.innerHeight;

		if (vw >= 1024) {
			coversPerRow = 8;
		} else if (vw >= 640) {
			coversPerRow = 5;
		} else {
			coversPerRow = 3;
		}

		coverSize = Math.ceil(vw / coversPerRow);
		rowCount = Math.ceil(vh / coverSize) + 1;

		const cx = vw / 2;
		const cy = vh / 2;

		const newRows: Array<{ id: string; url: string }[]> = [];
		const newDelays: number[][] = [];
		const newOffsets: { x: number; y: number }[][] = [];
		for (let i = 0; i < rowCount; i++) {
			const rotated = rotateArray(shuffled, i * 7);
			const rowCovers = [];
			for (let j = 0; j < coversPerRow + 1; j++) {
				rowCovers.push(rotated[j % rotated.length]);
			}
			const fullRow = [...rowCovers, ...rowCovers, ...rowCovers, ...rowCovers];
			newRows.push(fullRow);
			newDelays.push(fullRow.map(() => Math.random() * 1));

			const setSize = coversPerRow + 1;
			const coverY = i * (coverSize + GAP) + coverSize / 2;
			const isRightRow = i % 2 === 1;
			const rowScrollOffset = isRightRow
				? setSize * (coverSize + GAP) + Math.floor(coverSize / 2)
				: 0;
			newOffsets.push(
				fullRow.map((_, j) => {
					const coverX = j * (coverSize + GAP) + coverSize / 2 - rowScrollOffset;
					if (
						coverX < -setSize * (coverSize + GAP) ||
						coverX > vw + setSize * (coverSize + GAP)
					) {
						return { x: 0, y: 0 };
					}
					const dx = coverX - cx;
					const dy = coverY - cy;
					return { x: dx * 1.5, y: dy * 1.5 };
				})
			);
		}
		rows = newRows;
		flyDelays = newDelays;
		flyOffsets = newOffsets;
	}

	onMount(() => {
		calculateGrid();
		requestAnimationFrame(() => {
			requestAnimationFrame(() => {
				ready = true;
			});
		});
		window.addEventListener('resize', calculateGrid);
		return () => window.removeEventListener('resize', calculateGrid);
	});
</script>

{#if coverSize > 0}
	{@html `<style>
		@keyframes scroll-left {
			from { transform: translateX(0px); }
			to { transform: translateX(-${setWidthPx}px); }
		}
		@keyframes scroll-right {
			from { transform: translateX(-${setWidthPx + staggerPx}px); }
			to { transform: translateX(-${staggerPx}px); }
		}
	</style>`}
{/if}

<div class="screensaver" style="--cover-size: {coverSize}px;">
	{#each rows as row, i}
		<div
			class="row"
			style="animation: {i % 2 === 0 ? 'scroll-left' : 'scroll-right'} 120s linear infinite;"
		>
			{#each row as cover, j}
				<img
					src={cover.url}
					alt=""
					class="cover"
					class:landed={ready}
					style="transition-delay: {flyDelays[i]?.[j]?.toFixed(3) ?? 0}s; --fly-x: {flyOffsets[i]?.[j]?.x?.toFixed(0) ?? 0}px; --fly-y: {flyOffsets[i]?.[j]?.y?.toFixed(0) ?? 0}px;"
					loading="eager"
					draggable="false"
					crossorigin="anonymous"
				/>
			{/each}
		</div>
	{/each}
	<div class="vignette"></div>
</div>

<style>
	.screensaver {
		position: fixed;
		inset: 0;
		background: #000;
		overflow: hidden;
	}

	.row {
		display: flex;
		gap: 3px;
		height: var(--cover-size);
		margin-bottom: 3px;
		will-change: transform;
	}

	.cover {
		width: var(--cover-size);
		height: var(--cover-size);
		min-width: var(--cover-size);
		object-fit: cover;
		display: block;
		user-select: none;
		-webkit-user-drag: none;

		transform: translate(var(--fly-x), var(--fly-y)) scale(1.8);
		opacity: 0;
		transition:
			transform 1s cubic-bezier(0.22, 1, 0.36, 1),
			opacity 0.4s ease-out;
	}

	.cover.landed {
		transform: translate(0, 0) scale(1);
		opacity: 1;
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
