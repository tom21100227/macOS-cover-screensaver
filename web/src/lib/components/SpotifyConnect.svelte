<script lang="ts">
	import { startAuth, fetchAlbumCovers } from '$lib/services/spotify';
	import { spotifyCovers, spotifyConnected, spotifyToken } from '$lib/stores/covers';

	interface Props {
		clientId: string;
		redirectUri: string;
	}

	let { clientId, redirectUri }: Props = $props();

	let loading = $state(false);
	let error = $state('');
	let albumCount = $state(0);

	// If we already have a token (from callback), fetch albums
	$effect(() => {
		if ($spotifyToken && !$spotifyConnected) {
			fetchAlbums($spotifyToken);
		}
	});

	async function connect() {
		loading = true;
		error = '';
		try {
			await startAuth(clientId, redirectUri);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to connect';
			loading = false;
		}
	}

	async function fetchAlbums(token: string) {
		loading = true;
		error = '';
		try {
			const covers = await fetchAlbumCovers(token);
			albumCount = covers.length;
			$spotifyCovers = covers.map((c) => ({
				...c,
				source: 'spotify' as const
			}));
			$spotifyConnected = true;
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to fetch albums';
		} finally {
			loading = false;
		}
	}
</script>

{#if $spotifyConnected}
	<div class="connected">
		<span class="badge">Spotify</span>
		<span class="count">{albumCount} albums</span>
	</div>
{:else}
	<button class="connect-btn spotify" onclick={connect} disabled={loading}>
		{#if loading}
			Connecting...
		{:else}
			Connect Spotify
		{/if}
	</button>
	{#if error}
		<p class="error">{error}</p>
	{/if}
{/if}

<style>
	.connect-btn {
		padding: 12px 24px;
		border: none;
		border-radius: 12px;
		font-size: 16px;
		font-weight: 600;
		cursor: pointer;
		transition: opacity 0.2s;
	}

	.connect-btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.connect-btn.spotify {
		background: linear-gradient(135deg, #1db954, #1aa34a);
		color: white;
	}

	.connected {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.badge {
		background: #1db954;
		color: white;
		padding: 4px 12px;
		border-radius: 20px;
		font-size: 14px;
		font-weight: 600;
	}

	.count {
		color: #aaa;
		font-size: 14px;
	}

	.error {
		color: #ff4444;
		font-size: 14px;
		margin-top: 8px;
	}
</style>
