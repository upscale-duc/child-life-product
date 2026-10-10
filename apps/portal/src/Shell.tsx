import type { Environment } from '@child-life/contracts';
import type { SupportedLocale } from '@child-life/web-config';
import { useCallback, useEffect, useRef, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useApi, type Badges } from './api';
import {
  BadgesContext,
  NavigateContext,
  routePaths,
  routeOf,
  useStaff,
  type Route,
} from './context';
import { sortedRoles } from './session';
import { AuditScreen } from './screens/Audit';
import { FeaturesScreen } from './screens/Features';
import { JobsScreen } from './screens/Jobs';
import { OverviewScreen } from './screens/Overview';
import { StorageScreen } from './screens/Storage';
import { SupportScreen } from './screens/Support';
import { SystemScreen } from './screens/System';

const nav: Array<{ route: Route; badge?: keyof Badges; section?: true }> = [
  { route: 'overview' },
  { route: 'support', badge: 'tickets' },
  { route: 'storage', badge: 'storage' },
  { route: 'jobs', badge: 'jobs' },
  { route: 'system', section: true },
  { route: 'features' },
  { route: 'audit' },
];

/** The signed-in portal: the Admin/Sidebar (`253:467`) and the A02–A12 screens. */
export function Shell({
  environment,
  locale,
  onLocale,
  onSignOut,
}: {
  environment: Environment;
  locale: SupportedLocale;
  onLocale: (l: SupportedLocale) => void;
  onSignOut: () => void;
}) {
  const api = useApi();
  const [route, setRoute] = useState<Route>(() => routeOf(window.location.pathname));
  const [badges, setBadges] = useState<Badges | null>(null);

  const refreshBadges = useCallback(() => {
    api
      .call<Badges>('staffBadges')
      .then(setBadges)
      .catch(() => setBadges(null));
  }, [api]);
  useEffect(() => {
    refreshBadges();
    const t = setInterval(refreshBadges, 60_000);
    return () => clearInterval(t);
  }, [refreshBadges]);

  useEffect(() => {
    const onPop = () => setRoute(routeOf(window.location.pathname));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const navigate = useCallback((r: Route) => {
    if (window.location.pathname !== routePaths[r]) window.history.pushState({}, '', routePaths[r]);
    setRoute(r);
    window.scrollTo(0, 0);
  }, []);

  return (
    <NavigateContext.Provider value={navigate}>
      <BadgesContext.Provider value={refreshBadges}>
        <div className="shell">
          <Sidebar
            route={route}
            badges={badges}
            environment={environment}
            locale={locale}
            onLocale={onLocale}
            onSignOut={onSignOut}
            navigate={navigate}
          />
          <main className="main">
            <Screen route={route} />
          </main>
        </div>
      </BadgesContext.Provider>
    </NavigateContext.Provider>
  );
}

function Screen({ route }: { route: Route }) {
  switch (route) {
    case 'overview':
      return <OverviewScreen />;
    case 'support':
      return <SupportScreen />;
    case 'storage':
      return <StorageScreen />;
    case 'jobs':
      return <JobsScreen />;
    case 'system':
      return <SystemScreen tab="storage" />;
    case 'systemAi':
      return <SystemScreen tab="ai" />;
    case 'features':
      return <FeaturesScreen />;
    case 'audit':
      return <AuditScreen />;
  }
}

export function Sidebar({
  route,
  badges,
  environment,
  locale,
  onLocale,
  onSignOut,
  navigate,
}: {
  route: Route;
  badges: Badges | null;
  environment: Environment;
  locale: SupportedLocale;
  onLocale: (l: SupportedLocale) => void;
  onSignOut: () => void;
  navigate: (r: Route) => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const [menu, setMenu] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!menu) return;
    const close = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenu(false);
    };
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && setMenu(false);
    document.addEventListener('mousedown', close);
    document.addEventListener('keydown', esc);
    return () => {
      document.removeEventListener('mousedown', close);
      document.removeEventListener('keydown', esc);
    };
  }, [menu]);
  const active = route === 'systemAi' ? 'system' : route;
  const roles = sortedRoles(staff.roles)
    .map((r) => intl.formatMessage({ id: `role.${r}` }))
    .join(' · ');
  return (
    <nav className="sidebar" aria-label={intl.formatMessage({ id: 'nav.label' })}>
      <p className="brand brand--side">
        Child Life <span className="brand__sub">Vận hành</span>
      </p>
      <ul className="sidebar__nav">
        {nav.map((item) => (
          <li key={item.route}>
            {item.section && (
              <p className="sidebar__section">
                <FormattedMessage id="nav.section.system" />
              </p>
            )}
            <a
              href={routePaths[item.route]}
              className={`sidebar__item ${active === item.route ? 'sidebar__item--on' : ''}`}
              aria-current={active === item.route ? 'page' : undefined}
              onClick={(e) => {
                if (e.metaKey || e.ctrlKey || e.shiftKey) return;
                e.preventDefault();
                navigate(item.route);
              }}
            >
              <FormattedMessage id={`nav.${item.route}`} />
              {item.badge && badges && badges[item.badge] > 0 && (
                <span className="sidebar__badge">{intl.formatNumber(badges[item.badge])}</span>
              )}
            </a>
          </li>
        ))}
      </ul>
      <div className="sidebar__foot">
        <span className={`env env--${environment}`}>
          ● <FormattedMessage id={`env.${environment}`} />
        </span>
        <div className="usercard" ref={menuRef}>
          <button
            type="button"
            className="usercard__button"
            aria-haspopup="menu"
            aria-expanded={menu}
            onClick={() => setMenu((m) => !m)}
          >
            <span className="avatar" aria-hidden="true">
              {staff.name.trim()[0]?.toUpperCase() ?? '?'}
            </span>
            <span className="usercard__text">
              <span className="usercard__name">{staff.name}</span>
              <span className="usercard__role">{roles}</span>
            </span>
          </button>
          {menu && (
            <div className="menu" role="menu">
              <p className="menu__email">{staff.email}</p>
              <button
                type="button"
                role="menuitem"
                className="menu__item"
                onClick={() => {
                  onLocale(locale === 'vi' ? 'en' : 'vi');
                  setMenu(false);
                }}
              >
                {locale === 'vi' ? 'English' : 'Tiếng Việt'}
              </button>
              <button type="button" role="menuitem" className="menu__item" onClick={onSignOut}>
                <FormattedMessage id="menu.signOut" />
              </button>
            </div>
          )}
        </div>
      </div>
    </nav>
  );
}
