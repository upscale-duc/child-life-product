import {
  builtinRole,
  staffCan,
  type Environment,
  type StaffAction,
  type StaffLevels,
} from '@child-life/contracts';
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
import { useEscape, useScrollLock } from './ui';
import { AnalyticsScreen } from './screens/Analytics';
import { AuditScreen } from './screens/Audit';
import { FamiliesScreen } from './screens/Families';
import { FeaturesScreen } from './screens/Features';
import { NavIcon } from './nav-icons';
import { AppUpdateScreen } from './screens/AppUpdate';
import { FirstAidScreen } from './screens/FirstAid';
import { JobsScreen } from './screens/Jobs';
import { OverviewScreen } from './screens/Overview';
import { QaScreen } from './screens/Qa';
import { ReferenceScreen } from './screens/Reference';
import { StaffScreen } from './screens/Staff';
import { StorageScreen } from './screens/Storage';
import { SupportScreen } from './screens/Support';
import { SystemScreen } from './screens/System';

type NavItem = {
  route: Route;
  badge?: keyof Badges;
  group?: 'ops' | 'content' | 'system' | 'develop';
  /** What a member needs to see the item (P-134); Kiểm thử only reaches the QA handbook. */
  can: StaffAction;
};
/** The v1.0 sidebar (`253:467`), NỘI DUNG › Sơ cứu (D-058), PHÁT TRIỂN › Sổ tay kiểm thử (P-132). */
const nav: NavItem[] = [
  { route: 'overview', can: 'overview.view' },
  { route: 'analytics', can: 'analytics.view' },
  { route: 'families', group: 'ops', can: 'families.view' },
  { route: 'support', badge: 'tickets', group: 'ops', can: 'support.view' },
  { route: 'storage', badge: 'storage', group: 'ops', can: 'storage.view' },
  { route: 'jobs', badge: 'jobs', group: 'ops', can: 'jobs.view' },
  { route: 'reference', group: 'ops', can: 'reference.view' },
  { route: 'firstAid', group: 'content', can: 'content.view' },
  { route: 'system', group: 'system', can: 'system.view' },
  { route: 'features', group: 'system', can: 'features.view' },
  { route: 'appUpdate', group: 'system', can: 'release.view' },
  { route: 'staff', group: 'system', can: 'staff.view' },
  { route: 'audit', group: 'system', can: 'audit.view' },
  { route: 'qa', group: 'develop', can: 'qa.view' },
];

const canOpen = (levels: StaffLevels, route: Route) => {
  const item = nav.find((n) => n.route === (route === 'systemAi' ? 'system' : route));
  return !!item && staffCan(levels, item.can);
};

/** The page a staff member lands on: the requested one, or the first their levels may open. */
export function allowedRoute(levels: StaffLevels, route: Route): Route {
  return canOpen(levels, route)
    ? route
    : (nav.find((n) => canOpen(levels, n.route))?.route ?? route);
}

const collapsedKey = 'portal.sidebar.collapsed';

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
  const staff = useStaff();
  const [route, setRoute] = useState<Route>(() =>
    allowedRoute(staff.levels, routeOf(window.location.pathname)),
  );
  const [badges, setBadges] = useState<Badges | null>(null);
  const seesCounts = staffCan(staff.levels, 'overview.view');

  const refreshBadges = useCallback(() => {
    if (!seesCounts) return;
    api
      .call<Badges>('staffBadges')
      .then(setBadges)
      .catch(() => setBadges(null));
  }, [api, seesCounts]);
  useEffect(() => {
    refreshBadges();
    const t = setInterval(refreshBadges, 60_000);
    return () => clearInterval(t);
  }, [refreshBadges]);

  useEffect(() => {
    const onPop = () => setRoute(allowedRoute(staff.levels, routeOf(window.location.pathname)));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, [staff.levels]);
  // A page the levels may not open (e.g. "/" for Kiểm thử) shows its fallback's address.
  useEffect(() => {
    if (routeOf(window.location.pathname) !== route) {
      window.history.replaceState({}, '', routePaths[route]);
    }
  }, [route]);
  const navigate = useCallback((r: Route) => {
    if (window.location.pathname !== routePaths[r]) window.history.pushState({}, '', routePaths[r]);
    setRoute(r);
    setDrawer(false);
    window.scrollTo(0, 0);
  }, []);
  // Below 860 px the sidebar is a drawer opened from the top bar (portal UI review).
  const [drawer, setDrawer] = useState(false);
  // Wider: the menu can shrink to icons; remembered on this browser (portal review 2026-10-12).
  const [collapsed, setCollapsed] = useState(() => {
    try {
      return window.localStorage.getItem(collapsedKey) === '1';
    } catch {
      return false;
    }
  });
  const collapse = useCallback((value: boolean) => {
    setCollapsed(value);
    try {
      window.localStorage.setItem(collapsedKey, value ? '1' : '0');
    } catch {
      // Private mode: it just resets next time.
    }
  }, []);
  useScrollLock(drawer);
  useEscape(() => setDrawer(false), drawer);
  const intl = useIntl();
  const active = route === 'systemAi' ? 'system' : route;

  return (
    <NavigateContext.Provider value={navigate}>
      <BadgesContext.Provider value={refreshBadges}>
        <div className={`shell ${collapsed ? 'shell--collapsed' : ''}`}>
          <header className="topbar">
            <button
              type="button"
              className="topbar__menu"
              aria-label={intl.formatMessage({ id: 'nav.open' })}
              aria-expanded={drawer}
              aria-controls="portal-menu"
              onClick={() => setDrawer(true)}
            >
              <svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true">
                <path
                  d="M4 7h16M4 12h16M4 17h16"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                />
              </svg>
            </button>
            <p className="topbar__title">
              <span className="brand">Child Life</span>
              <span className="topbar__page">
                <FormattedMessage id={`nav.${active}`} />
              </span>
            </p>
            <span className={`env env--${environment}`}>
              ● <FormattedMessage id={`env.${environment}`} />
            </span>
          </header>
          {drawer && (
            <div className="sidebar-scrim" onClick={() => setDrawer(false)} aria-hidden="true" />
          )}
          <Sidebar
            route={route}
            badges={badges}
            environment={environment}
            locale={locale}
            onLocale={onLocale}
            onSignOut={onSignOut}
            navigate={navigate}
            open={drawer}
            onClose={() => setDrawer(false)}
            collapsed={collapsed}
            onCollapse={collapse}
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
    case 'analytics':
      return <AnalyticsScreen />;
    case 'families':
      return <FamiliesScreen />;
    case 'reference':
      return <ReferenceScreen />;
    case 'firstAid':
      return <FirstAidScreen />;
    case 'staff':
      return <StaffScreen />;
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
    case 'appUpdate':
      return <AppUpdateScreen />;
    case 'audit':
      return <AuditScreen />;
    case 'qa':
      return <QaScreen />;
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
  open = false,
  onClose,
  collapsed = false,
  onCollapse,
}: {
  route: Route;
  badges: Badges | null;
  environment: Environment;
  locale: SupportedLocale;
  onLocale: (l: SupportedLocale) => void;
  onSignOut: () => void;
  navigate: (r: Route) => void;
  /** The drawer state below 860 px. */
  open?: boolean;
  onClose?: () => void;
  /** Wide screens: icons only (portal review 2026-10-12); the drawer is always full. */
  collapsed?: boolean;
  onCollapse?: (collapsed: boolean) => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const rail = collapsed && !open;
  const listRef = useRef<HTMLUListElement>(null);
  const [menu, setMenu] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!menu) return;
    const close = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenu(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [menu]);
  useEscape(() => setMenu(false), menu);
  const active = route === 'systemAi' ? 'system' : route;
  // The menu scrolls on short screens: keep the current page in view.
  useEffect(() => {
    listRef.current?.querySelector('.sidebar__item--on')?.scrollIntoView?.({ block: 'nearest' });
  }, [active, open]);
  // Built-in roles by their catalog name; roles made on the portal by the name `staffMe` gave.
  const names = new Map(staff.roles.map((r, i) => [builtinRole(r) ?? r, staff.roleNames?.[i]]));
  const roles = sortedRoles(staff.roles)
    .map((r) =>
      builtinRole(r) ? intl.formatMessage({ id: `role.${builtinRole(r)}` }) : (names.get(r) ?? r),
    )
    .join(' · ');
  return (
    <nav
      id="portal-menu"
      className={`sidebar ${open ? 'sidebar--open' : ''} ${rail ? 'sidebar--rail' : ''}`}
      aria-label={intl.formatMessage({ id: 'nav.label' })}
    >
      <div className="sidebar__head">
        <p className="brand brand--side">
          <span className="brand__full">
            Child Life <span className="brand__sub">Vận hành</span>
          </span>
          <span className="brand__short" aria-hidden="true">
            CL
          </span>
        </p>
        {onCollapse && (
          <button
            type="button"
            className="sidebar__toggle"
            aria-label={intl.formatMessage({ id: collapsed ? 'nav.expand' : 'nav.collapse' })}
            title={intl.formatMessage({ id: collapsed ? 'nav.expand' : 'nav.collapse' })}
            aria-expanded={!collapsed}
            onClick={() => onCollapse(!collapsed)}
          >
            <NavIcon name={collapsed ? 'expand' : 'collapse'} />
          </button>
        )}
        {onClose && (
          <button
            type="button"
            className="sidebar__close"
            aria-label={intl.formatMessage({ id: 'nav.close' })}
            onClick={onClose}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true">
              <path
                d="M6 6l12 12M18 6L6 18"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
              />
            </svg>
          </button>
        )}
      </div>
      <ul className="sidebar__nav" ref={listRef}>
        {nav
          .filter((item) => canOpen(staff.levels, item.route))
          .map((item, i, shown) => ({
            ...item,
            // A group's heading sits above its first item this member can see.
            section: item.group && item.group !== shown[i - 1]?.group ? item.group : undefined,
          }))
          .map((item) => (
            <li key={item.route}>
              {item.section && (
                <p className="sidebar__section">
                  <FormattedMessage id={`nav.section.${item.section}`} />
                </p>
              )}
              <a
                href={routePaths[item.route]}
                title={rail ? intl.formatMessage({ id: `nav.${item.route}` }) : undefined}
                className={`sidebar__item ${active === item.route ? 'sidebar__item--on' : ''}`}
                aria-current={active === item.route ? 'page' : undefined}
                onClick={(e) => {
                  if (e.metaKey || e.ctrlKey || e.shiftKey) return;
                  e.preventDefault();
                  navigate(item.route);
                }}
              >
                <NavIcon name={item.route as Exclude<Route, 'systemAi'>} />
                <span className="sidebar__label">
                  <FormattedMessage id={`nav.${item.route}`} />
                </span>
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
            title={rail ? staff.name : undefined}
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
