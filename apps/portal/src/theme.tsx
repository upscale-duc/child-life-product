import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

/** Light, dark or the system setting (D-063); remembered on this browser. */
export type ThemeMode = 'light' | 'dark' | 'system';
type Resolved = 'light' | 'dark';

const storageKey = 'childlife.portal.theme';
const darkQuery = '(prefers-color-scheme: dark)';

export function readThemeMode(): ThemeMode {
  try {
    const v = globalThis.localStorage?.getItem(storageKey);
    return v === 'light' || v === 'dark' || v === 'system' ? v : 'system';
  } catch {
    return 'system';
  }
}

function resolve(mode: ThemeMode): Resolved {
  if (mode !== 'system') return mode;
  return typeof window !== 'undefined' && window.matchMedia?.(darkQuery).matches ? 'dark' : 'light';
}

/** Sets `data-theme` on <html>: the shadcn tokens and the design tokens both follow it. */
export function applyTheme(mode: ThemeMode): Resolved {
  const resolved = resolve(mode);
  if (typeof document !== 'undefined') document.documentElement.dataset.theme = resolved;
  return resolved;
}

const ThemeContext = createContext<{
  mode: ThemeMode;
  resolved: Resolved;
  setMode: (m: ThemeMode) => void;
}>({ mode: 'system', resolved: 'light', setMode: () => undefined });

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [mode, setMode] = useState<ThemeMode>(readThemeMode);
  const [resolved, setResolved] = useState<Resolved>(() => resolve(mode));
  useEffect(() => {
    setResolved(applyTheme(mode));
    try {
      globalThis.localStorage?.setItem(storageKey, mode);
    } catch {
      // Private mode: back to the system setting next time.
    }
    if (mode !== 'system' || !window.matchMedia) return;
    const mql = window.matchMedia(darkQuery);
    const onChange = () => setResolved(applyTheme('system'));
    mql.addEventListener('change', onChange);
    return () => mql.removeEventListener('change', onChange);
  }, [mode]);
  const value = useMemo(() => ({ mode, resolved, setMode }), [mode, resolved]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  return useContext(ThemeContext);
}
