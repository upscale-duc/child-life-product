import { useEffect, useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useStaff } from '../../context';
import { Page } from '../../ui';
import { AnalyticsTab } from './Analytics';
import { CatalogView } from './Catalog';
import { DeliveryTab } from './Delivery';
import { JourneysTab } from './Journeys';
import { OverviewTab } from './Overview';
import { SettingsTab } from './Settings';
import { TemplateEditor } from './TemplateEditor';
import { TemplatesTab } from './Templates';
import { TimelineTab } from './Timeline';
import { locationOf, pathOf, visibleTabs, type NotificationTab, type NtfLocation } from './shared';

const currentPath = () => (typeof window === 'undefined' ? '' : window.location.pathname);

/**
 * Thông báo & Gắn kết (P-174, docs/notifications/): one page with a tab per job — overview,
 * templates (EN08 editor), the catalog and destinations, delivery and failures, Smart Engagement
 * journeys, a family's timeline (restricted, audited), analytics and the ops switches. Each tab
 * has its own address ("/notifications/delivery").
 */
export function NotificationsScreen({ initial }: { initial?: NtfLocation }) {
  const intl = useIntl();
  const staff = useStaff();
  const tabs = useMemo(() => visibleTabs(staff.levels), [staff.levels]);
  const [loc, setLoc] = useState<NtfLocation>(() => {
    const l = initial ?? locationOf(currentPath(), tabs);
    return tabs.includes(l.tab) ? l : { tab: tabs[0] ?? 'overview' };
  });
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
  const setTab = (tab: NotificationTab) => go({ tab });

  if (loc.tab === 'templates' && loc.template) {
    return (
      <Page title={<FormattedMessage id="ntf.title" />} info={<FormattedMessage id="ntf.info" />}>
        <TemplateEditor
          key={loc.template}
          templateId={loc.template}
          onBack={() => go({ tab: 'templates' }, true)}
        />
      </Page>
    );
  }

  return (
    <Page title={<FormattedMessage id="ntf.title" />} info={<FormattedMessage id="ntf.info" />}>
      <Tabs
        value={loc.tab}
        onValueChange={(t) => setTab(t as NotificationTab)}
        className="min-w-0 gap-4"
      >
        <div className="max-w-full overflow-x-auto">
          <TabsList aria-label={intl.formatMessage({ id: 'ntf.tabs' })}>
            {tabs.map((t) => (
              <TabsTrigger key={t} value={t} className="px-3">
                <FormattedMessage id={`ntf.tab.${t}`} />
              </TabsTrigger>
            ))}
          </TabsList>
        </div>
        {tabs.includes('overview') && (
          <TabsContent value="overview" className="min-w-0">
            <OverviewTab onTab={setTab} />
          </TabsContent>
        )}
        <TabsContent value="templates" className="min-w-0">
          <TemplatesTab onOpen={(id) => go({ tab: 'templates', template: id }, true)} />
        </TabsContent>
        <TabsContent value="catalog" className="min-w-0">
          <CatalogView />
        </TabsContent>
        <TabsContent value="delivery" className="min-w-0">
          <DeliveryTab
            onTimeline={
              tabs.includes('timeline') ? (code) => go({ tab: 'timeline', code }, true) : undefined
            }
          />
        </TabsContent>
        <TabsContent value="journeys" className="min-w-0">
          <JourneysTab />
        </TabsContent>
        {tabs.includes('timeline') && (
          <TabsContent value="timeline" className="min-w-0">
            <TimelineTab
              key={loc.code ?? ''}
              initialCode={loc.code}
              onCode={(code) => {
                const path = pathOf({ tab: 'timeline', code });
                if (window.location.pathname !== path) window.history.replaceState({}, '', path);
              }}
            />
          </TabsContent>
        )}
        <TabsContent value="analytics" className="min-w-0">
          <AnalyticsTab />
        </TabsContent>
        <TabsContent value="settings" className="min-w-0">
          <SettingsTab />
        </TabsContent>
      </Tabs>
    </Page>
  );
}
