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
  Boxes,
  BadgeCheck,
  BellRing,
  CalendarHeart,
  CalendarRange,
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
  Milk,
  Monitor,
  Moon,
  Newspaper,
  ScrollText,
  Search,
  Server,
  ShieldCheck,
  Smartphone,
  Soup,
  Sparkles,
  Star,
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
import { Toaster } from '@/components/ui/sonner';
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
  canonicalPath,
  routePaths,
  routeOf,
  useStaff,
  type Route,
} from './context';
import { sortedRoles } from './session';
import { pageInfoSlot } from './ui';
import { AnalyticsScreen } from './screens/Analytics';
import { AppUpdateScreen } from './screens/AppUpdate';
import { ArticlesScreen } from './screens/Articles';
import { AuditScreen } from './screens/Audit';
import { ContentReviewScreen } from './screens/ContentReview';
import { FamiliesScreen } from './screens/Families';
import { FeatureHubScreen } from './screens/FeatureHub';
import { FirstAidScreen } from './screens/FirstAid';
import { KeepsakesScreen } from './screens/Keepsakes';
import { PrintStudioScreen } from './screens/PrintStudio';
import { MilestonesScreen } from './screens/Milestones';
import { NutritionScreen } from './screens/Nutrition';
import { JobsScreen } from './screens/Jobs';
import { NotificationsScreen } from './screens/notifications';
import { OverviewScreen } from './screens/Overview';
import { ProductHubScreen } from './screens/product';
import { QaScreen } from './screens/Qa';
import { ReferenceScreen } from './screens/Reference';
import { RhythmScreen } from './screens/Rhythm';
import { SolidsScreen } from './screens/Solids';
import { StaffScreen } from './screens/Staff';
import { StagesScreen } from './screens/Stages';
import { StorageScreen } from './screens/Storage';
import { SupportScreen } from './screens/Support';
import { SystemScreen } from './screens/System';

type Group = 'main' | 'product' | 'ops' | 'content' | 'system' | 'develop';
type NavItem = {
  route: Route;
  icon: LucideIcon;
  badge?: keyof Badges;
  group: Group;
  /** What a member needs to see the item (P-134); Kiểm thử only reaches the QA handbook. */
  can: StaffAction;
  /** Another action that also opens it (Thông báo: content experts edit templates only). */
  orCan?: StaffAction;
};
/** The v1.0 sidebar (`253:467`), NỘI DUNG › Sơ cứu (D-058), Nhịp lớn lên (PN01–PN04) and Mẫu kỷ niệm (D-068, not drawn: G-107), PHÁT TRIỂN › Sổ tay kiểm thử (P-132). */
const nav: NavItem[] = [
  { route: 'overview', icon: LayoutDashboard, group: 'main', can: 'overview.view' },
  { route: 'analytics', icon: ChartColumn, group: 'main', can: 'analytics.view' },
  // Sản phẩm (D-155): product knowledge, read by product, engineering and analysts.
  { route: 'product', icon: Boxes, group: 'product', can: 'product.view' },
  { route: 'families', icon: Users, group: 'ops', can: 'families.view' },
  { route: 'support', icon: LifeBuoy, badge: 'tickets', group: 'ops', can: 'support.view' },
  { route: 'storage', icon: HardDrive, badge: 'storage', group: 'ops', can: 'storage.view' },
  { route: 'jobs', icon: DatabaseBackup, badge: 'jobs', group: 'ops', can: 'jobs.view' },
  // Thông báo & Gắn kết (P-174); content experts reach its Templates with notifications.edit.
  {
    route: 'notifications',
    icon: BellRing,
    group: 'ops',
    can: 'notifications.view',
    orCan: 'notifications.edit',
  },
  { route: 'firstAid', icon: HeartPulse, group: 'content', can: 'content.view' },
  { route: 'rhythm', icon: CalendarHeart, group: 'content', can: 'content.view' },
  { route: 'keepsakes', icon: Sparkles, group: 'content', can: 'content.view' },
  { route: 'printStudio', icon: BookOpen, group: 'ops', can: 'support.view' },
  // Editorial content (D-076 #5–#7): Bài viết, Nội dung theo giai đoạn, Mốc phát triển, Duyệt.
  { route: 'articles', icon: Newspaper, group: 'content', can: 'content.view' },
  { route: 'stages', icon: CalendarRange, group: 'content', can: 'content.view' },
  { route: 'milestones', icon: Star, group: 'content', can: 'content.view' },
  // Dinh dưỡng theo giai đoạn (D-083, Figma D01–D04): stages, micronutrients, suggestion rules.
  { route: 'nutrition', icon: Milk, group: 'content', can: 'content.view' },
  // Ăn dặm (D-085, plan §6): food catalogue, recipes, solids guides.
  { route: 'solids', icon: Soup, group: 'content', can: 'content.view' },
  { route: 'contentReview', icon: BadgeCheck, group: 'content', can: 'content.view' },
  // Bảng tham chiếu (P-138; owner 2026-10-21): WHO growth tables, bottle amounts, vaccine schedule.
  { route: 'reference', icon: BookOpen, group: 'content', can: 'reference.view' },
  // Hệ thống & AI (owner 2026-10-21): storage, AI drafts and the assistant's usage and tasks.
  { route: 'system', icon: Server, group: 'system', can: 'system.view' },
  // Tính năng & Premium (D-089): features, families, the plan, system switches, history.
  { route: 'features', icon: ToggleRight, group: 'system', can: 'features.view' },
  { route: 'appUpdate', icon: Smartphone, group: 'system', can: 'release.view' },
  { route: 'staff', icon: ShieldCheck, group: 'system', can: 'staff.view' },
  { route: 'audit', icon: ScrollText, group: 'system', can: 'audit.view' },
  { route: 'qa', icon: ClipboardCheck, group: 'develop', can: 'qa.view' },
];
const groups: Group[] = ['main', 'product', 'ops', 'content', 'system', 'develop'];

const canOpen = (levels: StaffLevels, route: Route) => {
  const item = nav.find((n) => n.route === route);
  return !!item && (staffCan(levels, item.can) || (!!item.orCan && staffCan(levels, item.orCan)));
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

  // An old address of a merged page (/premium, /assistant) shows its tab's address.
  useEffect(() => {
    const path = canonicalPath(window.location.pathname);
    if (path !== window.location.pathname) window.history.replaceState({}, '', path);
  }, []);
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
  // A sidebar link opens the page as new (its first tab), even from one of its tabs.
  const [visit, setVisit] = useState(0);
  const navigate = useCallback((r: Route, sub?: string) => {
    const path = sub ? `${routePaths[r]}/${sub}` : routePaths[r];
    if (window.location.pathname !== path) {
      window.history.pushState({}, '', path);
      setVisit((v) => v + 1);
    }
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

  const active = route;
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
                {/* The page's "i" (Page `info`) sits next to its name, not on the page. */}
                <span id={pageInfoSlot} className="-ml-1 flex shrink-0 items-center" />
                <div className="ml-auto flex items-center gap-2">
                  <SearchButton onClick={() => setSearch(true)} />
                  <ThemeMenu />
                  <EnvBadge environment={environment} className="hidden md:inline-flex" />
                </div>
              </header>
              {/* SidebarInset is the page's <main>. */}
              <div className="main flex-1">
                <Screen key={`${route}:${visit}`} route={route} />
              </div>
            </SidebarInset>
            <CommandMenu
              open={search}
              onOpenChange={setSearch}
              navigate={navigate}
              locale={locale}
              onLocale={onLocale}
            />
            {/* "Đã lưu", "Đã gửi duyệt": short confirmations after an action (content screens). */}
            <Toaster position="bottom-right" closeButton />
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
    case 'rhythm':
      return <RhythmScreen />;
    case 'keepsakes':
      return <KeepsakesScreen />;
    case 'printStudio':
      return <PrintStudioScreen />;
    case 'articles':
      return <ArticlesScreen />;
    case 'stages':
      return <StagesScreen />;
    case 'milestones':
      return <MilestonesScreen />;
    case 'nutrition':
      return <NutritionScreen />;
    case 'solids':
      return <SolidsScreen />;
    case 'contentReview':
      return <ContentReviewScreen />;
    case 'staff':
      return <StaffScreen />;
    case 'support':
      return <SupportScreen />;
    case 'storage':
      return <StorageScreen />;
    case 'jobs':
      return <JobsScreen />;
    case 'system':
      return <SystemScreen />;
    case 'features':
      return <FeatureHubScreen />;
    case 'product':
      return <ProductHubScreen />;
    case 'notifications':
      return <NotificationsScreen />;
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
  const active = route;
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
                keywords={[
                  t(`nav.help.${item.route}`),
                  `${t(`nav.${item.route}`)} ${t(`nav.help.${item.route}`)}`
                    .normalize('NFD')
                    .replace(/[\u0300-\u036f]/g, '')
                    .replaceAll('đ', 'd')
                    .replaceAll('Đ', 'D'),
                ]}
                onSelect={() => run(() => navigate(item.route))}
              >
                <item.icon />
                <span className="grid min-w-0 gap-0.5">
                  <span>
                    <FormattedMessage id={`nav.${item.route}`} />
                  </span>
                  <span className="text-xs leading-5 text-muted-foreground">
                    <FormattedMessage id={`nav.help.${item.route}`} />
                  </span>
                </span>
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
