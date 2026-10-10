/** Languages shipped in V1 (D-012). Vietnamese is the source language and the fallback. */
export const supportedLocales = ['vi', 'en'] as const;
export type SupportedLocale = (typeof supportedLocales)[number];
export const fallbackLocale: SupportedLocale = 'vi';

const storageKey = 'childlife.locale';

function asSupported(tag: string | null | undefined): SupportedLocale | null {
  const language = tag?.toLowerCase().split(/[-_]/)[0];
  return (supportedLocales as readonly string[]).includes(language ?? '')
    ? (language as SupportedLocale)
    : null;
}

/** Explicit choice → first supported browser language → Vietnamese. */
export function resolveLocale(
  saved: string | null | undefined,
  browserLanguages: readonly string[],
): SupportedLocale {
  const explicit = asSupported(saved);
  if (explicit) return explicit;
  for (const tag of browserLanguages) {
    const match = asSupported(tag);
    if (match) return match;
  }
  return fallbackLocale;
}

/** Browser helpers; storage can be unavailable (private mode), so failures are ignored. */
export function readSavedLocale(): string | null {
  try {
    return globalThis.localStorage?.getItem(storageKey) ?? null;
  } catch {
    return null;
  }
}

export function saveLocale(locale: SupportedLocale): void {
  try {
    globalThis.localStorage?.setItem(storageKey, locale);
  } catch {
    // Not persisted; the choice still applies to this page view.
  }
}
