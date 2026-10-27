import {
  staffCan,
  printCancellationReasons,
  type PrintCatalog,
  type PrintOrderStatus,
} from '@child-life/contracts';
import { useEffect, useState } from 'react';
import { useIntl } from 'react-intl';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useApi, useLoad } from '../api';
import { useStaff } from '../context';
import { Button, Loaded, Page, Panel, SelectMenu, TableScroll } from '../ui';
import { Section } from '../content-kit';

interface OrderRow {
  id: string;
  babyId: string;
  status: PrintOrderStatus;
  total: number;
  renderStatus?: string;
  createdAt: string;
}
interface Order extends OrderRow {
  fileUrl: string | null;
  address: {
    recipient: string;
    phone: string;
    address: string;
    country: string;
    giftMessage: string;
  };
  tracking?: string;
  paymentMethod?: string;
  giftWrapFee?: number;
  subtotal: number;
  shipping: number;
  pricesEstimated: boolean;
  contacted: boolean;
  internalNote: string;
  printPartner: string;
  cancellationReason?: string;
  updatedAt: string;
  render?: { status: string; attempt: number; error: string | null; leaseUntil: string | null };
  design: { name: string; title: string; date: string; product: string; size: string };
}
interface Data {
  demand: Array<Record<string, number | string>>;
  catalog: PrintCatalog;
  orders: OrderRow[];
  reviews: Array<{ id: string; rating: number; message: string; product: string }>;
}

export function PrintStudioScreen() {
  const intl = useIntl(),
    api = useApi(),
    staff = useStaff(),
    [load, reload] = useLoad<Data>('staffPrintStudio', {}, 'print-studio');
  const [catalog, setCatalog] = useState<PrintCatalog | null>(null),
    [order, setOrder] = useState<Order | null>(null),
    [busy, setBusy] = useState(false),
    [notice, setNotice] = useState('');
  const [tracking, setTracking] = useState(''),
    [note, setNote] = useState(''),
    [partner, setPartner] = useState(''),
    [contacted, setContacted] = useState(false),
    [customerConfirmed, setCustomerConfirmed] = useState(false),
    [quoteSubtotal, setQuoteSubtotal] = useState(''),
    [quoteShipping, setQuoteShipping] = useState(''),
    [reason, setReason] = useState<string>('customer_changed_mind');
  useEffect(() => {
    if (!order || !['queued', 'rendering'].includes(order.render?.status ?? '')) return;
    let active = true;
    const timer = setInterval(() => {
      void api
        .call<Order>('staffPrintOrder', { babyId: order.babyId, id: order.id })
        .then((next) => {
          if (active)
            setOrder((current) =>
              current?.id === next.id && current.updatedAt <= next.updatedAt ? next : current,
            );
        })
        .catch(() => {});
    }, 5000);
    return () => {
      active = false;
      clearInterval(timer);
    };
  }, [api, order?.id, order?.babyId, order?.render?.status]);
  const t = (id: string) => intl.formatMessage({ id: id.startsWith('nav.') ? id : `print.${id}` });
  const money = (n: number) =>
    intl.formatNumber(n, { style: 'currency', currency: 'VND', maximumFractionDigits: 0 });
  const canConfig = staffCan(staff.levels, 'system.video'),
    canEdit = staffCan(staff.levels, 'support.reply');
  async function run(action: () => Promise<void>) {
    if (busy) return;
    setBusy(true);
    setNotice('');
    try {
      await action();
    } catch {
      setNotice(t('error'));
    } finally {
      setBusy(false);
    }
  }
  async function open(o: OrderRow) {
    await run(async () => {
      const d = await api.call<Order>('staffPrintOrder', { babyId: o.babyId, id: o.id });
      setOrder(d);
      setNote(d.internalNote);
      setPartner(d.printPartner);
      setContacted(d.contacted);
      setCustomerConfirmed(false);
      setQuoteSubtotal(String(d.subtotal));
      setQuoteShipping(String(d.shipping));
      setReason('customer_changed_mind');
      setTracking(d.tracking ?? '');
    });
  }
  async function advance(status?: PrintOrderStatus, retryRender = false) {
    if (!order) return;
    await run(async () => {
      const d = await api.call<Order>('staffPrintOrder', {
        babyId: order.babyId,
        id: order.id,
        ...(status ? { status } : {}),
        tracking,
        note,
        printPartner: partner,
        contacted,
        reason,
        retryRender,
        ...(status === 'confirmed'
          ? {
              customerConfirmed,
              quote: { subtotal: Number(quoteSubtotal), shipping: Number(quoteShipping) },
            }
          : {}),
      });
      setOrder(d);
      reload();
    });
  }
  const data = load.status === 'ok' ? load.data : null,
    c = catalog ?? data?.catalog;
  const edit = (patch: Partial<PrintCatalog>) => c && setCatalog({ ...c, ...patch });
  function field(
    label: string,
    value: string | number,
    onChange: (value: string) => void,
    type = 'text',
  ) {
    return (
      <label className="grid gap-2">
        {t(label)}
        <Input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          disabled={!canConfig || busy}
        />
      </label>
    );
  }
  if (load.status !== 'ok') {
    return (
      <Page title={t('title')}>
        <Loaded load={load} reload={reload}>
          {() => null}
        </Loaded>
      </Page>
    );
  }
  return (
    <Page
      title={t('title')}
      actions={
        <Button onClick={reload} disabled={busy}>
          {t('refresh')}
        </Button>
      }
    >
      <div className="stack">
        <p className="muted">{t('notice')}</p>
        {notice && <p role="status">{notice}</p>}
        {data && canEdit && data.reviews.length > 0 && (
          <Panel title={t('reviews')}>
            {data.reviews.map((r) => (
              <div key={r.id} className="grid gap-3 border-b py-4">
                <p>
                  {r.rating} ★ · {r.product}
                </p>
                <p>{r.message}</p>
                <div className="flex gap-3">
                  <Button
                    disabled={busy}
                    onClick={() =>
                      void run(async () => {
                        await api.call('staffPrintReview', { id: r.id, publish: true });
                        reload();
                      })
                    }
                  >
                    {t('publish')}
                  </Button>
                  <Button
                    disabled={busy}
                    onClick={() =>
                      void run(async () => {
                        await api.call('staffPrintReview', { id: r.id, publish: false });
                        reload();
                      })
                    }
                  >
                    {t('reject')}
                  </Button>
                </div>
              </div>
            ))}
          </Panel>
        )}
        {data && (
          <Panel title={t('orders')} note={t('access')}>
            <TableScroll>
              <table className="table">
                <thead>
                  <tr>
                    {['id', 'status', 'total', 'render'].map((k) => (
                      <th key={k}>{t(k)}</th>
                    ))}
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {data.orders.map((o) => (
                    <tr key={o.id}>
                      <td>{o.id}</td>
                      <td>{t(o.status)}</td>
                      <td>{money(o.total)}</td>
                      <td>{t(`render.${o.renderStatus ?? 'ready'}`)}</td>
                      <td>
                        <Button onClick={() => void open(o)} disabled={busy || !canEdit}>
                          {t('open')}
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableScroll>
            {!data.orders.length && <p>{t('empty')}</p>}
          </Panel>
        )}
        {order && (
          <Panel
            title={order.id}
            aside={
              <Button onClick={() => setOrder(null)}>
                {intl.formatMessage({ id: 'action.close' })}
              </Button>
            }
          >
            <p>
              {t(order.status)} · {money(order.total)}
            </p>
            <h3>{t('address')}</h3>
            <p>
              {order.address.recipient}
              <br />
              {order.address.phone}
              <br />
              {order.address.address} · {order.address.country}
            </p>
            <p>{t(order.paymentMethod === 'bankTransfer' ? 'bankTransfer' : 'cod')}</p>
            {!!order.giftWrapFee && (
              <p>
                {t('giftWrapFee')}: {money(order.giftWrapFee)}
              </p>
            )}
            {order.address.giftMessage && <p>{order.address.giftMessage}</p>}
            <p>
              {order.design.name} · {order.design.title} · {order.design.size} cm
            </p>
            <p>{order.pricesEstimated ? t('estimated') : t('agreedPrice')}</p>
            <div className="my-4 grid gap-3">
              <p>
                {t('render')}: {t(`render.${order.render?.status ?? 'ready'}`)}
              </p>
              {order.render?.status === 'failed' && (
                <p role="alert">
                  {t(
                    order.render.error === 'photo-unavailable'
                      ? 'photoUnavailable'
                      : order.render.error === 'low-resolution'
                        ? 'lowResolution'
                        : 'renderFailed',
                  )}
                </p>
              )}
              {order.fileUrl ? (
                <a href={order.fileUrl} target="_blank" rel="noreferrer">
                  {t('file')}
                </a>
              ) : order.render?.status === 'ready' ? (
                <p>{t('fileExpired')}</p>
              ) : null}
              {canEdit &&
                (order.render?.status === 'failed' ||
                  (order.render?.status === 'rendering' &&
                    order.render.leaseUntil &&
                    Date.parse(order.render.leaseUntil) <= Date.now())) &&
                !['delivered', 'cancelled'].includes(order.status) && (
                  <Button disabled={busy} onClick={() => void advance(undefined, true)}>
                    {t('retryRender')}
                  </Button>
                )}
            </div>
            {canEdit && (
              <div className="grid gap-4 mt-4">
                <label>
                  <input
                    type="checkbox"
                    checked={contacted}
                    disabled={busy}
                    onChange={(e) => setContacted(e.target.checked)}
                  />
                  {t('contacted')}
                </label>
                <label className="grid gap-2">
                  {t('partner')}
                  <Input
                    value={partner}
                    maxLength={120}
                    disabled={busy}
                    onChange={(e) => setPartner(e.target.value)}
                  />
                </label>
                <label className="grid gap-2">
                  {t('note')}
                  <Textarea
                    value={note}
                    maxLength={2000}
                    disabled={busy}
                    onChange={(e) => setNote(e.target.value)}
                  />
                </label>
                <label className="grid gap-2">
                  {t('tracking')}
                  <Input
                    value={tracking}
                    maxLength={100}
                    disabled={busy}
                    onChange={(e) => setTracking(e.target.value)}
                  />
                </label>
                <Button disabled={busy} onClick={() => void advance()}>
                  {t('saveDetails')}
                </Button>
                {order.status === 'pendingConfirmation' && (
                  <>
                    <div className="grid gap-3 md:grid-cols-2">
                      <label>
                        {t('subtotal')}
                        <Input
                          type="number"
                          min="0"
                          value={quoteSubtotal}
                          onChange={(e) => setQuoteSubtotal(e.target.value)}
                        />
                      </label>
                      <label>
                        {t('shipping')}
                        <Input
                          type="number"
                          min="0"
                          value={quoteShipping}
                          onChange={(e) => setQuoteShipping(e.target.value)}
                        />
                      </label>
                    </div>
                    <p>
                      {t('total')}: {money(Number(quoteSubtotal) + Number(quoteShipping))}
                    </p>
                    <label>
                      <input
                        type="checkbox"
                        checked={customerConfirmed}
                        disabled={busy}
                        onChange={(e) => setCustomerConfirmed(e.target.checked)}
                      />
                      {t('customerConfirmed')}
                    </label>
                    <Button
                      kind="primary"
                      disabled={
                        busy ||
                        !customerConfirmed ||
                        !quoteSubtotal ||
                        !quoteShipping ||
                        !Number.isInteger(Number(quoteSubtotal)) ||
                        !Number.isInteger(Number(quoteShipping)) ||
                        Number(quoteSubtotal) < 0 ||
                        Number(quoteShipping) < 0
                      }
                      onClick={() => void advance('confirmed')}
                    >
                      {t('confirmOrder')}
                    </Button>
                  </>
                )}
                {order.status === 'confirmed' && (
                  <Button
                    kind="primary"
                    disabled={busy || !order.fileUrl || order.render?.status !== 'ready'}
                    onClick={() => void advance('printing')}
                  >
                    {t('start')}
                  </Button>
                )}
                {order.status === 'printing' && (
                  <Button kind="primary" disabled={busy} onClick={() => void advance('shipped')}>
                    {t('ship')}
                  </Button>
                )}
                {order.status === 'shipped' && (
                  <Button kind="primary" disabled={busy} onClick={() => void advance('delivered')}>
                    {t('deliver')}
                  </Button>
                )}
                {['pendingConfirmation', 'confirmed'].includes(order.status) && (
                  <>
                    <SelectMenu
                      label={t('cancelReason')}
                      value={reason}
                      onChange={setReason}
                      options={printCancellationReasons.map((r) => ({
                        value: r,
                        label: t(`reason.${r}`),
                      }))}
                    />
                    <Button kind="danger" disabled={busy} onClick={() => void advance('cancelled')}>
                      {t('cancel')}
                    </Button>
                  </>
                )}
              </div>
            )}
          </Panel>
        )}

        {data && (
          <Section collapsible defaultOpen={false} title={t('demand')} hint={t('demandNote')}>
            <div className="grid gap-3 md:grid-cols-5">
              {['viewed', 'designStarted', 'submitted', 'confirmed', 'delivered'].map((event) => (
                <div key={event}>
                  <p>{t(`demand.${event}`)}</p>
                  <strong>
                    {data.demand.reduce((sum, row) => sum + Number(row[event] ?? 0), 0)}
                  </strong>
                </div>
              ))}
            </div>
            <div className="mt-4 grid gap-2 md:grid-cols-3">
              {printCancellationReasons.map((reason) => (
                <p key={reason}>
                  {t(`reason.${reason}`)}:{' '}
                  {data.demand.reduce(
                    (sum, row) => sum + Number(row[`cancelled_${reason}`] ?? 0),
                    0,
                  )}
                </p>
              ))}
            </div>
          </Section>
        )}
        {c && canConfig && (
          <Section collapsible defaultOpen={false} title={t('config')}>
            <div className="grid gap-4 md:grid-cols-2">
              <label>
                <input
                  type="checkbox"
                  checked={c.digitalEnabled}
                  disabled={busy}
                  onChange={(e) => edit({ digitalEnabled: e.target.checked })}
                />
                {t('digital')}
              </label>
              <label>
                <input
                  type="checkbox"
                  checked={c.physicalEnabled}
                  disabled={busy}
                  onChange={(e) => edit({ physicalEnabled: e.target.checked })}
                />
                {t('physical')}
              </label>
              {field('countries', c.supportedCountries.join(', '), (v) =>
                edit({
                  supportedCountries: v
                    .split(',')
                    .map((s) => s.trim().toUpperCase())
                    .filter(Boolean),
                }),
              )}
              <label>
                <input
                  type="checkbox"
                  checked={c.pricesEstimated}
                  disabled={busy}
                  onChange={(e) => edit({ pricesEstimated: e.target.checked })}
                />
                {t('pricesEstimated')}
              </label>
              <div>
                <p>{t('orderProducts')}</p>
                {(['single', 'trio', 'five', 'book'] as const).map((product) => (
                  <label key={product} className="flex gap-2 my-2">
                    <input
                      type="checkbox"
                      checked={c.orderProducts.includes(product)}
                      disabled={busy}
                      onChange={(e) =>
                        edit({
                          orderProducts: e.target.checked
                            ? [...c.orderProducts, product]
                            : c.orderProducts.filter((p) => p !== product),
                        })
                      }
                    />
                    {t(`product.${product}`)}
                  </label>
                ))}
              </div>
              {(
                [
                  'leadDays',
                  'shippingFee',
                  'freeShippingFrom',
                  'giftSurcharge',
                  'giftWrapFee',
                ] as const
              ).map((k, i) => (
                <div key={k}>
                  {field(
                    ['lead', 'shipping', 'freeFrom', 'gift', 'giftWrapFee'][i]!,
                    c[k],
                    (v) => edit({ [k]: Number(v) }),
                    'number',
                  )}
                </div>
              ))}
              {(['vi', 'en'] as const).map((lang) => (
                <label key={lang}>
                  {t(lang === 'vi' ? 'policyVi' : 'policyEn')}
                  <Textarea
                    value={c.policy[lang]}
                    maxLength={4000}
                    onChange={(e) => edit({ policy: { ...c.policy, [lang]: e.target.value } })}
                  />
                </label>
              ))}
            </div>
            <h3 className="mt-6 mb-3">{t('prices')}</h3>
            <div className="grid gap-3 md:grid-cols-3">
              {Object.entries(c.prices).map(([key, value]) => (
                <label key={key}>
                  {key}
                  <Input
                    type="number"
                    min="0"
                    value={value}
                    onChange={(e) =>
                      edit({ prices: { ...c.prices, [key]: Number(e.target.value) } })
                    }
                  />
                </label>
              ))}
            </div>
            <div className="mt-6">
              <Button
                kind="primary"
                disabled={busy}
                onClick={() =>
                  void run(async () => {
                    await api.call('staffPrintCatalog', { catalog: c });
                    setCatalog(null);
                    reload();
                    setNotice(t('saved'));
                  })
                }
              >
                {t('save')}
              </Button>
            </div>
          </Section>
        )}
      </div>
    </Page>
  );
}
