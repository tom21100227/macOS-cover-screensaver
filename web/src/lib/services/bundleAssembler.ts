import JSZip from 'jszip';

export interface AssemblyProgress {
	phase: 'downloading' | 'assembling' | 'done';
	current: number;
	total: number;
}

export async function assembleSaverBundle(
	coverUrls: string[],
	onProgress?: (progress: AssemblyProgress) => void
): Promise<Blob> {
	const zip = new JSZip();
	const saverDir = zip.folder('TomtopiaSaver.saver/Contents')!;

	// Fetch pre-built template files
	onProgress?.({ phase: 'downloading', current: 0, total: coverUrls.length + 2 });

	const [binaryRes, plistRes] = await Promise.all([
		fetch('/saver-template/TomtopiaSaver'),
		fetch('/saver-template/Info.plist')
	]);

	if (!binaryRes.ok || !plistRes.ok) {
		throw new Error('Failed to fetch saver template files. Has `make saver-template` been run?');
	}

	const binary = await binaryRes.arrayBuffer();
	const plist = await plistRes.text();

	saverDir.file('MacOS/TomtopiaSaver', binary);
	saverDir.file('Info.plist', plist);

	onProgress?.({ phase: 'downloading', current: 2, total: coverUrls.length + 2 });

	// Download all cover images
	const coversDir = saverDir.folder('Resources/covers')!;

	// Download in batches of 10 to avoid overwhelming the browser
	const batchSize = 10;
	for (let i = 0; i < coverUrls.length; i += batchSize) {
		const batch = coverUrls.slice(i, i + batchSize);
		const blobs = await Promise.all(
			batch.map(async (url) => {
				const res = await fetch(url);
				if (!res.ok) throw new Error(`Failed to download cover: ${url}`);
				return res.arrayBuffer();
			})
		);

		blobs.forEach((blob, j) => {
			coversDir.file(`${i + j + 1}.jpg`, blob);
		});

		onProgress?.({
			phase: 'downloading',
			current: Math.min(i + batchSize, coverUrls.length) + 2,
			total: coverUrls.length + 2
		});
	}

	// Add install script
	const installScript = `#!/bin/bash
cd "$(dirname "$0")"
echo "Installing Tomtopia Screensaver..."
codesign --force --sign - TomtopiaSaver.saver
cp -r TomtopiaSaver.saver ~/Library/Screen\\ Savers/
echo ""
echo "Installed! Open System Settings > Screen Saver to select Tomtopia."
echo "Press any key to close..."
read -n 1
`;

	zip.file('Install Tomtopia Screensaver.command', installScript, {
		unixPermissions: '755'
	});

	// Generate zip
	onProgress?.({ phase: 'assembling', current: 0, total: 1 });

	const blob = await zip.generateAsync(
		{ type: 'blob', platform: 'UNIX' },
		(metadata) => {
			onProgress?.({
				phase: 'assembling',
				current: Math.round(metadata.percent),
				total: 100
			});
		}
	);

	onProgress?.({ phase: 'done', current: 1, total: 1 });

	return blob;
}

export function downloadBlob(blob: Blob, filename: string) {
	const url = URL.createObjectURL(blob);
	const a = document.createElement('a');
	a.href = url;
	a.download = filename;
	document.body.appendChild(a);
	a.click();
	document.body.removeChild(a);
	URL.revokeObjectURL(url);
}
