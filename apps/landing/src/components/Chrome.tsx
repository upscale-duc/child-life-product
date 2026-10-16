import { useSite } from '../context';
import { alternateOf, isStage, pathOf } from '../routes';
import { Icon, Lockup } from './primitives';

interface NavLink {
  label: string;
  href: string;
  /** Section id on this page, highlighted while in view. */
  spy?: string;
  current?: boolean;
  accent?: boolean;
}

/** Nav (28-landing-v5b-home §9, 15-landing-v3-stages §1). Sticky with a frosted background once
 *  the page scrolls (not in Figma); section links on desktop only, as designed; the language
 *  switch is an addition (D-012). Links point at this page's sections where it has them. */
export function Nav() {
  const { c, route, homePath } = useSite();
  const other = alternateOf(route, route.locale === 'vi' ? 'en' : 'vi');
  const l = c.nav.links;
  const firstYear = pathOf('stage1', route.locale);
  const onHome = route.page === 'home';
  const onStage1 = route.page === 'stage1';
  const local = (id: string) => ({ href: `#${id}`, spy: id });
  const links: NavLink[] = [
    { label: l.journey, ...(onHome ? local('hanh-trinh') : { href: `${homePath}#hanh-trinh` }) },
    onHome
      ? { label: l.firstYear, ...local('nam-dau-doi') }
      : { label: l.firstYear, href: firstYear, current: onStage1 },
    // Lumi has its own page (32-landing-v6-home §8); the link keeps a mint accent.
    {
      label: l.lumi,
      href: pathOf('lumi', route.locale),
      current: route.page === 'lumi',
      accent: true,
    },
    { label: l.stages, ...(onHome ? local('cac-chang') : { href: `${homePath}#cac-chang` }) },
    // Chặng 1 has its own "Tuổi thơ" section with the same id.
    {
      label: l.memories,
      ...(onHome || onStage1 ? local('ky-niem') : { href: `${homePath}#ky-niem` }),
    },
    // Chặng 1 and Lumi have their own FAQ (33-landing-lumi-page §13).
    {
      label: l.faq,
      ...(onHome || onStage1 || route.page === 'lumi'
        ? local('hoi-dap')
        : { href: `${homePath}#hoi-dap` }),
    },
  ];
  const hasCta = onHome || isStage(route.page) || route.page === 'lumi';
  return (
    <header className="nav" data-nav="">
      <div className="nav__inner container">
        <a className="nav__logo" href={homePath} aria-label={c.nav.homeLabel}>
          <Lockup />
        </a>
        <nav className="nav__links" aria-label={c.nav.sectionsLabel}>
          {links.map((link) => (
            <a
              key={link.label}
              href={link.href}
              data-spy={link.spy}
              aria-current={link.current ? 'page' : undefined}
              className={link.accent ? 'nav__accent' : undefined}
            >
              {link.label}
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
          <a className="nav__cta pressable" href={hasCta ? '#tai-app' : `${homePath}#tai-app`}>
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
