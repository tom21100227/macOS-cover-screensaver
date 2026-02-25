export interface SpotifyCover {
	id: string;
	url: string;
	name: string;
	artist: string;
}

const SPOTIFY_AUTH_URL = 'https://accounts.spotify.com/authorize';
const SPOTIFY_TOKEN_URL = 'https://accounts.spotify.com/api/token';
const SPOTIFY_ALBUMS_URL = 'https://api.spotify.com/v1/me/albums';

function generateRandomString(length: number): string {
	const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
	const values = crypto.getRandomValues(new Uint8Array(length));
	return Array.from(values, (v) => chars[v % chars.length]).join('');
}

async function sha256(plain: string): Promise<ArrayBuffer> {
	const encoder = new TextEncoder();
	return crypto.subtle.digest('SHA-256', encoder.encode(plain));
}

function base64url(buffer: ArrayBuffer): string {
	return btoa(String.fromCharCode(...new Uint8Array(buffer)))
		.replace(/\+/g, '-')
		.replace(/\//g, '_')
		.replace(/=+$/, '');
}

export async function startAuth(clientId: string, redirectUri: string): Promise<void> {
	const codeVerifier = generateRandomString(128);
	sessionStorage.setItem('spotify_code_verifier', codeVerifier);
	sessionStorage.setItem('spotify_client_id', clientId);

	const challengeBuffer = await sha256(codeVerifier);
	const codeChallenge = base64url(challengeBuffer);

	const params = new URLSearchParams({
		client_id: clientId,
		response_type: 'code',
		redirect_uri: redirectUri,
		scope: 'user-library-read',
		code_challenge_method: 'S256',
		code_challenge: codeChallenge
	});

	window.location.href = `${SPOTIFY_AUTH_URL}?${params}`;
}

export async function exchangeCode(
	code: string,
	clientId: string,
	redirectUri: string
): Promise<string> {
	const codeVerifier = sessionStorage.getItem('spotify_code_verifier');
	if (!codeVerifier) throw new Error('No code verifier found');

	const res = await fetch(SPOTIFY_TOKEN_URL, {
		method: 'POST',
		headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
		body: new URLSearchParams({
			client_id: clientId,
			grant_type: 'authorization_code',
			code,
			redirect_uri: redirectUri,
			code_verifier: codeVerifier
		})
	});

	const data = await res.json();
	if (data.error) throw new Error(data.error_description || data.error);

	sessionStorage.removeItem('spotify_code_verifier');
	return data.access_token;
}

export async function fetchAlbumCovers(accessToken: string): Promise<SpotifyCover[]> {
	const covers: SpotifyCover[] = [];
	let url: string | null = `${SPOTIFY_ALBUMS_URL}?limit=50`;

	while (url) {
		const res = await fetch(url, {
			headers: { Authorization: `Bearer ${accessToken}` }
		});

		if (!res.ok) throw new Error(`Spotify API error: ${res.status}`);

		const data = await res.json();

		for (const item of data.items) {
			const album = item.album;
			if (album.images?.[0]?.url) {
				covers.push({
					id: album.id,
					url: album.images[0].url,
					name: album.name,
					artist: album.artists.map((a: { name: string }) => a.name).join(', ')
				});
			}
		}

		url = data.next;
	}

	return covers;
}
