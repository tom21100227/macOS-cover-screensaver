import { json } from '@sveltejs/kit';
import { SignJWT, importPKCS8 } from 'jose';
import type { RequestHandler } from './$types';

let cachedToken: { token: string; expiresAt: number } | null = null;

export const GET: RequestHandler = async ({ platform }) => {
	const env = platform?.env;
	if (!env?.APPLE_TEAM_ID || !env?.APPLE_KEY_ID || !env?.APPLE_PRIVATE_KEY) {
		return json({ error: 'Apple Music credentials not configured' }, { status: 500 });
	}

	// Return cached token if still valid (with 10min buffer)
	if (cachedToken && cachedToken.expiresAt > Date.now() + 10 * 60 * 1000) {
		return json({ developerToken: cachedToken.token });
	}

	try {
		const privateKey = await importPKCS8(env.APPLE_PRIVATE_KEY, 'ES256');

		const token = await new SignJWT({})
			.setProtectedHeader({ alg: 'ES256', kid: env.APPLE_KEY_ID })
			.setIssuedAt()
			.setIssuer(env.APPLE_TEAM_ID)
			.setExpirationTime('1h')
			.sign(privateKey);

		cachedToken = { token, expiresAt: Date.now() + 60 * 60 * 1000 };

		return json({ developerToken: token });
	} catch (err) {
		console.error('Apple Music token generation error:', err);
		return json({ error: 'Failed to generate developer token' }, { status: 500 });
	}
};
