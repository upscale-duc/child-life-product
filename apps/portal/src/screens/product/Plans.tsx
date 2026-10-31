import { Check, Minus } from 'lucide-react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { Notice, Section } from '../../content-kit';
import { useNavigate } from '../../context';
import { shortDate } from '../../format';
import { Button, Loaded, Pill, TableScroll } from '../../ui';
import { AuthorityPill, ConflictText, Meta, PathText, linkClass } from './kit';
import type { PlansView } from './types';

export function PlansLoader() {
  const [load, reload] = useLoad<PlansView>('productHubPlans', {}, 'plans');
  return <Loaded load={load} reload={reload}>{(d) => <PlansView data={d} />}</Loaded>;
}

/**
 * Gói & quyền (doc 04 §2.4): Free / Premium by feature and capability, the default tier in code
 * beside the live one, and the open plan conflicts. Read only — changes are made in
 * "Tính năng & Premium" (D-089).
 */
export function PlansView({ data }: { data: PlansView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const yes = (on: boolean) =>
    on ? (
      <Check className="size-4 text-primary" aria-label={intl.formatMessage({ id: 'ph.yes' })} />
    ) : (
      <Minus className="size-4 text-muted-foreground" aria-label={intl.formatMessage({ id: 'ph.no' })} />
    );
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <Notice
        tone="info"
        action={
          <Button onClick={() => navigate('features')}>
            <FormattedMessage id="ph.access.change" />
          </Button>
        }
      >
        <FormattedMessage id="ph.plans.readOnly" />
      </Notice>

      {data.conflicts.length > 0 && (
        <Section title={<FormattedMessage id="ph.plans.conflicts" values={{ n: data.conflicts.length }} />}>
          <ul className="grid gap-3">
            {data.conflicts.map((c) => (
              <li key={c.id} className="grid gap-1.5 text-sm">
                <span><ConflictText conflict={c} /></span>
                {c.claims.map((cl, i) => (
                  <span key={i} className="flex flex-wrap items-center gap-2 text-[13px] text-muted-foreground">
                    <AuthorityPill authority={cl.authority} />
                    <PathText path={cl.path} />
                  </span>
                ))}
              </li>
            ))}
          </ul>
        </Section>
      )}

      <Section title={<FormattedMessage id="ph.plans.catalogue" />} flush>
        <TableScroll min={760}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="ph.plans.hubFeature" />
                </th>
                <th>
                  <FormattedMessage id="ph.access.defaultTier" />
                </th>
                <th>
                  <FormattedMessage id="ph.access.liveTier" />
                </th>
                <th>
                  <FormattedMessage id="ph.access.credits" />
                </th>
                <th>
                  <FormattedMessage id="ph.plans.features" />
                </th>
              </tr>
            </thead>
            <tbody>
              {data.catalogue.map((c) => (
                <tr key={c.key}>
                  <td>
                    <span className="font-medium">
                      <FormattedMessage id={`hub.feature.${c.key}`} />
                    </span>
                    <div className="font-mono text-xs text-muted-foreground">{c.key}</div>
                  </td>
                  <td>
                    <FormattedMessage id={`ph.tier.${c.defaultTier}`} />
                  </td>
                  <td>
                    {c.liveTier ? (
                      <span className="inline-flex items-center gap-1.5">
                        <FormattedMessage id={`ph.tier.${c.liveTier}`} />
                        {c.liveTier !== c.defaultTier && (
                          <Pill tone="info">
                            <FormattedMessage id="ph.plans.changed" />
                          </Pill>
                        )}
                      </span>
                    ) : (
                      <span className="text-muted-foreground">
                        <FormattedMessage id="ph.access.liveDefault" />
                      </span>
                    )}
                  </td>
                  <td>{yes(c.credits)}</td>
                  <td>
                    {c.features.length ? (
                      c.features.map((f) => (
                        <button
                          key={f}
                          type="button"
                          className={`${linkClass} mr-2 font-mono text-[12.5px]`}
                          onClick={() => navigate('product', `features/${f}`)}
                        >
                          {f}
                        </button>
                      ))
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      </Section>

      <Section title={<FormattedMessage id="ph.plans.capabilities" />} hint={<FormattedMessage id="ph.plans.capabilitiesHint" />} flush>
        <TableScroll min={560}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="ph.access.capabilities" />
                </th>
                <th>
                  <FormattedMessage id="ph.tier.free" />
                </th>
                <th>
                  <FormattedMessage id="ph.tier.premium" />
                </th>
                <th>
                  <FormattedMessage id="ph.plans.byCredits" />
                </th>
              </tr>
            </thead>
            <tbody>
              {data.capabilities.map((c) => (
                <tr key={c.key}>
                  <td className="font-mono text-[12.5px]">{c.key}</td>
                  <td>{yes(c.free)}</td>
                  <td>{yes(c.premium || c.free)}</td>
                  <td>{yes(c.credits)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      </Section>

      <Section title={<FormattedMessage id="ph.plans.decisions" />}>
        {data.decisions.length === 0 ? (
          <Meta>
            <FormattedMessage id="ph.plans.noDecisions" />
          </Meta>
        ) : (
          <ul className="grid gap-2 text-sm">
            {data.decisions.map((d) => (
              <li key={d.id} className="flex gap-2">
                <span className="font-mono text-[12.5px] font-semibold">{d.id}</span>
                <span className="min-w-0 flex-1">{d.title}</span>
                {d.date && <span className="text-muted-foreground tabular-nums">{shortDate(intl, d.date)}</span>}
              </li>
            ))}
          </ul>
        )}
      </Section>
    </div>
  );
}
