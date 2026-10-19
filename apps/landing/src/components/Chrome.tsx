import { useEffect, useRef, useState } from 'react';
import { useSite } from '../context';
import { alternateOf, isStage, pathOf } from '../routes';
import { Icon, Lockup } from './primitives';
import { launched } from './StoreBadges';

interface NavLink {
  label: string;
  href: string;
  /** Section id on this page, highlighted while in view. */
  spy?: string;
  current?: boolean;
}

/** Nav (V8, Figma 735:5378 / 736:65571; 34-landing-v8-home §1). Sticky with a frosted background
 *  once the page scrolls (not in Figma). Desktop: five links, the language switch (D-012, an
 *  addition) and "Bắt đầu". Mobile: "Bắt đầu" and a menu button; the menu's open state is not
 *  drawn, so it is a simple panel with the links and the language switch. Links point at this
 *  page's sections where it has them. */
export function Nav() {
  const { c, route, homePath } = useSite();
  const other = alternateOf(route, route.locale === 'vi' ? 'en' : 'vi');
  const l = c.nav.links;
  const page = route.page;
  const onHome = page === 'home';
  const onFirstYear = page === 'stage1';
  const local = (id: string) => ({ href: `#${id}`, spy: id });
  const home = (id: string) => ({ href: `${homePath}#${id}` });
  const links: NavLink[] = [
    {
      label: l.care,
      ...(onHome ? local('cham-soc') : onFirstYear ? local('ghi-va-nhac') : home('cham-soc')),
    },
    { label: l.memories, ...(onHome || onFirstYear ? local('ky-niem') : home('ky-niem')) },
    { label: l.lumi, href: pathOf('lumi', route.locale), current: page === 'lumi' },
    { label: l.firstYear, href: pathOf('stage1', route.locale), current: onFirstYear },
    // Home, Năm đầu đời and Lumi have their own FAQ; stage pages and legal pages use the home's.
    {
      label: l.faq,
      ...(onHome || onFirstYear || page === 'lumi' ? local('hoi-dap') : home('hoi-dap')),
    },
  ];
  const hasCta = onHome || isStage(page) || page === 'lumi';
  const start = hasCta ? '#tai-app' : `${homePath}#tai-app`;

  const [open, setOpen] = useState(false);
  const panel = useRef<HTMLDivElement>(null);
  const toggle = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return;
      setOpen(false);
      toggle.current?.focus();
    };
    const onClick = (event: MouseEvent) => {
      const target = event.target as Node;
      if (!panel.current?.contains(target) && !toggle.current?.contains(target)) setOpen(false);
    };
    document.addEventListener('keydown', onKey);
    document.addEventListener('click', onClick);
    panel.current?.querySelector('a')?.focus();
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('click', onClick);
    };
  }, [open]);

  const linkProps = (link: NavLink) => ({
    href: link.href,
    'aria-current': link.current ? ('page' as const) : undefined,
  });
  return (
    <header className={open ? 'nav is-open' : 'nav'} data-nav="">
      <div className="nav__inner container">
        <a className="nav__logo" href={homePath} aria-label={c.nav.homeLabel}>
          <Lockup />
        </a>
        <nav className="nav__links" aria-label={c.nav.sectionsLabel}>
          {links.map((link) => (
            <a key={link.label} {...linkProps(link)} data-spy={link.spy}>
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
          <a className="nav__cta pressable" href={start}>
            {c.nav.start}
          </a>
          <button
            ref={toggle}
            type="button"
            className="nav__menu pressable"
            aria-expanded={open}
            aria-controls="nav-menu"
            aria-label={open ? c.nav.menuClose : c.nav.menuOpen}
            onClick={() => setOpen((value) => !value)}
          >
            {open ? (
              <Icon name="close" size={18} />
            ) : (
              <span className="nav__bars" aria-hidden="true" />
            )}
          </button>
        </div>
      </div>
      <div id="nav-menu" ref={panel} className="nav__panel" hidden={!open}>
        <nav className="container" aria-label={c.nav.sectionsLabel}>
          {links.map((link) => (
            <a key={link.label} {...linkProps(link)} onClick={() => setOpen(false)}>
              {link.label}
              <Icon name="chevron-right" size={16} />
            </a>
          ))}
          <a
            className="nav__panel-lang"
            href={other.path}
            hrefLang={other.locale}
            lang={other.locale}
            data-locale={other.locale}
          >
            <Icon name="globe" size={16} />
            {c.nav.switchLabel}
          </a>
        </nav>
      </div>
    </header>
  );
}

/** "Thanh tải app cố định · hiện sau hero" (Figma 736:66587), mobile only: slides in once the
 *  page's first section has scrolled away, and hides again while the closing card (#tai-app) is on
 *  screen. Its button goes to #tai-app ("Bắt đầu" before launch, so it never promises a download
 *  the badges cannot give — V8/CTA tải app rule). */
export function StickyBar() {
  const { c } = useSite();
  const [shown, setShown] = useState(false);
  useEffect(() => {
    const hero = document.querySelector('main > :first-child');
    const end = document.getElementById('tai-app');
    if (!hero || !('IntersectionObserver' in window)) return;
    let pastHero = false;
    let atEnd = false;
    const update = () => setShown(pastHero && !atEnd);
    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.target === hero)
          pastHero = !entry.isIntersecting && entry.boundingClientRect.top < 0;
        else atEnd = entry.isIntersecting;
      }
      update();
    });
    observer.observe(hero);
    if (end) observer.observe(end);
    return () => observer.disconnect();
  }, []);
  return (
    <div className={shown ? 'sticky-bar is-shown' : 'sticky-bar'} aria-hidden={!shown}>
      <Lockup scale={0.6} />
      <a className="sticky-bar__cta pressable" href="#tai-app" tabIndex={shown ? undefined : -1}>
        {launched ? c.nav.download : c.nav.start}
      </a>
    </div>
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
