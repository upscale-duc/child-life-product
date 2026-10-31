import { FormattedMessage, useIntl } from 'react-intl';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { subPath, useNavigate } from '../../context';
import { Page } from '../../ui';
import { CatalogLoader } from './Catalog';
import { FeatureLoader } from './Feature';
import { OverviewLoader } from './Overview';
import { PlansLoader } from './Plans';
import { ChangeSetLoader, SourceLoader, SourcesLoader } from './Sources';

/**
 * Sản phẩm · Product Hub (D-155, `docs/product-hub/04-information-architecture-and-ux.md`).
 * Phase 1 tabs: Tổng quan, Tính năng (catalog + feature page), Gói & quyền (read only) and Nguồn
 * tri thức (library + review queue). Copilot, Journeys, Decisions and Insights come in later
 * phases and are not shown until they exist.
 */
export const productTabs = ['overview', 'features', 'plans', 'sources'] as const;
export type ProductTab = (typeof productTabs)[number];

export type ProductPlace =
  | { tab: 'overview' }
  | { tab: 'features'; feature: string | null }
  | { tab: 'plans' }
  | { tab: 'sources'; source: string | null; changeSet: string | null };

/** "/product/features/care.feeding" → the tab and the item it opens. */
export function productPlaceOf(pathname: string): ProductPlace {
  const [first, second, third] = subPath('product', pathname);
  if (first === 'features') return { tab: 'features', feature: second ?? null };
  if (first === 'plans') return { tab: 'plans' };
  if (first === 'sources') {
    if (second === 'review' && third) return { tab: 'sources', source: null, changeSet: third };
    return { tab: 'sources', source: second ?? null, changeSet: null };
  }
  return { tab: 'overview' };
}

export function ProductHubScreen({ initial }: { initial?: ProductPlace }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const place = initial ?? productPlaceOf(window.location.pathname);
  return (
    <Page title={<FormattedMessage id="ph.title" />} info={<FormattedMessage id="ph.info" />}>
      <Tabs
        value={place.tab}
        onValueChange={(t) => navigate('product', t === 'overview' ? undefined : t)}
        className="min-w-0 gap-4"
      >
        <TabsList aria-label={intl.formatMessage({ id: 'ph.tabs' })} className="max-w-full">
          {productTabs.map((t) => (
            <TabsTrigger key={t} value={t} className="px-3">
              <FormattedMessage id={`ph.tab.${t}`} />
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>
      {place.tab === 'overview' && <OverviewLoader />}
      {place.tab === 'features' &&
        (place.feature ? <FeatureLoader id={place.feature} /> : <CatalogLoader />)}
      {place.tab === 'plans' && <PlansLoader />}
      {place.tab === 'sources' &&
        (place.changeSet ? (
          <ChangeSetLoader id={place.changeSet} />
        ) : place.source ? (
          <SourceLoader id={place.source} />
        ) : (
          <SourcesLoader />
        ))}
    </Page>
  );
}
