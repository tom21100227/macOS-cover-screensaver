import { writable, derived } from 'svelte/store';

export interface Cover {
	id: string;
	url: string;
	name: string;
	artist: string;
	source: 'apple' | 'spotify';
}

export const appleMusicCovers = writable<Cover[]>([]);
export const spotifyCovers = writable<Cover[]>([]);

export const allCovers = derived(
	[appleMusicCovers, spotifyCovers],
	([$apple, $spotify]) => {
		// Deduplicate by album name + artist (cross-service)
		const seen = new Set<string>();
		const combined: Cover[] = [];

		for (const cover of [...$apple, ...$spotify]) {
			const key = `${cover.name.toLowerCase()}::${cover.artist.toLowerCase()}`;
			if (!seen.has(key)) {
				seen.add(key);
				combined.push(cover);
			}
		}

		return combined;
	}
);

export const appleMusicConnected = writable(false);
export const spotifyConnected = writable(false);
export const spotifyToken = writable<string | null>(null);
