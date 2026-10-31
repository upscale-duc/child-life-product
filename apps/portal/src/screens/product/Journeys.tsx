import { ArrowLeft, Route } from 'lucide-react';
import type { ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { EmptyState, Section } from '../../content-kit';
import { useNavigate } from '../../context';
import { Button, Loaded, TableScroll } from '../../ui';
import { Meta, PathText, VerificationText, linkClass, shortRev, useLocalName } from './kit';
import type { JourneyView, JourneysView } from './types';

/**
 * Sản phẩm › Hành trình (D-155, Phase 3): end-to-end user journeys from the reviewed registry
 * (`docs/product-hub/registry/journeys.json`), each step linked to the feature that carries it.
 */
export function JourneysLoader() {
  const [load, reload] = useLoad<JourneysView>('productHubJourneys', {}, 'journeys');
  return <Loaded load={load} reload={reload}>{(d) => <JourneysView data={d} />}</Loaded>;
}

export function JourneysView({ data }: { data: JourneysView }) {
  const navigate = useNavigate();
  const name = useLocalName();
  if (data.journeys.length === 0) {
    return (
      <Section title={<FormattedMessage id="ph.journeys.title" />}>
        <EmptyState icon={Route} title={<FormattedMessage id="ph.journeys.emptyTitle" />}>
          <FormattedMessage id="ph.journeys.emptyBody" />
        </EmptyState>
      </Section>
    );
  }
  return (
    <Section title={<FormattedMessage id="ph.journeys.title" />} hint={<FormattedMessage id="ph.journeys.hint" />} flush>
      <TableScroll min={720}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="ph.col.journey" />
              </th>
              <th>
                <FormattedMessage id="ph.col.steps" />
              </th>
              <th>
                <FormattedMessage id="ph.col.features" />
              </th>
              <th>
                <FormattedMessage id="ph.col.verification" />
              </th>
            </tr>
          </thead>
          <tbody>
            {data.journeys.map((j) => (
              <tr key={j.id}>
                <td>
                  <button type="button" className={`${linkClass} text-left font-medium text-foreground`} onClick={() => navigate('product', `journeys/${j.id}`)}>
                    {name(j.name, j.id)}
                  </button>
                  <div className="text-xs text-muted-foreground">{name(j.goal)}</div>
                </td>
                <td className="tabular-nums">{j.steps}</td>
                <td className="text-[12.5px]">
                  {j.features.map((f) => (
                    <button key={f} type="button" className={`${linkClass} mr-2 font-mono`} onClick={() => navigate('product', `features/${f}`)}>
                      {f}
                    </button>
                  ))}
                </td>
                <td>
                  <VerificationText value={j.verification} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Section>
  );
}

export function JourneyLoader({ id }: { id: string }) {
  const [load, reload] = useLoad<JourneyView>('productHubJourney', { id }, id);
  return <Loaded load={load} reload={reload}>{(d) => <JourneyDetail data={d} />}</Loaded>;
}

export function JourneyDetail({ data }: { data: JourneyView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const name = useLocalName();
  const j = data.journey;
  const featureName = (id: string) => name(data.features.find((f) => f.id === id)?.name, id);
  const list = (title: string, items: Array<{ vi: string; en: string }>) =>
    items.length ? (
      <Block title={title}>
        <ul className="grid list-disc gap-1 pl-4">
          {items.map((x, i) => (
            <li key={i}>{name(x)}</li>
          ))}
        </ul>
      </Block>
    ) : null;
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <div className="flex flex-wrap items-center gap-3">
        <Button kind="ghost" onClick={() => navigate('product', 'journeys')}>
          <ArrowLeft className="size-4" />
          <FormattedMessage id="ph.journeys.back" />
        </Button>
        <h2 className="text-lg font-semibold">{name(j.name, j.id)}</h2>
        <VerificationText value={j.verification} />
      </div>
      <Meta>
        <FormattedMessage id="ph.journeys.meta" values={{ rev: shortRev(j.revision) }} />
      </Meta>
      <div className="grid items-start gap-4 xl:grid-cols-[minmax(0,1fr)_300px] [&>*]:min-w-0">
        <Section title={<FormattedMessage id="ph.journeys.steps" />}>
          <div className="grid gap-4 text-sm">
            <Block title="ph.journeys.goal">{name(j.goal)}</Block>
            <Block title="ph.journeys.trigger">{name(j.trigger)}</Block>
            {list('ph.journeys.preconditions', j.preconditions)}
            <ol className="grid gap-2">
              {j.steps.map((st, i) => (
                <li key={i} className="flex gap-3">
                  <span className="grid size-6 shrink-0 place-items-center rounded-full bg-muted text-xs font-semibold tabular-nums">{i + 1}</span>
                  <span className="min-w-0 flex-1">
                    {name(st.text)}
                    {st.feature && (
                      <button type="button" className={`${linkClass} ml-2 text-xs`} onClick={() => navigate('product', `features/${st.feature}`)}>
                        {featureName(st.feature)}
                      </button>
                    )}
                  </span>
                </li>
              ))}
            </ol>
            {list('ph.journeys.alternatives', j.alternatives)}
            {list('ph.journeys.errors', j.errors)}
            <Block title="ph.journeys.completion">{name(j.completion)}</Block>
          </div>
        </Section>
        <div className="grid gap-4 [&>*]:min-w-0">
          <Section title={<FormattedMessage id="ph.col.features" />}>
            <ul className="grid gap-2 text-sm">
              {data.features.map((f) => (
                <li key={f.id} className="flex flex-wrap items-center gap-2">
                  <button type="button" className={`${linkClass} text-left`} onClick={() => navigate('product', `features/${f.id}`)}>
                    {name(f.name, f.id)}
                  </button>
                  <span className="text-xs text-muted-foreground">
                    <FormattedMessage id={`ph.lifecycle.${f.lifecycle}`} />
                  </span>
                </li>
              ))}
            </ul>
          </Section>
          <Section title={<FormattedMessage id="ph.journeys.metrics" />}>
            {j.metrics.length ? (
              <p className="font-mono text-[12.5px]">{j.metrics.join(' · ')}</p>
            ) : (
              <Meta>
                <FormattedMessage id="ph.none" />
              </Meta>
            )}
            <Meta>
              <FormattedMessage id="ph.journeys.metricsNote" />
            </Meta>
          </Section>
          <Section title={<FormattedMessage id="ph.journeys.sources" />}>
            <ul className="grid gap-1">
              {j.sources.map((s) => (
                <li key={s}>
                  <PathText path={s} />
                </li>
              ))}
            </ul>
            <Meta>{intl.formatMessage({ id: 'ph.journeys.sourcesNote' })}</Meta>
          </Section>
        </div>
      </div>
    </div>
  );
}

function Block({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="grid gap-1">
      <p className="text-xs font-semibold text-muted-foreground">
        <FormattedMessage id={title} />
      </p>
      <div>{children}</div>
    </div>
  );
}
