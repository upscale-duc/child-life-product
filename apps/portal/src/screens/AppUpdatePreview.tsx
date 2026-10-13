import type { AppUpdateConfig, AppUpdateHighlight, AppUpdateText } from '@child-life/contracts';
import { useState, type CSSProperties, type ReactNode } from 'react';
import { FormattedMessage, IntlProvider, useIntl } from 'react-intl';
import { appIcons, appMark, appPalettes } from '../app-icons';
import type { FirstAidImage } from '../api';
import { messages } from '../messages';
import { Segmented } from '../ui';

/**
 * A phone showing what the app will show (D-061, v1.0 improvement UP1–UP6), drawn at the
 * design's 375 × 812 with the app's icons, colours and copy, live as the form changes. The copy
 * is the app's, in the language picked here, not the portal's.
 */
export type PreviewScreen = 'required' | 'available' | 'banner' | 'pages' | 'version';

export function AppUpdatePreview({
  config,
  images,
  initial = 'available',
}: {
  config: AppUpdateConfig;
  images: FirstAidImage[];
  initial?: PreviewScreen;
}) {
  const intl = useIntl();
  const [screen, setScreen] = useState<PreviewScreen>(initial);
  const [lang, setLang] = useState<'vi' | 'en'>('vi');
  const [platform, setPlatform] = useState<'ios' | 'android'>('ios');
  // The app's own palette, whatever the portal's light / dark theme.
  const [palette, setPalette] = useState<'light' | 'night'>('light');
  const [page, setPage] = useState(0);
  const pages = config.release?.pages ?? [];
  const pageIndex = Math.min(page, Math.max(pages.length - 1, 0));
  return (
    <div className="aup">
      <Segmented
        label={intl.formatMessage({ id: 'au.pv.screen' })}
        value={screen}
        onChange={setScreen}
        options={(['required', 'available', 'banner', 'pages', 'version'] as const).map((s) => ({
          value: s,
          label: <FormattedMessage id={`au.pv.tab.${s}`} />,
        }))}
      />
      <div className="aup__controls">
        <Segmented
          label={intl.formatMessage({ id: 'au.pv.lang' })}
          value={lang}
          onChange={setLang}
          options={[
            { value: 'vi', label: 'Tiếng Việt' },
            { value: 'en', label: 'English' },
          ]}
        />
        <Segmented
          label={intl.formatMessage({ id: 'au.pv.palette' })}
          value={palette}
          onChange={setPalette}
          options={[
            { value: 'light', label: <FormattedMessage id="au.pv.light" /> },
            { value: 'night', label: <FormattedMessage id="au.pv.night" /> },
          ]}
        />
        <Segmented
          label={intl.formatMessage({ id: 'au.pv.platform' })}
          value={platform}
          onChange={setPlatform}
          options={[
            { value: 'ios', label: 'iOS' },
            { value: 'android', label: 'Android' },
          ]}
        />
      </div>
      <div
        className="aup__frame"
        aria-label={intl.formatMessage({ id: 'au.pv.label' })}
        role="img"
        style={appPalettes[palette] as CSSProperties}
      >
        <div className="aup__screen">
          <IntlProvider locale={lang} defaultLocale="vi" messages={messages[lang]}>
            <Phone
              screen={screen}
              config={config}
              images={images}
              lang={lang}
              platform={platform}
              page={pageIndex}
              onPage={setPage}
            />
          </IntlProvider>
        </div>
      </div>
      <p className="field__help">
        <FormattedMessage id={`au.pv.when.${screen}`} />
      </p>
    </div>
  );
}

/** The app's line icon (24 grid, 1.8 stroke) at [size]. */
export function AppIcon({
  name,
  size = 20,
  color,
}: {
  name: string;
  size?: number;
  color?: string;
}) {
  const icon = appIcons[name];
  if (!icon) return null;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      aria-hidden="true"
      style={{ color, flex: 'none' }}
      // Generated from the app's own SVG files (scripts/app-icons.py).
      dangerouslySetInnerHTML={{ __html: `<g ${icon.attrs}>${icon.body}</g>` }}
    />
  );
}

function Mark({ size }: { size: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox={appMark.viewBox}
      aria-hidden="true"
      dangerouslySetInnerHTML={{ __html: appMark.body }}
    />
  );
}

const text = (t: AppUpdateText | null | undefined, lang: 'vi' | 'en') =>
  (lang === 'en' ? t?.en || t?.vi : t?.vi) ?? '';

/** An older version for the examples: just below the minimum, or below latest. */
function olderThan(version: string | null | undefined): string {
  const [a = 1, b = 0, c = 0] = (version ?? '1.0.0').split('.').map(Number);
  if (c > 0) return `${a}.${b}.${c - 1}`;
  if (b > 0) return `${a}.${b - 1}.9`;
  return a > 0 ? `${a - 1}.9.9` : '0.0.0';
}

function Phone({
  screen,
  config,
  images,
  lang,
  platform,
  page,
  onPage,
}: {
  screen: PreviewScreen;
  config: AppUpdateConfig;
  images: FirstAidImage[];
  lang: 'vi' | 'en';
  platform: 'ios' | 'android';
  page: number;
  onPage: (i: number) => void;
}) {
  const p = config[platform];
  const release = config.release;
  const latest = p.latest;
  switch (screen) {
    case 'required': {
      if (!p.minimum || !latest) return <Note id="au.pv.noMinimum" />;
      const notes = release && release.version === latest && release.pages.length > 0;
      return (
        <div className="aup-up1">
          <div className="aup-up1__art">
            <span className="aup-up1__sun" />
            <span className="aup-up1__halo" />
            <span className="aup-up1__icon">
              <Mark size={64} />
            </span>
            <span className="aup-up1__badge">
              <span style={{ display: 'inline-flex', transform: 'rotate(-90deg)' }}>
                <AppIcon name="arrow-right" size={18} color="#fff" />
              </span>
            </span>
            <span className="aup-pill">
              <span className="muted">{olderThan(p.minimum)}</span>
              <AppIcon name="arrow-right" size={14} color="var(--ink-muted)" />
              <strong className="aup-mint">{latest}</strong>
            </span>
          </div>
          <h3 className="aup-h1">
            <FormattedMessage id="au.app.requiredTitle" />
          </h3>
          <p className="aup-body">
            <FormattedMessage id="au.app.requiredBody" />
          </p>
          <div className="aup-card">
            <Row icon="lock" tone={['var(--mint-soft)', 'var(--mint-text)']} small>
              <strong>
                <FormattedMessage id="au.app.safeTitle" />
              </strong>
              <span>
                <FormattedMessage id="au.app.safeBody" />
              </span>
            </Row>
          </div>
          <div className="aup-bottom">
            <span className="aup-btn">
              <FormattedMessage
                id={platform === 'ios' ? 'au.app.openAppStore' : 'au.app.openPlay'}
              />
            </span>
            <div className="aup-links">
              {notes && (
                <span className="aup-link">
                  <FormattedMessage id="au.app.whatsNewIn" values={{ version: latest }} />
                </span>
              )}
              <span className="aup-link aup-link--danger">
                <AppIcon name="alert" size={16} />
                <FormattedMessage id="au.app.firstAid" />
              </span>
            </div>
          </div>
        </div>
      );
    }
    case 'available': {
      if (!latest) return <Note id="au.pv.noLatest" />;
      const rows = release && release.version === latest ? release.highlights : [];
      return (
        <div className="aup-today aup-today--dim">
          <TodayBackdrop />
          <div className="aup-sheet">
            <span className="aup-grab" />
            <div className="aup-sheet__head">
              <span className="aup-appicon">
                <Mark size={36} />
              </span>
              <div>
                <span className="aup-tag">
                  <FormattedMessage id="au.app.newTag" values={{ version: latest }} />
                </span>
                <h3 className="aup-h2">
                  <FormattedMessage id="au.app.newTitle" />
                </h3>
              </div>
            </div>
            {rows.map((h, i) => (
              <Highlight key={i} h={h} lang={lang} />
            ))}
            <span className="aup-btn">
              <FormattedMessage id="au.app.update" />
            </span>
            <span className="aup-link">
              <FormattedMessage id="au.app.later" />
            </span>
          </div>
        </div>
      );
    }
    case 'banner': {
      if (!release || release.pages.length === 0) return <Note id="au.pv.noPages" />;
      return (
        <div className="aup-today">
          <p className="aup-date">
            <FormattedMessage id="au.app.todayDate" />
          </p>
          <h3 className="aup-title">
            <FormattedMessage id="au.app.today" />
          </h3>
          <div className="aup-banner">
            <span className="aup-banner__ic">
              <AppIcon name="spark" size={18} color="var(--ink)" />
            </span>
            <span className="aup-banner__t">
              <strong>
                <FormattedMessage id="au.app.bannerTitle" values={{ version: release.version }} />
              </strong>
              <span>{text(release.summary, lang)}</span>
            </span>
            <strong className="aup-mint">
              <FormattedMessage id="au.app.see" />
            </strong>
            <AppIcon name="close" size={16} color="var(--ink-muted)" />
          </div>
          <TodayTiles />
        </div>
      );
    }
    case 'pages': {
      const pages = release?.pages ?? [];
      const current = pages[page];
      if (!release || !current) return <Note id="au.pv.noPages" />;
      const url = images.find((i) => i.id === current.image)?.url;
      return (
        <div className="aup-up3">
          <div className="aup-up3__top">
            <span className="aup-dots">
              {pages.map((_, i) => (
                <button
                  key={i}
                  type="button"
                  className={i === page ? 'aup-dot aup-dot--on' : 'aup-dot'}
                  aria-label={`${i + 1}`}
                  onClick={() => onPage(i)}
                />
              ))}
            </span>
            <span className="aup-skip">
              <FormattedMessage id="au.app.skip" />
            </span>
          </div>
          <div className="aup-up3__image">
            {url ? (
              <img src={url} alt="" />
            ) : (
              <span className="aup-up3__ph">
                <Mark size={72} />
              </span>
            )}
            <span className="aup-tag aup-tag--over">
              <FormattedMessage id="au.app.pageTag" values={{ version: release.version }} />
            </span>
          </div>
          <h3 className="aup-h1">{text(current.title, lang)}</h3>
          <p className="aup-body">{text(current.body, lang)}</p>
          {current.where && (text(current.where, lang) || null) && (
            <span className="aup-where">
              <AppIcon name="grid" size={16} color="var(--ink)" />
              {text(current.where, lang)}
            </span>
          )}
          <div className="aup-bottom">
            <button
              type="button"
              className="aup-btn"
              onClick={() => onPage(page + 1 < pages.length ? page + 1 : 0)}
            >
              <FormattedMessage id={page + 1 < pages.length ? 'au.app.next' : 'au.app.done'} />
            </button>
          </div>
        </div>
      );
    }
    case 'version': {
      const installed = latest ? olderThan(latest) : '1.0.0';
      return (
        <div className="aup-today">
          <h3 className="aup-title">
            <FormattedMessage id="au.app.me" />
          </h3>
          <div className="aup-card aup-card--rows">
            <Row icon="lock" plain>
              <strong>
                <FormattedMessage id="au.app.account" />
              </strong>
            </Row>
            <Row
              icon="retry"
              plain
              trailing={
                latest ? (
                  <span className="aup-tag">
                    <FormattedMessage id="au.app.update" />
                  </span>
                ) : null
              }
            >
              <strong>
                <FormattedMessage id="au.app.versionTitle" values={{ version: installed }} />
              </strong>
              <span>
                {latest ? (
                  <FormattedMessage id="au.app.newVersion" values={{ version: latest }} />
                ) : (
                  <FormattedMessage id="au.app.latestVersion" />
                )}
              </span>
            </Row>
          </div>
        </div>
      );
    }
  }
}

function Note({ id }: { id: string }) {
  return (
    <div className="aup-note">
      <Mark size={56} />
      <p>
        <FormattedMessage id={id} />
      </p>
    </div>
  );
}

const tones: Record<AppUpdateHighlight['tone'], [string, string]> = {
  danger: ['var(--error-soft)', 'var(--error)'],
  growth: ['var(--care-growth-soft)', 'var(--care-growth-ink)'],
  pump: ['var(--care-pump-soft)', 'var(--care-pump-ink)'],
  sleep: ['var(--care-sleep-soft)', 'var(--care-sleep-ink)'],
  bottle: ['var(--care-bottle-soft)', 'var(--care-bottle-ink)'],
  mint: ['var(--mint-soft)', 'var(--mint-text)'],
  sunshine: ['var(--sunshine-soft)', 'var(--ink)'],
};

function Highlight({ h, lang }: { h: AppUpdateHighlight; lang: 'vi' | 'en' }) {
  return (
    <Row icon={h.icon} tone={tones[h.tone]}>
      <strong>{text(h.title, lang) || '—'}</strong>
      <span>{text(h.body, lang)}</span>
    </Row>
  );
}

function Row({
  icon,
  tone,
  small,
  plain,
  trailing,
  children,
}: {
  icon: string;
  tone?: [string, string];
  small?: boolean;
  plain?: boolean;
  trailing?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className={`aup-row ${small ? 'aup-row--small' : ''}`}>
      {plain ? (
        <AppIcon name={icon} size={20} color="var(--ink)" />
      ) : (
        <span className="aup-row__ic" style={{ background: tone?.[0] }}>
          <AppIcon name={icon} size={small ? 18 : 20} color={tone?.[1]} />
        </span>
      )}
      <span className="aup-row__t">{children}</span>
      {trailing}
    </div>
  );
}

/** Hôm nay behind the UP2 sheet: just enough to read as the home screen. */
function TodayBackdrop() {
  return (
    <>
      <p className="aup-date">
        <FormattedMessage id="au.app.todayDate" />
      </p>
      <h3 className="aup-title">
        <FormattedMessage id="au.app.today" />
      </h3>
      <TodayTiles />
    </>
  );
}

function TodayTiles() {
  return (
    <div className="aup-tiles">
      {(['bottle', 'breast', 'sleep', 'diaper'] as const).map((t) => (
        <span key={t} className="aup-tile" style={{ background: `var(--care-${t}-soft)` }} />
      ))}
    </div>
  );
}
