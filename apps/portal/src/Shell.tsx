import {
  builtinRole,
  staffCan,
  type Environment,
  type StaffAction,
  type StaffLevels,
} from '@child-life/contracts';
import type { SupportedLocale } from '@child-life/web-config';
import {
  BookOpen,
  ChartColumn,
  ChevronsUpDown,
  ClipboardCheck,
  DatabaseBackup,
  HardDrive,
  HeartPulse,
  Languages,
  LayoutDashboard,
  LifeBuoy,
  LogOut,
  Monitor,
  Moon,
  ScrollText,
  Search,
  Server,
  ShieldCheck,
  Smartphone,
  Sun,
  ToggleRight,
  Users,
  type LucideIcon,
} from 'lucide-react';
import { useCallback, useContext, useEffect, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from '@/components/ui/command';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Separator } from '@/components/ui/separator';
import {
  Sidebar as SidebarRoot,
  SidebarContent,
  SidebarContext,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuBadge,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarRail,
  SidebarTrigger,
  useSidebar,
} from '@/components/ui/sidebar';
import { TooltipProvider } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';
import { useTheme, type ThemeMode } from '@/theme';
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
import { AnalyticsScreen } from './screens/Analytics';
import { AppUpdateScreen } from './screens/AppUpdate';
import { AuditScreen } from './screens/Audit';
import { FamiliesScreen } from './screens/Families';
import { FeaturesScreen } from './screens/Features';
import { FirstAidScreen } from './screens/FirstAid';
import { JobsScreen } from './screens/Jobs';
import { OverviewScreen } from './screens/Overview';
import { QaScreen } from './screens/Qa';
import { ReferenceScreen } from './screens/Reference';
import { StaffScreen } from './screens/Staff';
import { StorageScreen } from './screens/Storage';
import { SupportScreen } from './screens/Support';
import { SystemScreen } from './screens/System';

type Group = 'main' | 'ops' | 'content' | 'system' | 'develop';
type NavRoute = Exclude<Route, 'systemAi'>;
type NavItem = {
  route: NavRoute;
  icon: LucideIcon;
  badge?: keyof Badges;
  group: Group;
  /** What a member needs to see the item (P-134); Kiểm thử only reaches the QA handbook. */
  can: StaffAction;
};
/** The v1.0 sidebar (`253:467`), NỘI DUNG › Sơ cứu (D-058), PHÁT TRIỂN › Sổ tay kiểm thử (P-132). */
const nav: NavItem[] = [
  { route: 'overview', icon: LayoutDashboard, group: 'main', can: 'overview.view' },
  { route: 'analytics', icon: ChartColumn, group: 'main', can: 'analytics.view' },
  { route: 'families', icon: Users, group: 'ops', can: 'families.view' },
  { route: 'support', icon: LifeBuoy, badge: 'tickets', group: 'ops', can: 'support.view' },
  { route: 'storage', icon: HardDrive, badge: 'storage', group: 'ops', can: 'storage.view' },
  { route: 'jobs', icon: DatabaseBackup, badge: 'jobs', group: 'ops', can: 'jobs.view' },
  { route: 'reference', icon: BookOpen, group: 'ops', can: 'reference.view' },
  { route: 'firstAid', icon: HeartPulse, group: 'content', can: 'content.view' },
  { route: 'system', icon: Server, group: 'system', can: 'system.view' },
  { route: 'features', icon: ToggleRight, group: 'system', can: 'features.view' },
  { route: 'appUpdate', icon: Smartphone, group: 'system', can: 'release.view' },
  { route: 'staff', icon: ShieldCheck, group: 'system', can: 'staff.view' },
  { route: 'audit', icon: ScrollText, group: 'system', can: 'audit.view' },
  { route: 'qa', icon: ClipboardCheck, group: 'develop', can: 'qa.view' },
];
const groups: Group[] = ['main', 'ops', 'content', 'system', 'develop'];

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

/** The items a member may open, by sidebar group (a group with nothing open is left out). */
function visibleGroups(levels: StaffLevels) {
  return groups
    .map((group) => ({
      group,
      items: nav.filter((n) => n.group === group && canOpen(levels, n.route)),
    }))
    .filter((g) => g.items.length > 0);
}

// Kept from the pre-shadcn sidebar so members keep their choice (portal review 2026-10-12).
const collapsedKey = 'portal.sidebar.collapsed';
const themeIcons: Record<ThemeMode, LucideIcon> = { light: Sun, dark: Moon, system: Monitor };

/** The signed-in portal on shadcn/ui (D-063): sidebar, header with ⌘K, and the screens. */
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
  const [search, setSearch] = useState(false);
  const intl = useIntl();
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
    window.scrollTo(0, 0);
  }, []);

  const [open, setOpen] = useState(() => {
    try {
      return window.localStorage.getItem(collapsedKey) !== '1';
    } catch {
      return true;
    }
  });
  const onOpenChange = useCallback((value: boolean) => {
    setOpen(value);
    try {
      window.localStorage.setItem(collapsedKey, value ? '0' : '1');
    } catch {
      // Private mode: it just resets next time.
    }
  }, []);

  // ⌘K / Ctrl+K: jump to a page or run an action.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'k' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setSearch((s) => !s);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const active: NavRoute = route === 'systemAi' ? 'system' : route;
  const group = nav.find((n) => n.route === active)?.group ?? 'main';

  return (
    <NavigateContext.Provider value={navigate}>
      <BadgesContext.Provider value={refreshBadges}>
        <TooltipProvider delayDuration={0}>
          <SidebarProvider open={open} onOpenChange={onOpenChange}>
            <AppSidebar
              route={route}
              badges={badges}
              environment={environment}
              locale={locale}
              onLocale={onLocale}
              onSignOut={onSignOut}
              navigate={navigate}
            />
            <SidebarInset className="min-w-0">
              <header className="sticky top-0 z-20 flex h-14 shrink-0 items-center gap-2 border-b bg-background/90 px-3 backdrop-blur supports-[backdrop-filter]:bg-background/70 md:px-4">
                <SidebarToggle />
                <Separator
                  orientation="vertical"
                  className="mr-1 data-[orientation=vertical]:h-4"
                />
                <nav
                  aria-label={intl.formatMessage({ id: 'nav.breadcrumb' })}
                  className="flex min-w-0 items-center gap-1.5 text-sm"
                >
                  {group !== 'main' && (
                    <span className="hidden truncate text-muted-foreground sm:inline">
                      <SectionName group={group} />
                      <span className="mx-1.5 text-muted-foreground/60">/</span>
                    </span>
                  )}
                  <span className="truncate font-medium text-foreground">
                    <FormattedMessage id={`nav.${active}`} />
                  </span>
                </nav>
                <div className="ml-auto flex items-center gap-2">
                  <SearchButton onClick={() => setSearch(true)} />
                  <ThemeMenu />
                  <EnvBadge environment={environment} className="hidden md:inline-flex" />
                </div>
              </header>
              {/* SidebarInset is the page's <main>. */}
              <div className="main flex-1">
                <Screen route={route} />
              </div>
            </SidebarInset>
            <CommandMenu
              open={search}
              onOpenChange={setSearch}
              navigate={navigate}
              locale={locale}
              onLocale={onLocale}
            />
          </SidebarProvider>
        </TooltipProvider>
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

function SectionName({ group }: { group: Group }) {
  return <FormattedMessage id={`nav.section.${group}`} />;
}

function SidebarToggle() {
  const intl = useIntl();
  const { open, isMobile } = useSidebar();
  const label = isMobile ? 'nav.open' : open ? 'nav.collapse' : 'nav.expand';
  return (
    <SidebarTrigger
      className="-ml-1"
      aria-label={intl.formatMessage({ id: label })}
      title={intl.formatMessage({ id: label })}
    />
  );
}

function EnvBadge({ environment, className }: { environment: Environment; className?: string }) {
  return (
    <span
      className={cn(
        'inline-flex shrink-0 items-center gap-1 rounded-full border px-2 py-0.5 text-xs font-medium',
        environment === 'prod'
          ? 'border-destructive/30 bg-destructive/10 text-destructive'
          : 'border-primary/25 bg-primary/10 text-primary',
        className,
      )}
    >
      ● <FormattedMessage id={`env.${environment}`} />
    </span>
  );
}

function SearchButton({ onClick }: { onClick: () => void }) {
  const intl = useIntl();
  return (
    <Button
      variant="outline"
      size="sm"
      onClick={onClick}
      aria-label={intl.formatMessage({ id: 'search.open' })}
      className="h-8 gap-2 rounded-md px-2 text-muted-foreground sm:w-56 sm:justify-start sm:px-3"
    >
      <Search className="size-4" />
      <span className="hidden flex-1 text-left sm:inline">
        <FormattedMessage id="search.open" />
      </span>
      <kbd className="pointer-events-none hidden h-5 items-center gap-0.5 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium sm:inline-flex">
        ⌘K
      </kbd>
    </Button>
  );
}

function ThemeMenu() {
  const intl = useIntl();
  const { mode, resolved, setMode } = useTheme();
  const Icon = resolved === 'dark' ? Moon : Sun;
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="size-8"
          aria-label={intl.formatMessage({ id: 'theme.label' })}
        >
          <Icon className="size-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <ThemeChoices mode={mode} setMode={setMode} />
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

function ThemeChoices({ mode, setMode }: { mode: ThemeMode; setMode: (m: ThemeMode) => void }) {
  return (
    <DropdownMenuRadioGroup value={mode} onValueChange={(v) => setMode(v as ThemeMode)}>
      {(['light', 'dark', 'system'] as const).map((m) => {
        const Icon = themeIcons[m];
        return (
          <DropdownMenuRadioItem key={m} value={m}>
            <Icon className="size-4 text-muted-foreground" />
            <FormattedMessage id={`theme.${m}`} />
          </DropdownMenuRadioItem>
        );
      })}
    </DropdownMenuRadioGroup>
  );
}

type SidebarProps = {
  route: Route;
  badges: Badges | null;
  environment: Environment;
  locale: SupportedLocale;
  onLocale: (l: SupportedLocale) => void;
  onSignOut: () => void;
  navigate: (r: Route) => void;
};

/**
 * The menu. Inside the Shell it uses the Shell's SidebarProvider; rendered on its own (tests,
 * previews) it brings one, `collapsed` giving the icon-only state.
 */
export function Sidebar({ collapsed = false, ...props }: SidebarProps & { collapsed?: boolean }) {
  const inShell = useContext(SidebarContext) !== null;
  if (inShell) return <AppSidebar {...props} />;
  return (
    <TooltipProvider delayDuration={0}>
      <SidebarProvider defaultOpen={!collapsed}>
        <AppSidebar {...props} />
        <SidebarToggle />
      </SidebarProvider>
    </TooltipProvider>
  );
}

function AppSidebar({
  route,
  badges,
  environment,
  locale,
  onLocale,
  onSignOut,
  navigate,
}: SidebarProps) {
  const intl = useIntl();
  const staff = useStaff();
  const { isMobile, setOpenMobile, open } = useSidebar();
  const active = route === 'systemAi' ? 'system' : route;
  return (
    <SidebarRoot
      collapsible="icon"
      variant="inset"
      aria-label={intl.formatMessage({ id: 'nav.label' })}
      closeLabel={intl.formatMessage({ id: 'nav.close' })}
    >
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <div className="flex items-center gap-2 rounded-md p-2 group-data-[collapsible=icon]:p-0">
              <span className="flex aspect-square size-8 shrink-0 items-center justify-center rounded-lg bg-sidebar-primary text-xs font-bold text-sidebar-primary-foreground">
                CL
              </span>
              <span className="grid min-w-0 flex-1 text-left text-sm leading-tight group-data-[collapsible=icon]:hidden">
                <span className="truncate font-semibold">Child Life</span>
                <span className="flex items-center gap-1.5 truncate text-xs text-muted-foreground">
                  Vận hành
                  <EnvBadge environment={environment} className="px-1.5 py-0 text-[10px]" />
                </span>
              </span>
            </div>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        {visibleGroups(staff.levels).map(({ group, items }) => (
          <SidebarGroup key={group}>
            {group !== 'main' && (
              <SidebarGroupLabel className="tracking-wide">
                <SectionName group={group} />
              </SidebarGroupLabel>
            )}
            <SidebarMenu>
              {items.map((item) => {
                const count = item.badge && badges ? badges[item.badge] : 0;
                const label = intl.formatMessage({ id: `nav.${item.route}` });
                return (
                  <SidebarMenuItem key={item.route}>
                    <SidebarMenuButton asChild isActive={active === item.route} tooltip={label}>
                      <a
                        href={routePaths[item.route]}
                        aria-current={active === item.route ? 'page' : undefined}
                        onClick={(e) => {
                          if (e.metaKey || e.ctrlKey || e.shiftKey) return;
                          e.preventDefault();
                          navigate(item.route);
                          if (isMobile) setOpenMobile(false);
                        }}
                      >
                        <item.icon />
                        <span>{label}</span>
                      </a>
                    </SidebarMenuButton>
                    {count > 0 && (
                      <SidebarMenuBadge className="rounded-full bg-destructive/10 text-destructive peer-data-[active=true]/menu-button:text-destructive">
                        {intl.formatNumber(count)}
                      </SidebarMenuBadge>
                    )}
                  </SidebarMenuItem>
                );
              })}
            </SidebarMenu>
          </SidebarGroup>
        ))}
      </SidebarContent>
      <SidebarFooter>
        <UserMenu locale={locale} onLocale={onLocale} onSignOut={onSignOut} />
      </SidebarFooter>
      <SidebarRail
        aria-label={intl.formatMessage({ id: open ? 'nav.collapse' : 'nav.expand' })}
        title={intl.formatMessage({ id: open ? 'nav.collapse' : 'nav.expand' })}
      />
    </SidebarRoot>
  );
}

function UserMenu({
  locale,
  onLocale,
  onSignOut,
}: {
  locale: SupportedLocale;
  onLocale: (l: SupportedLocale) => void;
  onSignOut: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const { isMobile } = useSidebar();
  const { mode, setMode } = useTheme();
  // Built-in roles by their catalog name; roles made on the portal by the name `staffMe` gave.
  const names = new Map(staff.roles.map((r, i) => [builtinRole(r) ?? r, staff.roleNames?.[i]]));
  const roles = sortedRoles(staff.roles)
    .map((r) =>
      builtinRole(r) ? intl.formatMessage({ id: `role.${builtinRole(r)}` }) : (names.get(r) ?? r),
    )
    .join(' · ');
  const initial = staff.name.trim()[0]?.toUpperCase() ?? '?';
  return (
    <SidebarMenu>
      <SidebarMenuItem>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <SidebarMenuButton
              size="lg"
              tooltip={staff.name}
              className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
            >
              <Avatar className="size-8 rounded-lg">
                <AvatarFallback className="rounded-lg bg-primary/15 font-semibold text-primary">
                  {initial}
                </AvatarFallback>
              </Avatar>
              <span className="grid flex-1 text-left text-sm leading-tight">
                <span className="truncate font-medium">{staff.name}</span>
                <span className="truncate text-xs text-muted-foreground">{roles}</span>
              </span>
              <ChevronsUpDown className="ml-auto size-4" />
            </SidebarMenuButton>
          </DropdownMenuTrigger>
          <DropdownMenuContent
            className="min-w-56 rounded-lg"
            side={isMobile ? 'bottom' : 'right'}
            align="end"
            sideOffset={4}
          >
            <DropdownMenuLabel className="font-normal">
              <span className="block truncate text-sm font-medium">{staff.name}</span>
              <span className="block truncate text-xs text-muted-foreground">{staff.email}</span>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuGroup>
              <DropdownMenuItem onSelect={() => onLocale(locale === 'vi' ? 'en' : 'vi')}>
                <Languages />
                {locale === 'vi' ? 'English' : 'Tiếng Việt'}
              </DropdownMenuItem>
            </DropdownMenuGroup>
            <DropdownMenuSeparator />
            <DropdownMenuLabel className="text-xs font-normal text-muted-foreground">
              <FormattedMessage id="theme.label" />
            </DropdownMenuLabel>
            <ThemeChoices mode={mode} setMode={setMode} />
            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={onSignOut}>
              <LogOut />
              <FormattedMessage id="menu.signOut" />
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </SidebarMenuItem>
    </SidebarMenu>
  );
}

function CommandMenu({
  open,
  onOpenChange,
  navigate,
  locale,
  onLocale,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  navigate: (r: Route) => void;
  locale: SupportedLocale;
  onLocale: (l: SupportedLocale) => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const { setMode } = useTheme();
  const run = (action: () => void) => {
    onOpenChange(false);
    action();
  };
  const t = (id: string) => intl.formatMessage({ id });
  return (
    <CommandDialog
      open={open}
      onOpenChange={onOpenChange}
      title={t('search.open')}
      description={t('search.placeholder')}
    >
      <CommandInput placeholder={t('search.placeholder')} />
      <CommandList>
        <CommandEmpty>
          <FormattedMessage id="search.empty" />
        </CommandEmpty>
        {visibleGroups(staff.levels).map(({ group, items }) => (
          <CommandGroup key={group} heading={t(`nav.section.${group}`)}>
            {items.map((item) => (
              <CommandItem
                key={item.route}
                value={`${t(`nav.${item.route}`)} ${item.route}`}
                onSelect={() => run(() => navigate(item.route))}
              >
                <item.icon />
                <FormattedMessage id={`nav.${item.route}`} />
              </CommandItem>
            ))}
          </CommandGroup>
        ))}
        <CommandGroup heading={t('search.actions')}>
          {(['light', 'dark', 'system'] as const).map((m) => {
            const Icon = themeIcons[m];
            return (
              <CommandItem
                key={m}
                value={`${t('theme.label')} ${t(`theme.${m}`)}`}
                onSelect={() => run(() => setMode(m))}
              >
                <Icon />
                <span>
                  {t('theme.label')}: {t(`theme.${m}`)}
                </span>
              </CommandItem>
            );
          })}
          <CommandItem
            value="language ngôn ngữ English Tiếng Việt"
            onSelect={() => run(() => onLocale(locale === 'vi' ? 'en' : 'vi'))}
          >
            <Languages />
            {locale === 'vi' ? 'English' : 'Tiếng Việt'}
          </CommandItem>
        </CommandGroup>
      </CommandList>
    </CommandDialog>
  );
}
