import { spawn } from 'node:child_process';
const id = process.argv[2] ?? 'S01';
if (!/^S(0[1-9]|1[01])(-Vertical)?$/.test(id))
  throw new Error('Use S01 … S11, optionally -Vertical');
spawn('pnpm', ['exec', 'remotion', 'studio', 'src/index.ts', id, '--port=3010'], {
  stdio: 'inherit',
});
