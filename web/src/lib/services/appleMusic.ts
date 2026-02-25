export interface AppleMusicCover {
	id: string;
	url: string;
	name: string;
	artist: string;
}

let musicInstance: MusicKitInstance | null = null;

async function loadMusicKit(): Promise<void> {
	if (typeof MusicKit !== 'undefined') return;

	return new Promise((resolve, reject) => {
		const script = document.createElement('script');
		script.src = 'https://js-cdn.music.apple.com/musickit/v3/musickit.js';
		script.onload = () => {
			// MusicKit needs a moment after script load
			const check = () => {
				if (typeof MusicKit !== 'undefined') resolve();
				else setTimeout(check, 100);
			};
			check();
		};
		script.onerror = () => reject(new Error('Failed to load MusicKit JS'));
		document.head.appendChild(script);
	});
}

export async function authorize(): Promise<void> {
	await loadMusicKit();

	const res = await fetch('/api/apple-token');
	const { developerToken, error } = await res.json();
	if (error) throw new Error(error);

	await MusicKit.configure({
		developerToken,
		app: { name: 'Tomtopia Screensaver', build: '1.0.0' }
	});

	musicInstance = MusicKit.getInstance();
	await musicInstance.authorize();
}

export async function fetchAlbumCovers(): Promise<AppleMusicCover[]> {
	if (!musicInstance) throw new Error('Not authorized');

	const covers: AppleMusicCover[] = [];
	let url = '/v1/me/library/albums';
	const params: Record<string, unknown> = { limit: 100 };

	while (url) {
		const response = await musicInstance.api.music(url, params);
		const data = response.data;

		for (const album of data.data) {
			if (album.attributes.artwork?.url) {
				covers.push({
					id: album.id,
					url: album.attributes.artwork.url
						.replace('{w}', '500')
						.replace('{h}', '500'),
					name: album.attributes.name,
					artist: album.attributes.artistName
				});
			}
		}

		url = data.next ?? '';
		// After first request, don't pass params (next URL includes them)
		if (url) {
			Object.keys(params).forEach((k) => delete params[k]);
		}
	}

	return covers;
}
