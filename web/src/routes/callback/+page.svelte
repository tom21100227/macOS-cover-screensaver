<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { exchangeCode } from '$lib/services/spotify';
	import { spotifyToken } from '$lib/stores/covers';

	let status = $state('Connecting to Spotify...');

	// Get Spotify client ID from page data or fallback
	const SPOTIFY_CLIENT_ID = $page.url.searchParams.get('state') || '';

	onMount(async () => {
		const code = $page.url.searchParams.get('code');
		const error = $page.url.searchParams.get('error');

		if (error) {
			status = `Spotify authorization failed: ${error}`;
			setTimeout(() => goto('/'), 3000);
			return;
		}

		if (!code) {
			status = 'No authorization code received.';
			setTimeout(() => goto('/'), 3000);
			return;
		}

		try {
			const clientId = sessionStorage.getItem('spotify_client_id') || '';
			const redirectUri = `${window.location.origin}/callback`;
			const token = await exchangeCode(code, clientId, redirectUri);
			$spotifyToken = token;
			goto('/');
		} catch (err) {
			status = `Error: ${err instanceof Error ? err.message : 'Unknown error'}`;
			setTimeout(() => goto('/'), 3000);
		}
	});
</script>

<div class="callback">
	<p>{status}</p>
</div>

<style>
	.callback {
		display: flex;
		align-items: center;
		justify-content: center;
		height: 100vh;
		background: #000;
		color: #fff;
		font-family: system-ui, sans-serif;
	}

	p {
		font-size: 18px;
		opacity: 0.8;
	}
</style>
