<script lang="ts">
	import {
		assembleSaverBundle,
		downloadBlob,
		type AssemblyProgress
	} from '$lib/services/bundleAssembler';
	import { allCovers } from '$lib/stores/covers';

	let building = $state(false);
	let progress = $state<AssemblyProgress | null>(null);
	let error = $state('');
	let done = $state(false);
	let blob = $state<Blob | null>(null);

	const coverCount = $derived($allCovers.length);

	const phaseLabel: Record<string, string> = {
		downloading: 'Downloading covers',
		assembling: 'Assembling bundle',
		done: 'Ready!'
	};

	const progressPercent = $derived(() => {
		if (!progress) return 0;
		if (progress.phase === 'done') return 100;
		if (progress.total === 0) return 0;
		const phaseWeight = progress.phase === 'downloading' ? 0.8 : 0.2;
		const phaseStart = progress.phase === 'downloading' ? 0 : 80;
		return phaseStart + (progress.current / progress.total) * phaseWeight * 100;
	});

	async function build() {
		if (coverCount === 0) return;

		building = true;
		error = '';
		done = false;
		blob = null;

		try {
			const urls = $allCovers.map((c) => c.url);
			blob = await assembleSaverBundle(urls, (p) => {
				progress = p;
			});
			done = true;
			downloadBlob(blob, 'TomtopiaSaver.zip');
		} catch (err) {
			error = err instanceof Error ? err.message : 'Build failed';
		} finally {
			building = false;
		}
	}

	function redownload() {
		if (blob) downloadBlob(blob, 'TomtopiaSaver.zip');
	}
</script>

<div class="build-section">
	{#if done && blob}
		<button class="build-btn done" onclick={redownload}>
			Download Again
		</button>
		<p class="hint">
			Extract the zip, then double-click <strong>Install Tomtopia Screensaver.command</strong>
		</p>
	{:else}
		<button class="build-btn" onclick={build} disabled={building || coverCount === 0}>
			{#if building}
				{phaseLabel[progress?.phase ?? 'downloading']}...
			{:else if coverCount === 0}
				Connect a service to get started
			{:else}
				Build Screensaver ({coverCount} covers)
			{/if}
		</button>
	{/if}

	{#if building && progress}
		<div class="progress-bar">
			<div class="progress-fill" style="width: {progressPercent()}%"></div>
		</div>
	{/if}

	{#if error}
		<p class="error">{error}</p>
	{/if}
</div>

<style>
	.build-section {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 16px;
	}

	.build-btn {
		padding: 16px 48px;
		border: none;
		border-radius: 16px;
		font-size: 18px;
		font-weight: 700;
		cursor: pointer;
		background: linear-gradient(135deg, #6366f1, #8b5cf6);
		color: white;
		transition: all 0.2s;
	}

	.build-btn:hover:not(:disabled) {
		transform: scale(1.02);
	}

	.build-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.build-btn.done {
		background: linear-gradient(135deg, #22c55e, #16a34a);
	}

	.progress-bar {
		width: 100%;
		max-width: 400px;
		height: 6px;
		background: rgba(255, 255, 255, 0.1);
		border-radius: 3px;
		overflow: hidden;
	}

	.progress-fill {
		height: 100%;
		background: linear-gradient(90deg, #6366f1, #8b5cf6);
		border-radius: 3px;
		transition: width 0.3s ease;
	}

	.hint {
		color: #888;
		font-size: 14px;
		text-align: center;
	}

	.hint strong {
		color: #ccc;
	}

	.error {
		color: #ff4444;
		font-size: 14px;
	}
</style>
