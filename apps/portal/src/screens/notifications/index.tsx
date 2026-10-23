import {
  staffCan,
  type NotificationOpsResponse,
  type NotificationStatsResponse,
  type NotificationTemplateRow,
} from '@child-life/contracts';
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';
import { useStaff } from '../../context';
import { Page } from '../../ui';
import { AnalyticsTab } from './Analytics';
import { CatalogView } from './Catalog';
import { DeliveryTab } from './Delivery';
import { JourneysTab } from './Journeys';
import { useOptionalLoad } from './kit';
import { OverviewTab } from './Overview';
import { SettingsTab } from './Settings';
import { TemplateEditor } from './TemplateEditor';
import { TemplatesTab } from './Templates';
import { TestSendTab } from './TestSend';
import { TimelineTab } from './Timeline';
import {
  locationOf,
  pathOf,
  rangeEnding,
  visibleTabs,
  type NotificationTab,
  type NtfLocation,
} from './shared';

const currentPath = () => (typeof window === 'undefined' ? '' : window.location.pathname);

/** The count a tab shows next to its name: problems on Delivery, drafts in review on Templates. */
export function tabBadges(
  stats: NotificationStatsResponse | null,
  templates: readonly NotificationTemplateRow[] | null,
): Partial<Record<NotificationTab, { n: number; tone: 'error' | 'warn' }>> {
  const out: Partial<Record<NotificationTab, { n: number; tone: 'error' | 'warn' }>> = {};
  if (stats && stats.problems.length) out.delivery = { n: stats.problems.length, tone: 'error' };
  const review = templates?.filter((t) => t.draftState === 'ready_for_review').length ?? 0;
  if (review) out.templates = { n: review, tone: 'warn' };
  return out;
}

/**
 * Thông báo & Gắn kết (P-174, D-092 UI review): one page with a tab per job — overview, templates
 * (EN08 editor), catalog and destinations, delivery, Smart Engagement journeys, a family's
 * timeline (restricted, audited), analytics and settings. Each tab has its own address
 * ("/notifications/delivery"); the tab bar stays visible while the page scrolls.
 */
export function NotificationsScreen({ initial }: { initial?: NtfLocation }) {
  const intl = useIntl();
  const staff = useStaff();
  const tabs = useMemo(() => visibleTabs(staff.levels), [staff.levels]);
  const canView = staffCan(staff.levels, 'notifications.view');
  const [loc, setLoc] = useState<NtfLocation>(() => {
    const l = initial ?? locationOf(currentPath(), tabs);
    return tabs.includes(l.tab) ? l : { tab: tabs[0] ?? 'overview' };
  });
  // Page-level reads shared by the overview, the badges, Templates and Settings.
  const week = useMemo(() => rangeEnding(7), []);
  const [stats, reloadStats] = useOptionalLoad<NotificationStatsResponse>(
    canView,
    'staffNotificationStats',
    week,
    `ntf-stats:${week.from}:${week.to}`,
  );
  const [templates, reloadTemplates] = useOptionalLoad<{ templates: NotificationTemplateRow[] }>(
    tabs.includes('templates'),
    'staffNotificationTemplates',
    {},
    'ntf-templates',
  );
  const [ops, reloadOps] = useOptionalLoad<NotificationOpsResponse>(
    canView,
    'staffNotificationOps',
    {},
    'ntf-ops',
  );
  const rows = templates?.status === 'ok' ? templates.data.templates : null;
  const badges = tabBadges(stats?.status === 'ok' ? stats.data : null, rows);

  // The browser's back / forward inside the page (the Shell keeps the same screen mounted).
  useEffect(() => {
    const onPop = () => setLoc(locationOf(window.location.pathname, tabs));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, [tabs]);
  useEffect(() => {
    const path = pathOf(loc);
    if (window.location.pathname !== path) window.history.replaceState({}, '', path);
  }, [loc]);
  const go = (next: NtfLocation, push = false) => {
    const path = pathOf(next);
    if (push && window.location.pathname !== path) window.history.pushState({}, '', path);
    setLoc(next);
    if (push) window.scrollTo(0, 0);
  };
  const setTab = (tab: NotificationTab) => {
    go({ tab });
    // A new tab starts at its top, not at the previous tab's scroll position.
    window.scrollTo({ top: 0 });
  };
  const openTimeline = tabs.includes('timeline')
    ? (code: string) => go({ tab: 'timeline', code }, true)
    : undefined;

  if (loc.tab === 'templates' && loc.template) {
    return (
      <Page title={<FormattedMessage id="ntf.title" />} info={<FormattedMessage id="ntf.info" />}>
        <TemplateEditor
          key={loc.template}
          templateId={loc.template}
          onBack={() => {
            reloadTemplates();
            go({ tab: 'templates' }, true);
          }}
        />
      </Page>
    );
  }

  const content: Record<NotificationTab, ReactNode> = {
    overview: (
      <OverviewTab
        stats={stats}
        reloadStats={reloadStats}
        ops={ops}
        reviewCount={rows ? (badges.templates?.n ?? 0) : null}
        canTimeline={!!openTimeline}
        onTab={setTab}
        onTimeline={(code) => openTimeline?.(code)}
      />
    ),
    templates: (
      <TemplatesTab
        load={templates}
        reload={reloadTemplates}
        onOpen={(id) => go({ tab: 'templates', template: id }, true)}
      />
    ),
    test: <TestSendTab templates={templates} />,
    catalog: <CatalogView />,
    delivery: <DeliveryTab onTimeline={openTimeline} />,
    journeys: <JourneysTab />,
    timeline: (
      <TimelineTab
        key={loc.code ?? ''}
        initialCode={loc.code}
        onCode={(code) => {
          const path = pathOf({ tab: 'timeline', code });
          if (window.location.pathname !== path) window.history.replaceState({}, '', path);
        }}
      />
    ),
    analytics: <AnalyticsTab />,
    settings: <SettingsTab load={ops} reload={reloadOps} />,
  };

  return (
    <Page title={<FormattedMessage id="ntf.title" />} info={<FormattedMessage id="ntf.info" />}>
      <Tabs
        value={loc.tab}
        onValueChange={(t) => setTab(t as NotificationTab)}
        // Grid tracks may not grow past the page: wide tables scroll inside DataTable instead.
        className="min-w-0 gap-5 [&_.stack]:grid-cols-[minmax(0,1fr)]"
      >
        <div className="sticky top-14 z-10 -mx-4 border-b bg-background/95 px-4 py-2 backdrop-blur supports-[backdrop-filter]:bg-background/80 md:-mx-8 md:px-8">
          <div className="no-scrollbar max-w-full overflow-x-auto">
            <TabsList aria-label={intl.formatMessage({ id: 'ntf.tabs' })}>
              {tabs.map((t) => {
                const badge = badges[t];
                return (
                  <TabsTrigger key={t} value={t} className="gap-1.5 px-3">
                    <FormattedMessage id={`ntf.tab.${t}`} />
                    {badge && (
                      <span
                        className={cn(
                          'grid h-5 min-w-5 place-items-center rounded-full px-1.5 text-[11px] font-semibold tabular-nums',
                          badge.tone === 'error'
                            ? 'bg-destructive/15 text-destructive'
                            : 'bg-warning/15 text-warning',
                        )}
                        aria-label={intl.formatMessage(
                          { id: `ntf.tab.badge.${t}` },
                          { n: badge.n },
                        )}
                      >
                        {intl.formatNumber(badge.n)}
                      </span>
                    )}
                  </TabsTrigger>
                );
              })}
            </TabsList>
          </div>
        </div>
        {tabs.map((t) => (
          <TabsContent key={t} value={t} className="min-w-0">
            {content[t]}
          </TabsContent>
        ))}
      </Tabs>
    </Page>
  );
}
