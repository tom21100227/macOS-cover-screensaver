/// <reference types="@sveltejs/kit" />
/// <reference types="@cloudflare/workers-types" />

declare global {
	namespace App {
		interface Platform {
			env: {
				APPLE_TEAM_ID: string;
				APPLE_KEY_ID: string;
				APPLE_PRIVATE_KEY: string;
				SPOTIFY_CLIENT_ID: string;
			};
		}
	}

	interface MusicKitInstance {
		authorize(): Promise<string>;
		musicUserToken: string;
		api: {
			music(path: string, params?: Record<string, unknown>): Promise<{
				data: {
					data: Array<{
						id: string;
						attributes: {
							name: string;
							artistName: string;
							artwork?: {
								url: string;
							};
						};
					}>;
					next?: string;
				};
			}>;
		};
	}

	interface MusicKitStatic {
		configure(config: {
			developerToken: string;
			app: { name: string; build: string };
		}): Promise<void>;
		getInstance(): MusicKitInstance;
	}

	const MusicKit: MusicKitStatic;
}

export {};
