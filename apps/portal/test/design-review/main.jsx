// Isolated visual harness: real Shell and screens, no Firebase or production API.
import { createRoot } from 'react-dom/client';
import { useState } from 'react';
import { IntlProvider } from 'react-intl';
import {
  levelsForRoles,
  referenceV1,
  initialPrintCatalog,
  keepsakeSeedV1,
} from '@child-life/contracts';
import { ApiContext, ApiError } from '/src/api';
import { StaffContext } from '/src/context';
import { Shell } from '/src/Shell';
import { SignInScreen } from '/src/screens/SignIn';
import { ThemeProvider } from '/src/theme';
import { messages } from '/src/messages';
import * as system from './system.fixture';
import * as hub from './hub.fixture';
import * as content from './content.fixture';
import * as v1 from './v1.fixture';
import * as firstAid from './first-aid.fixture';
import * as rhythm from './rhythm.fixture';
import * as notifications from './notifications.fixture';
import * as appUpdate from './app-update.fixture';
import * as assistant from './assistant.fixture';
import * as product from './product-analytics.fixture';
import * as qa from './qa.fixture';
import * as nutrition from './nutrition.fixture';
import * as solids from './solids.fixture';
import '/src/index.css';
const params = new URLSearchParams(location.search);
const wanted = params.get('path') || '/';
const query = location.search;
history.replaceState({}, '', wanted + query);
const staff = {
  uid: 's1',
  email: 'review@example.test',
  name: 'Linh Trần',
  roles: [params.get('role') || 'owner'],
  levels: levelsForRoles([params.get('role') || 'owner']),
};
const answers = {
  staffBadges: { tickets: 4, storage: 2, jobs: 1 },
  staffOverview: {
    kpis: {
      activeFamilies: 128,
      activeFamiliesPrev: 110,
      newAccounts: 24,
      newAccountsPrev: 20,
      setupRate: 0.78,
      multiCarerRate: 0.46,
    },
    daily: Array.from({ length: 14 }, (_, i) => ({
      date: `2026-10-${String(i + 1).padStart(2, '0')}`,
      families: 60 + i * 4,
    })),
    funnel: [
      { step: 'account', count: 124 },
      { step: 'baby', count: 96 },
      { step: 'firstLog', count: 82 },
    ],
    weekly: [],
    alerts: [{ severity: 'warn', module: 'storage', kind: 'storagePending', count: 2 }],
  },
  staffFeatureHub: hub.hub,
  staffFlags: hub.flagsView,
  staffPremium: hub.premiumView,
  staffSystem: system.health,
  staffAi: system.ai,
  staffAssistantUsage: assistant.usage,
  staffTeam: v1.team,
  staffFamilies: v1.list,
  staffAnalytics: wanted.includes('features') ? v1.feats : v1.growth,
  staffProductAnalytics: product.result,
  staffFirstAid: firstAid.view,
  staffRhythm: rhythm.view,
  staffRhythmRules: rhythm.rulesView,
  staffAppUpdate: appUpdate.view,
  staffNotificationStats: notifications.stats(),
  staffNotificationOps: notifications.opsResponse(),
  staffNotificationTemplates: { templates: [notifications.tplDetail()] },
  staffNotificationTimeline: notifications.timeline,
  staffNotificationTemplate: notifications.tplDetail(),
  staffNotificationDeliveries: { rows: notifications.stats().problems, next: null },
  staffTickets: { counts: { open: 0, new: 0, claimed: 0, waiting: 0 }, rows: [] },
  staffStorageRequests: {
    kpis: {
      pending: 0,
      oldestAt: null,
      over80: 0,
      grantedThisMonth: 0,
      grantedGbThisMonth: 0,
      medianHours: null,
    },
    rows: [],
  },
  staffJobs: {
    kpis: {
      running: 0,
      runningExports: 0,
      failed24h: 0,
      medianExportMinutes: null,
      deletionsDone: 0,
      deletionsTotal: 0,
    },
    rows: [],
  },
  staffAudit: { rows: [] },
  staffKeepsakes: {
    current: { version: 'review_v1', publishedAt: '2026-10-26T03:00:00Z', catalog: keepsakeSeedV1 },
    draft: null,
    history: [],
    assets: [],
  },
  staffPrintStudio: {
    catalog: initialPrintCatalog,
    orders: [
      {
        id: 'print_review_01',
        babyId: 'review',
        status: 'pendingConfirmation',
        total: 129000,
        createdAt: '2026-10-26T03:00:00Z',
        renderStatus: 'ready',
      },
    ],
    reviews: [],
    demand: [],
  },
  staffQa: { cases: qa.cases, results: qa.results, runId: qa.run.id, runs: [qa.run] },
  staffContentImages: { images: [] },
};
const api = {
  async call(name, data) {
    if (params.get('state') === 'loading') return new Promise(() => {});
    if (params.get('state') === 'error') throw new ApiError('unavailable', null);
    if (name === 'staffProductAnalytics')
      return { ...product.result, section: data.section, range: { from: data.from, to: data.to } };
    if (name === 'staffReference')
      return {
        dataset: data.dataset,
        current: {
          versionId: 'builtin',
          label: 'v2026.10',
          rows: referenceV1(data.dataset),
          publishedAt: null,
          approver: null,
        },
        draft: null,
        history: [],
      };
    if (name === 'staffContentList') {
      const v = data?.view;
      if (v === 'article') return content.articleView;
      if (v === 'stage') return content.stageView;
      if (['nutritionStage', 'nutrient', 'nutritionRule'].includes(v))
        return nutrition.view(
          v,
          v === 'nutrient'
            ? nutrition.nutrientRows
            : v.toLowerCase().includes('rule')
              ? nutrition.ruleRows
              : nutrition.stageRows,
        );
      if (['food', 'recipe'].includes(v))
        return solids.view(v, v === 'recipe' ? solids.recipeRows : solids.foodRows);
      if (v === 'queue')
        return {
          view: v,
          today: '2026-10-26',
          rows: [],
          counts: {},
          totals: content.articleView.counts,
          available: [],
          requireReview: false,
        };
      return { ...content.articleView, view: v, rows: [], coverage: [], queue: [] };
    }
    if (name === 'staffContentItem') return content.itemOf(content.fullArticle());
    if (name in answers) return answers[name];
    console.info('Fixture unavailable:', name);
    throw new ApiError('unavailable', null);
  },
};
window.__review = { messages, answers };
function Review() {
  const [locale, setLocale] = useState(params.get('lang') || 'vi');
  document.documentElement.lang = locale;
  return (
    <IntlProvider locale={locale} messages={messages[locale]}>
      <ApiContext.Provider value={api}>
        <StaffContext.Provider value={staff}>
          <ThemeProvider>
            {wanted === '/sign-in' ? (
              <SignInScreen
                actions={{
                  withPassword: async () => {},
                  sendLink: async () => {},
                  finishLink: async () => {},
                  resetPassword: async () => {},
                }}
                notice={null}
                pendingLink={false}
              />
            ) : (
              <Shell environment="dev" locale={locale} onLocale={setLocale} onSignOut={() => {}} />
            )}
          </ThemeProvider>
        </StaffContext.Provider>
      </ApiContext.Provider>
    </IntlProvider>
  );
}
createRoot(document.getElementById('root')).render(<Review />);
