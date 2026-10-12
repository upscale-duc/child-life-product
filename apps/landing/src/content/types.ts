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

/** Bullet of the v3 sections; `subShort` is the mobile wording (Figma 324:45487). */
export interface CompactBullet {
  title: string;
  sub: string;
  subShort: string;
}

export interface BentoTile {
  title: string;
  body: string;
  /** Mobile tiles carry a shorter body. */
  bodyShort: string;
}

export interface StageText {
  name: string;
  /** "0–12 tháng". */
  ages: string;
  title: string;
  lead: string;
  chips: [string, string, string];
  /** Chặng 2–4 only (Chặng 1 shows the feature sections instead). */
  highlights: [TitledText, TitledText, TitledText] | null;
  quote: string | null;
}

export interface WatchTile {
  label: string;
  value: string;
  caption: string;
}

export interface MemberText {
  initial: string;
  name: string;
  role: string;
}

export interface RoleText {
  role: string;
  title: string;
  body: string;
}

export interface ShortText {
  text: string;
  short: string;
}

export interface YearText {
  year: string;
  caption: string;
}

export interface TitledText {
  title: string;
  body: string;
}

export interface Article {
  tag: string;
  title: string;
  meta: string;
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
    links: {
      journey: string;
      firstYear: string;
      health: string;
      utilities: string;
      watch: string;
      faq: string;
    };
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
    /** iOS-style push notification header. */
    push: { app: string; now: string };
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
  /** v3 journey: shared by the home page and the four stage pages (14 / 15-landing-v3). */
  journey: {
    /** "Hành trình": switcher label and breadcrumb. */
    label: string;
    /** "Chặng {n}". */
    number: string;
    prevNextLabel: string;
    highlightsTitle: string;
    prev: string;
    next: string;
    backLabel: string;
    backTitle: string;
    /** CTA title of the home and Chặng 2–4 pages. */
    ctaTitle: [string, string];
    stages: [StageText, StageText, StageText, StageText];
  };
  home: {
    hero: {
      eyebrow: string;
      title: [string, string];
      lead: string;
      promises: [string, string, string];
      explore: string;
      art: {
        feed: { title: string; sub: string };
        smile: { title: string; sub: string };
        love: string;
      };
    };
    chapters: {
      eyebrow: string;
      title: string;
      lead: string;
      available: string;
      explore: string;
      view: string;
    };
    firstYear: {
      eyebrow: string;
      title: string;
      lead: string;
      leadShort: string;
      familyTitle: string;
      familyTitleShort: string;
      roles: [RoleText, RoleText, RoleText];
      /** The last chip is desktop only. */
      trust: [ShortText, ShortText, ShortText, ShortText, ShortText];
      nextTitle: string;
      preparing: string;
      more: string;
    };
    growUp: {
      eyebrow: string;
      title: string;
      body: string;
      bodyShort: string;
      years: [YearText, YearText, YearText];
    };
    /** v4 sections (Figma 459:3538, 22-landing-v4-home). Mock strings are illustrative app UI. */
    health: {
      eyebrow: string;
      title: string;
      lead: string;
      bullets: [CompactBullet, CompactBullet, CompactBullet];
      footnote: string;
      mock: {
        title: string;
        columns: [string, string, string, string, string, string];
        rows: [string, string, string, string, string, string];
        next: string;
        growthLabel: string;
        growthValue: string;
        growthChip: string;
      };
    };
    utilities: {
      eyebrow: string;
      title: [string, string];
      lead: string;
      cards: [TitledText, TitledText, TitledText];
      spending: {
        header: string;
        total: string;
        split: [{ label: string; amount: string }, { label: string; amount: string }];
        initials: [string, string];
        together: string;
      };
      members: [MemberText, MemberText, MemberText, MemberText];
    };
    yourWay: {
      eyebrow: string;
      title: string;
      lead: string;
      bullets: [CompactBullet, CompactBullet, CompactBullet];
      mock: {
        title: string;
        rows: [TitledText, TitledText, TitledText];
        chips: [string, string, string, string, string];
        night: string;
      };
    };
    /** v5 "Trên cổ tay" (Figma 475:4503, 25-landing-v5-home). Watch faces are illustrative. */
    watch: {
      eyebrow: string;
      title: [string, string];
      lead: string;
      bullets: [CompactBullet, CompactBullet, CompactBullet, CompactBullet];
      note: string;
      mock: {
        baby: string;
        time: string;
        tiles: [WatchTile, WatchTile, WatchTile, WatchTile, WatchTile, WatchTile];
        breast: {
          title: string;
          left: string;
          leftValue: string;
          right: string;
          rightValue: string;
          total: string;
          switchSide: string;
          stop: string;
        };
        notify: { app: string; title: string; sub: string; log: string; snooze: string };
      };
    };
    faq: { items: FaqItem[] };
  };
  everything: {
    eyebrow: string;
    title: string;
    lead: string;
    leadShort: string;
    tiles: [BentoTile, BentoTile, BentoTile, BentoTile, BentoTile, BentoTile, BentoTile, BentoTile];
    logChips: [string, string];
    notification: { title: string; sub: string };
    familyChip: string;
    weekChips: [string, string];
    milestone: { title: string; sub: string };
    topics: [string, string, string];
    foods: [string, string, string];
    moreFoods: string;
  };
  reminders: {
    eyebrow: string;
    title: string;
    lead: string;
    leadShort: string;
    bullets: [CompactBullet, CompactBullet, CompactBullet];
    notification: {
      title: string;
      sub: string;
      subShort: string;
      log: string;
      snooze: string;
      snoozeShort: string;
      skip: string;
    };
    rule: { title: string; sub: string; next: string };
    fixed: { title: string; times: [string, string, string] };
    done: string;
    doneShort: string;
  };
  understand: {
    eyebrow: string;
    title: string;
    lead: string;
    leadShort: string;
    columns: [TitledText, TitledText, TitledText];
    age: { chips: [string, string]; title: string; points: [string, string]; footer: string };
    wonder: {
      badge: string;
      countdown: string;
      title: string;
      dates: string;
      signsLabel: string;
      signs: [string, string, string];
      learningLabel: string;
      learning: string;
      reminder: string;
    };
    milestone: { chips: [string, string]; title: string; note: string; saved: string };
    note: string;
    noteShort: string;
  };
  library: {
    eyebrow: string;
    title: string;
    lead: string;
    leadShort: string;
    bullets: [CompactBullet, CompactBullet, CompactBullet];
    search: string;
    ageChip: string;
    articles: [Article, Article];
    /** Mobile meta of the first article. */
    articleMetaShort: string;
    solids: {
      label: string;
      meal: string;
      triedLabel: string;
      /** The last one is left out on mobile. */
      foods: [string, string, string, string, string];
      newFood: string;
      more: string;
      moreShort: string;
    };
    saved: string;
  };
  firstAid: {
    eyebrow: string;
    title: string;
    lead: string;
    leadShort: string;
    bullets: [CompactBullet, CompactBullet, CompactBullet];
    card: {
      title: string;
      sub: string;
      topics: [string, string, string, string, string, string];
      step: { label: string; text: string };
    };
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
    items: [FaqItem, FaqItem, FaqItem, FaqItem, FaqItem, FaqItem];
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
