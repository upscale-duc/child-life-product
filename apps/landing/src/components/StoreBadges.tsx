import appleDark from '../assets/figma/store-apple-dark.svg';
import apple from '../assets/figma/store-apple.svg';
import playDark from '../assets/figma/store-play-dark.svg';
import play from '../assets/figma/store-play.svg';
import { useSite } from '../context';
import { storeLinks } from '../site';

/** Store badges (spec §12). Figma draws placeholder glyphs, not the official badges — they must be
 *  replaced by Apple / Google artwork before launch. Until the listings exist (`storeLinks` null)
 *  a badge explains that the app is coming soon instead of linking. */
export function StoreBadges({ variant }: { variant: 'dark' | 'light' }) {
  const { c, notify } = useSite();
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
          <button
            key={store.key}
            type="button"
            className="badge pressable"
            onClick={() => notify(c.stores.comingSoon.replace('{store}', store.name))}
          >
            {inner}
          </button>
        );
      })}
    </div>
  );
}
