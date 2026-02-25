<script lang="ts">
	import { authorize, fetchAlbumCovers } from '$lib/services/appleMusic';
	import { appleMusicCovers, appleMusicConnected } from '$lib/stores/covers';

	let loading = $state(false);
	let error = $state('');
	let albumCount = $state(0);

	async function connect() {
		loading = true;
		error = '';
		try {
			await authorize();
			$appleMusicConnected = true;

			const covers = await fetchAlbumCovers();
			albumCount = covers.length;
			$appleMusicCovers = covers.map((c) => ({
				...c,
				source: 'apple' as const
			}));
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to connect';
		} finally {
			loading = false;
		}
	}
</script>

{#if $appleMusicConnected}
	<div class="connected">
		<span class="badge">Apple Music</span>
		<span class="count">{albumCount} albums</span>
	</div>
{:else}
	<button class="connect-btn apple" onclick={connect} disabled={loading}>
		{#if loading}
			Connecting...
		{:else}
			Connect Apple Music
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

	.connect-btn.apple {
		background: linear-gradient(135deg, #fc3c44, #d42f37);
		color: white;
	}

	.connected {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.badge {
		background: #fc3c44;
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
