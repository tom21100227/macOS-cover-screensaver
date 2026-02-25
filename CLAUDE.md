# macOS Cover Screensaver

## Architecture

macOS `.saver` bundle using **pure Core Animation** (CALayer). WKWebView is completely broken in the screensaver sandbox — `legacyScreenSaver`'s WebContent subprocess can't connect to system services.

### How It Works
1. `TomtopiaSaverView` (ScreenSaverView subclass) loads cover JPGs from bundle `Resources/covers/`
2. Builds a grid of CALayers: rows of album covers, 4x repeated for seamless scrolling
3. Each row scrolls horizontally via `CABasicAnimation(keyPath: "position.x")`, alternating left/right
4. Fly-in animation on startup: covers scale+translate from center outward with staggered delays
5. Radial vignette gradient overlay on top

### Grid Math (ported from CoverGrid.svelte)
- `coversPerRow`: 8 (>=1024px), 5 (>=640px), 3 (else)
- `coverSize = ceil(viewWidth / coversPerRow)`
- `rowCount = ceil(viewHeight / coverSize) + 1`
- Each row = 4 copies of `(coversPerRow + 1)` covers
- Scroll duration: 120s, infinite repeat
- Fly-in offset: `(coverX - centerX) * 1.5` with random 0-1s delay

## Build & Install

```bash
make install    # copies covers → builds .saver → installs to ~/Library/Screen Savers/
make clean      # removes build artifacts
make sign       # codesign with Developer ID
make notarize   # notarize + staple (requires APPLE_ID, TEAM_ID, APP_PASSWORD env vars)
```

## Key Technical Decisions

### WKWebView Does NOT Work in Screensaver Sandbox
The `legacyScreenSaver` process blocks WebContent subprocess from connecting to launchservicesd, CoreServices, RunningBoard. Tried `loadFileURL`, `loadHTMLString`, base64 data URIs — all fail. Must use in-process rendering (Core Animation).

### Animation Snap-Back Prevention
Model layer must be set to **final state** before adding animations. Animate FROM start values. Use `fillMode = .backwards` + `isRemovedOnCompletion = true`. The screensaver engine creates/destroys view instances unpredictably — if animations are removed while using `fillMode = .forwards`, all layers snap back to their pre-animation state (opacity 0, scaled/translated), causing a visible flicker.

### CGImage Required for CALayer.contents
`NSImage` does not render in CALayer.contents in the screensaver context. Must convert via `img.cgImage(forProposedRect:context:hints:)`.

### legacyScreenSaver Engine Quirks
- Creates multiple view instances without destroying old ones
- `stopAnimation()` unreliable on Sonoma/Sequoia
- `startAnimation()` called multiple times in quick succession
- Preview instances (frame {0,0}) created alongside fullscreen instances
- Must handle grid rebuild if sublayers go missing between start/stop cycles

## Apple Developer

- Team ID: 7L9GYT487J
- Signing Identity: "Developer ID Application: Chongye Han (7L9GYT487J)"
- Credentials in `.env` (gitignored)

## Current Cover Source: Discogs

Covers are currently 49 static JPGs downloaded from a Discogs collection. These are temporary.

- **API**: `GET https://api.discogs.com/users/ThomHan/collection/folders/0/releases?token={TOKEN}&per_page=100`
- **Auth**: Personal access token as query param, stored in `.env` as `DISCOGS_TOKEN`
- **Images**: `basic_information.cover_image` field, served from `i.discogs.com` (signed URLs)
- **Local cache**: Downloaded to `covers/` directory, named by release ID (e.g., `31943833.jpg`)

## Planned: Dynamic Cover Sources

The current static JPG approach is temporary. Future versions should pull covers dynamically from:

### Apple Music (MusicKit)
- Use MusicKit / Apple Music API to fetch user's library or top albums
- Requires Apple Developer membership and MusicKit entitlement
- Could use `MusicCatalogSearchRequest` for top charts or `MusicLibraryRequest` for user library
- Auth: MusicKit uses device-level authorization (Sign in with Apple Music prompt)
- Cover art available via `Artwork` type with configurable resolution

### Spotify
- Use Spotify Web API to fetch user's saved albums or top artists
- Endpoint: `GET /v1/me/albums` (saved albums) or `GET /v1/me/top/artists` (top artists with images)
- Auth: OAuth 2.0 with PKCE flow, scopes: `user-library-read`, `user-top-read`
- Cover art in `album.images[]` array with multiple sizes

### Integration Architecture
The screensaver should:
1. Have a preferences pane (configureSheet) to select data source and authenticate
2. Cache downloaded covers locally in `~/Library/Application Support/TomtopiaSaver/`
3. Periodically refresh covers in the background
4. Fall back to bundled covers if no network / no auth
5. Support mixing sources (e.g., Discogs + Spotify)
