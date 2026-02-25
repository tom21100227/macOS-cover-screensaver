<script lang="ts">
	import CoverPreview from '$lib/components/CoverPreview.svelte';
	import AppleMusicConnect from '$lib/components/AppleMusicConnect.svelte';
	import SpotifyConnect from '$lib/components/SpotifyConnect.svelte';
	import BuildDownload from '$lib/components/BuildDownload.svelte';
	import { allCovers, appleMusicConnected, spotifyConnected } from '$lib/stores/covers';

	const SPOTIFY_CLIENT_ID = import.meta.env.VITE_SPOTIFY_CLIENT_ID || '';
	const redirectUri = typeof window !== 'undefined' ? `${window.location.origin}/callback` : '';

	const hasCovers = $derived($allCovers.length > 0);
	const isConnected = $derived($appleMusicConnected || $spotifyConnected);
</script>

<svelte:head>
	<title>Tomtopia Screensaver</title>
	<meta name="description" content="Build a custom macOS screensaver from your music library" />
</svelte:head>

<CoverPreview />

<div class="ui-overlay">
	<div class="panel">
		{#if !isConnected}
			<h1>Tomtopia Screensaver</h1>
			<p class="subtitle">
				A macOS screensaver built from your album art.
				Connect your music library to get started.
			</p>
		{/if}

		<div class="services">
			<AppleMusicConnect />
			<SpotifyConnect clientId={SPOTIFY_CLIENT_ID} {redirectUri} />
		</div>

		{#if hasCovers}
			<div class="divider"></div>
			<BuildDownload />
		{/if}
	</div>
</div>

<style>
	:global(body) {
		margin: 0;
		background: #000;
		color: #fff;
		font-family: system-ui, -apple-system, sans-serif;
	}

	.ui-overlay {
		position: fixed;
		inset: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 20;
		pointer-events: none;
	}

	.panel {
		pointer-events: auto;
		background: rgba(0, 0, 0, 0.85);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: 24px;
		padding: 48px;
		max-width: 480px;
		width: calc(100% - 32px);
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 24px;
		text-align: center;
	}

	h1 {
		font-size: 32px;
		font-weight: 700;
		margin: 0;
		letter-spacing: -0.5px;
	}

	.subtitle {
		color: #888;
		font-size: 16px;
		line-height: 1.5;
		margin: 0;
	}

	.services {
		display: flex;
		flex-direction: column;
		gap: 12px;
		width: 100%;
		align-items: center;
	}

	.divider {
		width: 60px;
		height: 1px;
		background: rgba(255, 255, 255, 0.1);
	}
</style>
