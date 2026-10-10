import type { Environment } from '@child-life/contracts';
import { readSavedLocale, resolveLocale, saveLocale } from '@child-life/web-config';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Footer, Nav, Toast } from './components/Chrome';
import { Icon } from './components/primitives';
import { contentFor } from './content';
import { SiteContext, type Site } from './context';
import { startFit, startLocaleLinks, startNav, startStoryFonts, startTicking } from './effects';
import { startReveal } from './motion';
import { Home } from './pages/Home';
import { Legal } from './pages/Legal';
import { alternateOf, pathOf, type Route } from './routes';

/** Landing site (Slice S14): Figma Website 219:1391 / 233:804, Vietnamese at / and English at /en/. */
export function App({ route, environment }: { route: Route; environment: Environment }) {
  const c = contentFor(route.locale);
  const other = alternateOf(route, route.locale === 'vi' ? 'en' : 'vi');
  const [toast, setToast] = useState<string | null>(null);
  const [suggest, setSuggest] = useState(false);
  const toastTimer = useRef<number | undefined>(undefined);

  const notify = useCallback((message: string) => {
    setToast(message);
    window.clearTimeout(toastTimer.current);
    toastTimer.current = window.setTimeout(() => setToast(null), 4500);
  }, []);

  const site = useMemo<Site>(
    () => ({ c, route, homePath: pathOf('home', route.locale), notify }),
    [c, route, notify],
  );

  useEffect(() => {
    const stops = [
      startReveal(),
      startFit(),
      startTicking(),
      startNav(),
      startLocaleLinks(),
      startStoryFonts(),
    ];
    return () => stops.forEach((stop) => stop());
  }, []);

  useEffect(() => {
    // Suggest the visitor's language (saved choice, else browser) but never redirect: search
    // engines and shared links always get the page they asked for.
    if (resolveLocale(readSavedLocale(), navigator.languages) === other.locale) setSuggest(true);
  }, [other]);

  const suggestion = contentFor(other.locale).languageSuggestion;

  return (
    <SiteContext.Provider value={site}>
      <a className="skip-link" href="#main">
        {c.skipToContent}
      </a>
      <Nav />
      <main id="main">{route.page === 'home' ? <Home /> : <Legal page={route.page} />}</main>
      <Footer environment={environment} />
      <Toast message={toast} onClose={() => setToast(null)} closeLabel={c.stores.close} />
      {suggest && (
        <aside className="lang-suggest" lang={other.locale} aria-label={suggestion.text}>
          <Icon name="globe" size={18} />
          <span>{suggestion.text}</span>
          <a href={other.path} hrefLang={other.locale} data-locale={other.locale}>
            {suggestion.action}
          </a>
          <button
            type="button"
            className="lang-suggest__close pressable"
            aria-label={suggestion.dismiss}
            onClick={() => {
              saveLocale(route.locale);
              setSuggest(false);
            }}
          >
            <Icon name="close" size={16} />
          </button>
        </aside>
      )}
    </SiteContext.Provider>
  );
}
