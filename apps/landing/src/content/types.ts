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

export interface StageText {
  name: string;
  /** "0–12 tháng". */
  ages: string;
  title: string;
  lead: string;
}

export interface WatchTile {
  label: string;
  value: string;
  caption: string;
}

export interface DraftText {
  title: string;
  sub: string;
}

export interface DayCard {
  time: string;
  title: string;
  body: string;
}

export interface PlanTier {
  name: string;
  tagline: string;
  credits: string;
  photos: string;
  videos: string;
  /** Monthly and yearly price (the yearly one is shown when the toggle says "Theo năm"). */
  price: string;
  yearPrice: string;
  /** Sub-line under the monthly price, and under the yearly price. */
  sub: string;
  yearSub: string;
  button: string;
}

export interface LumiStage {
  sub: string;
  items: { title: string; body?: string }[];
}

export interface ModeText {
  name: string;
  sub: string;
  example: string;
}

/** One worked example: what the family logged, then what they can do with the card. */
export interface ScenarioText {
  logged: string[];
  decide: string[];
}

/** A "Hôm nay của bé" card in the landing mocks (Figma 699:5798 / 700:5832). */
export interface TodayCardText {
  title: string;
  body: string;
  why: string;
  action: string;
}

export interface TitledSub {
  title: string;
  sub: string;
}

/** One illustration row: title, sub and an optional chip (V9 home). */
export interface MockRow {
  title: string;
  sub: string;
  chip?: string;
}
export type MockRows = [MockRow, MockRow, MockRow];

export interface MemoryStep {
  title: string;
  sub: string;
  tags: string[];
}

export interface Member {
  name: string;
  role: string;
}

export interface SiriLine {
  say: string;
  reply: string;
}

export interface LockNotice {
  title: string;
  when: string;
  body: string;
  bodyShort: string;
}

export interface LumiModule {
  title: string;
  sub: string;
  /** Shown in curly quotes. */
  q: string;
  a: string;
}

export interface FlowStep {
  label: string;
  title: string;
  body: string;
  tags: string[];
}

export interface ToolCard {
  title: string;
  body: string;
  chip: string;
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
    /** V8 (Figma 735:5378): Chăm sóc · Kỷ niệm · Lumi · Năm đầu đời · Hỏi đáp. */
    links: {
      care: string;
      memories: string;
      lumi: string;
      firstYear: string;
      faq: string;
    };
    /** The nav button ("Bắt đầu", to #tai-app). */
    start: string;
    /** The mobile sticky bar's button once the store listings exist. */
    download: string;
    menuOpen: string;
    menuClose: string;
    /** Shown on this page, pointing to the other language. */
    switchLabel: string;
    switchShort: string;
  };
  /** Offered on the other language's page when the browser prefers this language. */
  languageSuggestion: { text: string; action: string; dismiss: string };
  stores: {
    appStore: { prefix: string; name: string };
    googlePlay: { prefix: string; name: string };
    /** Under the badges ("V8/CTA tải app"): after launch, and before it (badges not links). */
    caption: string;
    captionSoon: string;
    close: string;
  };
  /** Kết (home, Năm đầu đời, Chặng 2–4; Figma 735:6497 / 737:8276 / 738:7445). */
  closing: { title: string; sub: string };
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
    proofInitials: [string, string, string, string];
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
  /** "Lumi · suốt hành trình" (Figma 678:5614 / 691:5838): shared by the home and the Lumi page. */
  lumiJourney: {
    planned: string;
    stages: [LumiStage, LumiStage, LumiStage, LumiStage];
  };
  /** The Lumi page (Figma 650:4798, 33-landing-lumi-page). Mock strings are illustrative chat UI. */
  lumiPage: {
    meta: PageMeta;
    hero: {
      eyebrow: string;
      title: [string, string];
      lead: string;
      tryNow: string;
      promises: [string, string, string];
      mock: {
        name: string;
        family: string;
        ask: string;
        reply: string;
        drafts: [DraftText, DraftText, DraftText];
        draft: string;
        saveAll: string;
        ask2: string;
        reply2: string;
        composer: string;
        saved: string;
        expense: DraftText;
        sample: string;
      };
    };
    benefits: {
      eyebrow: string;
      title: string;
      cards: [TitledText, TitledText, TitledText, TitledText];
    };
    /** "Lumi hiểu cả app" (Figma 791:68734): six modules, a sample question and answer each. */
    modules: {
      eyebrow: string;
      title: string;
      lead: string;
      sub: string;
      items: [LumiModule, LumiModule, LumiModule, LumiModule, LumiModule, LumiModule];
      canLabel: string;
      can: [string, string, string, string, string];
    };
    how: {
      eyebrow: string;
      title: string;
      steps: [TitledText, TitledText, TitledText];
      trust: [string, string, string];
    };
    faq: { eyebrow: string; title: string; items: [FaqItem, FaqItem, FaqItem, FaqItem, FaqItem] };
    /** Kết: the download target (#tai-app). The download component stands in for the drawn
     *  "Mở Lumi trong app" pill, which has no web target. */
    cta: { title: string };
  };
  /** "Dành cho con" (home, Figma 699:5798) and "Một ngày dành riêng cho con" (Lumi page,
   *  700:5832): personalised "Hôm nay của bé" cards with the reason each appears. */
  forBaby: {
    mock: {
      initial: string;
      name: string;
      date: string;
      sample: string;
      why: string;
      cards: [TodayCardText, TodayCardText, TodayCardText];
      footnote: string;
    };
  };
  /** V8 home (Figma 735:5377 desktop, 736:65570 mobile; 34-landing-v8-home). */
  homePage: {
    hero: {
      /** Plain head + bold tail in one pill (V9). */
      eyebrow: [string, string];
      title: string;
      lead: string;
      firstYear: string;
      /** Stage chip status: stage 1, stage 2, stages 3–4. */
      now: string;
      next: string;
      later: string;
      feed: { title: string; sub: string };
      learn: { title: string; sub: string };
      video: { title: string; meta: string };
    };
    values: {
      eyebrow: string;
      title: string;
      pillars: [string, string, string];
      cards: [TitledText, TitledText, TitledText];
      /** Three illustration rows per card (V9). */
      rows: [MockRows, MockRows, MockRows];
      button: string;
    };
    people: { mom: string; dad: string; grandma: string; grandpa: string; nanny: string };
    /** 2b "Bắt đầu lúc nào cũng kịp" (Figma 786:8714). */
    restart: {
      eyebrow: string;
      title: string;
      /** Mobile only, as drawn. */
      lead: string;
      head: string;
      ages: [string, string, string, string];
      timeline: [string, string, string];
      sortLabel: string;
      rows: MockRows;
      points: [TitledText, TitledText, TitledText];
      button: string;
    };
    memories: {
      eyebrow: string;
      title: string;
      /** Mobile only (V9). */
      lead: string;
      steps: [MemoryStep, MemoryStep, MemoryStep, MemoryStep, MemoryStep, MemoryStep];
      quote: string;
      firsts: [string, string];
      video: { title: string; body: string; button: string };
      card: { title: string; body: string; bodyShort: string };
      thenNow: { title: string; body: string; bodyShort: string };
      album: { title: string; body: string; initial: string; seen: string };
      button: string;
    };
    family: {
      eyebrow: string;
      title: string;
      bullets: [string, string, string];
      trust: string;
      lock: string;
      members: [Member, Member, Member, Member];
      handover: {
        title: string;
        time: string;
        items: [TitledSub, TitledSub, TitledSub];
        note: string;
        done: string;
      };
    };
    wrist: {
      chip: string;
      title: string;
      lead: string;
      leadShort: string;
      /** Apple Watch, Wear OS, Widget, iOS Controls, Siri. */
      platforms: [string, string, string, string, string];
      apple: string;
      wearLabel: string;
      round: { asleep: string };
      widget: { label: string; baby: string; value: string };
      controls: { label: string; items: [string, string, string] };
      siri: { head: string; lines: [SiriLine, SiriLine, SiriLine] };
    };
    assistant: {
      eyebrow: string;
      title: string;
      lead: string;
      chat: TitledText;
      today: TitledText;
      floats: [string, string, string, string];
      cta: string;
      note: string;
      /** "Thử hỏi Lumi" (Figma 788:8801). */
      ask: {
        title: string;
        sub: string;
        questions: [string, string, string, string];
        foods: [string, string, string, string];
        foodsNote: string;
        activities: [{ title: string; time: string }, { title: string; time: string }];
        days: [string, string, string, string, string, string, string];
        week: [string, string];
        last: { value: string; meta: string; next: string };
      };
    };
    /** 5b "Không bỏ lỡ những khoảnh khắc quan trọng" (Figma 789:8811). */
    alerts: {
      eyebrow: string;
      title: string;
      lead: string;
      leadShort: string;
      modules: [TitledText, TitledText, TitledText, TitledText];
      note: string;
      date: string;
      time: string;
      notices: [LockNotice, LockNotice, LockNotice, LockNotice];
      more: string;
    };
    tools: {
      eyebrow: string;
      title: string;
      cards: [ToolCard, ToolCard, ToolCard, ToolCard, ToolCard, ToolCard, ToolCard, ToolCard];
      button: string;
    };
    journey: {
      eyebrow: string;
      title: string;
      lead: string;
      now: string;
      soon: string;
      more: string;
      bodies: [string, string, string, string];
    };
    trust: {
      eyebrow: string;
      title: string;
      points: [string, string, string, string];
      faq: FaqItem[];
    };
  };
  /** V8 "Năm đầu đời" page at the Chặng 1 path (Figma 737:6362; 35-landing-v8-first-year). */
  firstYearPage: {
    meta: PageMeta;
    hero: { badge: string; title: string; lead: string };
    jump: { label: string; navLabel: string };
    groups: [TitledSub, TitledSub, TitledSub, TitledSub, TitledSub];
    vaccines: {
      eyebrow: string;
      title: string;
      lead: string;
      bullets: [TitledSub, TitledSub, TitledSub];
      note: string;
      mock: {
        title: string;
        columns: [string, string, string, string, string, string];
        rows: [string, string, string, string, string, string];
        done: string;
        due: string;
        next: string;
        growth: { label: string; value: string; chip: string };
      };
    };
  };
  /** V8 future-stage template, Chặng 2–4 (Figma 738:7309; 36-landing-v8-lumi-and-stages B). */
  stagePage: {
    band: string;
    status: string;
    available: string;
    /** `{ages}` is the stage's age range. */
    lead: string;
    useFirstYear: string;
    eyebrow: string;
    /** Section title per stage 2, 3, 4. */
    titles: [string, string, string];
    note: string;
  };
  /** v3 journey: shared by the home page and the four stage pages (14 / 15-landing-v3). */
  journey: {
    /** "Hành trình": switcher label and breadcrumb. */
    label: string;
    /** "Chặng {n}". */
    number: string;
    prevNextLabel: string;
    stages: [StageText, StageText, StageText, StageText];
  };
  home: {
    /** Lumi block in the Chặng 1 frame (Figma 649:7270, 32-landing-v6-home §4). Mock strings are
     *  illustrative chat UI. */
    lumi: {
      mock: {
        logAsk: string;
        drafts: [{ title: string; sub: string }, { title: string; sub: string }];
        draft: string;
        dataAsk: string;
        dataAnswer: string;
        dataSource: string;
        sleepAsk: string;
        sleepAnswer: string;
        sleepSources: [string, string];
        mealAsk: string;
        mealAnswer: string;
        meals: [string, string];
        receipt: { title: string; sub: string; note: string; amount: string };
        video: string;
      };
    };
    /** "Kỷ niệm của con" (Figma 517:56217, §5.2). Mock strings are illustrative. */
    keepsakes: {
      mock: {
        video: {
          template: string;
          caption: string;
          time: string;
          music: string;
          milestones: string;
        };
        card: { title: string; sub: string; options: [string, string, string]; save: string };
        journal: {
          initial: string;
          name: string;
          time: string;
          text: string;
          duration: string;
          saved: string;
        };
        thenNow: { then: string; now: string; video: string; collage: string };
        voice: {
          initial: string;
          length: string;
          from: string;
          textInitial: string;
          textName: string;
          text: string;
          privacy: string;
        };
        book: {
          cover: [string, string];
          month: string;
          caption: string;
          pdf: string;
          print: string;
        };
      };
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
    /** V9 5-step flow (Figma 785:9495). `{n}` is the step number. */
    stepChip: string;
    steps: [FlowStep, FlowStep, FlowStep, FlowStep, FlowStep];
    found: { title: string; sub: string; saveAll: string; pick: string };
    views: [string, string, string];
    clip: string;
    card: { title: string; meta: string };
    share: { label: string; targets: [string, string, string, string] };
    tiles: {
      photos: { chip: string };
      story: {
        letter: { greeting: string; body: string; signature: string };
        moment: { caption: string; quote: string; tag: string };
      };
      family: {
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
