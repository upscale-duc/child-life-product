import appStoreEn from '../assets/badges/app-store-en.svg';
import appStoreVi from '../assets/badges/app-store-vi.svg';
import googlePlayEn from '../assets/badges/google-play-en.png';
import googlePlayVi from '../assets/badges/google-play-vi.png';
import { useSite } from '../context';
import { storeLinks } from '../site';

/** True once both store listings are published (`site.ts`). */
export const launched = Boolean(storeLinks.appStore && storeLinks.googlePlay);

// Official badge artwork per language (assets/badges/README.md), width : height.
const artwork = {
  vi: { appStore: appStoreVi, googlePlay: googlePlayVi },
  en: { appStore: appStoreEn, googlePlay: googlePlayEn },
} as const;
const ratio = { appStore: 119.66 / 40, googlePlay: 646 / 192 } as const;

/** App Store / Google Play badges: Apple's and Google's official artwork (V9, owner 2026-10-21).
 *  "V8/CTA tải app" forbids a download button that only says "sắp có": until a listing exists
 *  its badge is a plain picture (owner, 2026-10-19), and becomes a link to the store page as soon
 *  as `storeLinks` has it. */
export function StoreBadges() {
  const { c, route } = useSite();
  const stores = (['appStore', 'googlePlay'] as const).map((key) => ({
    key,
    href: storeLinks[key],
    src: artwork[route.locale][key],
    alt: `${c.stores[key].prefix} ${c.stores[key].name}`,
  }));
  return (
    <div className="badges">
      {stores.map((store) => {
        const img = (
          <img
            src={store.src}
            alt={store.href ? store.alt : ''}
            width={Math.round(48 * ratio[store.key])}
            height={48}
          />
        );
        return store.href ? (
          <a key={store.key} className="badge pressable" href={store.href} rel="noopener">
            {img}
          </a>
        ) : (
          <span key={store.key} className="badge badge--static" aria-hidden="true">
            {img}
          </span>
        );
      })}
    </div>
  );
}

/** "V8/CTA tải app" (Figma 734:5426): the badges and a caption. Before launch the caption says
 *  the app is coming (the badges are not links then); after launch the hero drops it (V9) and
 *  the closing card says it is free. The "Trước ra mắt" email variant needs a real sign-up flow
 *  and is not built (R-170). */
export function AppCta({
  tone = 'light',
  caption = true,
}: {
  tone?: 'light' | 'dark';
  caption?: boolean;
}) {
  const { c } = useSite();
  const text = launched ? (caption ? c.stores.caption : null) : c.stores.captionSoon;
  return (
    <div className={`app-cta app-cta--${tone}`}>
      <StoreBadges />
      {text && <p className="app-cta__caption">{text}</p>}
    </div>
  );
}
