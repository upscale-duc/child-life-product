import type { SupportedLocale } from '@child-life/web-config';

/** Every string on the landing, per language (D-012). Vietnamese is the Figma source
 *  (Website 219:1391 / 233:804); English is drafted by engineering for owner review.
 *  Strings inside mockups are illustrative app UI and are localized too. */

export type CareKind = 'bottle' | 'breast' | 'sleep' | 'diaper' | 'pump' | 'growth';

export interface PageMeta {
  title: string;
  description: string;
}

export interface Bullet {
  title: string;
  sub?: string;
}

export interface CareTileText {
  label: string;
  value: string;
  meta: [string, string];
}

export interface Permission {
  allowed: boolean;
  title: string;
  sub: string;
}

export interface RoleCard {
  initial: string;
  role: string;
  description: string;
  permissions: [Permission, Permission, Permission];
}

export interface FaqItem {
  q: string;
  a: string;
  open: boolean;
}

export interface LegalPage {
  meta: PageMeta;
  title: string;
  status: string;
  paragraphs: string[];
  contactLead: string;
}

export interface Content {
  locale: SupportedLocale;
  /** Name of this language in itself, shown on the language switch of the other page. */
  languageName: string;
  meta: PageMeta & { ogAlt: string };
  skipToContent: string;
  nav: {
    homeLabel: string;
    sectionsLabel: string;
    links: { care: string; memories: string; family: string; nights: string; faq: string };
    download: string;
    downloadShort: string;
    /** Shown on this page, pointing to the other language. */
    switchLabel: string;
    switchShort: string;
  };
  /** Offered on the other language's page when the browser prefers this language. */
  languageSuggestion: { text: string; action: string; dismiss: string };
  stores: {
    appStore: { prefix: string; name: string };
    googlePlay: { prefix: string; name: string };
    /** `{store}` is replaced by the store name. */
    comingSoon: string;
    close: string;
  };
  mock: {
    baby: string;
    babyAge: string;
    date: string;
    live: {
      app: string;
      shared: string;
      title: string;
      sub: string;
      timer: string;
      wake: string;
      editStart: string;
    };
    bottleWidget: { label: string; ago: string; meta: string; button: string };
    circular: { sleep: string; feed: string; sleepLabel: string; feedLabel: string };
  };
  hero: {
    eyebrow: string;
    title: [string, string, string];
    lead: string;
    caption: string;
    proofInitials: [string, string, string, string];
    proof: string;
    chips: [{ title: string; sub: string }, { title: string; sub: string }];
    today: {
      title: string;
      tiles: Record<CareKind, CareTileText>;
      reminder: { label: string; title: string; when: string };
      section: { title: string; link: string };
    };
    album: {
      title: string;
      count: string;
      newAlbum: string;
      albums: [AlbumText, AlbumText, AlbumText, AlbumText];
      segments: [string, string, string, string];
      navActive: string;
      navInitial: string;
    };
  };
  quick: {
    eyebrow: string;
    title: string;
    lead: string;
    labels: [string, string];
    large: {
      status: string;
      statusSub: string;
      sleepButton: string;
      recentTitle: string;
      recent: [RecentRow, RecentRow, RecentRow];
      totals: string;
    };
    tiles: Record<'bottle' | 'breast' | 'sleep' | 'diaper', { label: string; value: string }>;
    mediumMeta: string;
    logged: { title: string; meta: string; undo: string; edit: string };
    note: string;
    steps: [Bullet, Bullet, Bullet];
  };
  care: {
    eyebrow: string;
    title: string;
    lead: string;
    bullets: [Bullet, Bullet, Bullet];
    bottle: CareTileText;
    sleep: CareTileText;
    chip: string;
    rhythm: {
      title: string;
      totals: [[string, string], [string, string], [string, string], [string, string]];
      axis: [string, string, string, string, string];
      legend: [string, string, string, string];
    };
  };
  cocare: {
    eyebrow: string;
    title: string;
    lead: string;
    bullets: [string, string, string];
    initials: { mother: string; father: string; grandma: string; nanny: string };
    chip: string;
    feed: { title: string; rows: [[string, string], [string, string], [string, string]] };
  };
  memories: {
    eyebrow: string;
    title: string;
    lead: string;
    timeline: [Milestone, Milestone, Milestone, Milestone, Milestone, Milestone, Milestone];
    timelineEnd: string;
    tiles: {
      photos: { title: string; body: string; chip: string };
      story: {
        title: string;
        body: string;
        letter: { greeting: string; body: string; signature: string };
        moment: { caption: string; quote: string; tag: string };
      };
      family: {
        title: string;
        body: string;
        notifications: [Notification, Notification, Notification];
      };
    };
  };
  night: {
    eyebrow: string;
    title: string;
    lead: string;
    checks: [string, string];
    sleepWidget: { label: string; sub: string };
  };
  roles: {
    eyebrow: string;
    title: string;
    lead: string;
    allowed: string;
    notAllowed: string;
    cards: [RoleCard, RoleCard, RoleCard];
    notes: [string, string];
  };
  cta: {
    title: [string, string];
    sub: string;
    caption: string;
  };
  faq: {
    title: string;
    sub: [string, string, string];
    items: [FaqItem, FaqItem, FaqItem, FaqItem, FaqItem];
  };
  footer: {
    copyright: string;
    privacy: string;
    terms: string;
    contact: string;
    email: string;
    languageLabel: string;
    linksLabel: string;
  };
  legal: {
    privacy: LegalPage;
    terms: LegalPage;
    back: string;
  };
}

export interface AlbumText {
  name: string;
  meta: string;
  shared: boolean;
}

export interface RecentRow {
  time: string;
  label: string;
  who: string;
}

export interface Milestone {
  age: string;
  title: string;
}

export interface Notification {
  initial: string;
  text: string;
  when: string;
}
