import appleDark from '../assets/figma/store-apple-dark.svg';
import apple from '../assets/figma/store-apple.svg';
import playDark from '../assets/figma/store-play-dark.svg';
import play from '../assets/figma/store-play.svg';
import { useSite } from '../context';
import { storeLinks } from '../site';

/** True once both store listings are published (`site.ts`). */
export const launched = Boolean(storeLinks.appStore && storeLinks.googlePlay);

/** Store badges (spec §12). Figma draws placeholder glyphs, not the official badges — they must be
 *  replaced by Apple / Google artwork before launch. "V8/CTA tải app" (Figma 734:5426) forbids a
 *  download button that only says "sắp có": until a listing exists its badge is a plain picture
 *  (owner, 2026-10-19), and becomes a link to the store page as soon as `storeLinks` has it. */
export function StoreBadges({ variant }: { variant: 'dark' | 'light' }) {
  const { c } = useSite();
  const stores = [
    {
      key: 'appStore',
      href: storeLinks.appStore,
      glyph: variant === 'dark' ? apple : appleDark,
      ...c.stores.appStore,
    },
    {
      key: 'googlePlay',
      href: storeLinks.googlePlay,
      glyph: variant === 'dark' ? play : playDark,
      ...c.stores.googlePlay,
    },
  ] as const;

  return (
    <div className={`badges badges--${variant}`}>
      {stores.map((store) => {
        const inner = (
          <>
            <img className="badge__glyph" src={store.glyph} alt="" width={25} height={25} />
            <span className="badge__text">
              <span className="badge__prefix">{store.prefix}</span>
              <span className="badge__name">{store.name}</span>
            </span>
          </>
        );
        return store.href ? (
          <a key={store.key} className="badge pressable" href={store.href} rel="noopener">
            {inner}
          </a>
        ) : (
          <span key={store.key} className="badge badge--static" aria-hidden="true">
            {inner}
          </span>
        );
      })}
    </div>
  );
}

/** "V8/CTA tải app" (Figma 734:5426), the "Sau ra mắt" variant: two badges and a caption. Before
 *  launch the caption says the app is coming instead of "Tải miễn phí…" (the badges are not links
 *  then). The "Trước ra mắt" email variant needs a real sign-up flow and is not built (R-170). */
export function AppCta({ tone = 'light' }: { tone?: 'light' | 'dark' }) {
  const { c } = useSite();
  return (
    <div className={`app-cta app-cta--${tone}`}>
      <StoreBadges variant="light" />
      <p className="app-cta__caption">{launched ? c.stores.caption : c.stores.captionSoon}</p>
    </div>
  );
}
