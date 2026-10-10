import { useSite } from '../context';
import { alternateOf, pathOf } from '../routes';
import { Icon, Lockup } from './primitives';

const sectionIds = ['cham-con', 'hieu-con', 'ky-niem', 'gia-dinh', 'hoi-dap'] as const;

/** Nav (spec §1). Sticky with a frosted background once the page scrolls (not in Figma);
 *  section links on desktop only, as designed; the language switch is an addition (D-012). */
export function Nav() {
  const { c, route, homePath } = useSite();
  const other = alternateOf(route, route.locale === 'vi' ? 'en' : 'vi');
  const base = route.page === 'home' ? '' : homePath;
  const labels = [
    c.nav.links.care,
    c.nav.links.understand,
    c.nav.links.memories,
    c.nav.links.family,
    c.nav.links.faq,
  ];
  return (
    <header className="nav" data-nav="">
      <div className="nav__inner container">
        <a className="nav__logo" href={homePath} aria-label={c.nav.homeLabel}>
          <Lockup />
        </a>
        <nav className="nav__links" aria-label={c.nav.sectionsLabel}>
          {sectionIds.map((id, i) => (
            <a key={id} href={`${base}#${id}`} data-spy={route.page === 'home' ? id : undefined}>
              {labels[i]}
            </a>
          ))}
        </nav>
        <div className="nav__actions">
          <a
            className="nav__lang pressable"
            href={other.path}
            hrefLang={other.locale}
            data-locale={other.locale}
          >
            <Icon name="globe" size={16} />
            <span aria-hidden="true">{c.nav.switchShort}</span>
            <span className="sr-only" lang={other.locale}>
              {c.nav.switchLabel}
            </span>
          </a>
          <a className="nav__cta pressable" href={`${base}#tai-app`}>
            <span className="only-desktop-inline">{c.nav.download}</span>
            <span className="only-mobile-inline">{c.nav.downloadShort}</span>
          </a>
        </div>
      </div>
    </header>
  );
}

/** Footer (spec §11). */
export function Footer({ environment }: { environment: string }) {
  const { c, route, homePath } = useSite();
  const other = alternateOf(route, route.locale === 'vi' ? 'en' : 'vi');
  const otherName = route.locale === 'vi' ? 'English' : 'Tiếng Việt';
  return (
    <footer className="footer container">
      <div className="footer__row">
        <div className="footer__brand">
          <a href={homePath} aria-label={c.nav.homeLabel}>
            <Lockup scale={0.8} />
          </a>
          <span className="footer__copy only-desktop-inline">{c.footer.copyright}</span>
          {environment !== 'prod' && <span className="footer__env">{environment}</span>}
        </div>
        <nav className="footer__links" aria-label={c.footer.linksLabel}>
          <a href={pathOf('privacy', route.locale)}>{c.footer.privacy}</a>
          <a href={pathOf('terms', route.locale)}>{c.footer.terms}</a>
          <a href={`mailto:${c.footer.email}`}>{c.footer.contact}</a>
          <a
            href={other.path}
            hrefLang={other.locale}
            lang={other.locale}
            data-locale={other.locale}
            className="footer__lang"
          >
            <Icon name="globe" size={14} />
            {otherName}
          </a>
        </nav>
        <span className="footer__copy only-mobile-inline">{c.footer.copyright}</span>
      </div>
    </footer>
  );
}

export function Toast({
  message,
  onClose,
  closeLabel,
}: {
  message: string | null;
  onClose: () => void;
  closeLabel: string;
}) {
  return (
    <div className="toast-region" role="status" aria-live="polite">
      {message && (
        <div className="toast" key={message}>
          <span>{message}</span>
          <button
            type="button"
            className="toast__close pressable"
            onClick={onClose}
            aria-label={closeLabel}
          >
            <Icon name="close" size={18} />
          </button>
        </div>
      )}
    </div>
  );
}
