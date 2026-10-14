import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { createServer, type Server } from 'node:http';
import { basename, join } from 'node:path';

/**
 * Serves one folder to the headless browser on 127.0.0.1 only: the job's photos and music are
 * private (never a public URL, D-068 security), so the browser reads them from this machine.
 */
export async function serveFolder(
  dir: string,
): Promise<{ url: (file: string) => string; close: () => Promise<void> }> {
  const types: Record<string, string> = {
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    png: 'image/png',
    webp: 'image/webp',
    mp3: 'audio/mpeg',
    m4a: 'audio/mp4',
  };
  const server: Server = createServer(async (req, res) => {
    const name = basename(decodeURIComponent((req.url ?? '/').split('?')[0]!));
    const path = join(dir, name);
    try {
      const s = await stat(path);
      res.writeHead(200, {
        'Content-Type': types[name.split('.').pop() ?? ''] ?? 'application/octet-stream',
        'Content-Length': s.size,
        'Access-Control-Allow-Origin': '*',
      });
      createReadStream(path).pipe(res);
    } catch {
      res.writeHead(404).end();
    }
  });
  await new Promise<void>((ok) => server.listen(0, '127.0.0.1', ok));
  const port = (server.address() as { port: number }).port;
  return {
    url: (file) => `http://127.0.0.1:${port}/${encodeURIComponent(file)}`,
    close: () => new Promise((ok) => server.close(() => ok())),
  };
}
