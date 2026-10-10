import { contactEmail } from '../site';
import type { Content } from './types';

/** English — drafted by engineering from the Vietnamese source (D-012); needs owner review (G-081).
 *  Mirrors the PROPOSED replacements in vi.ts. */
export const en: Content = {
  locale: 'en',
  languageName: 'English',
  meta: {
    title: 'Child Life — Care for your baby together, keep every moment',
    description:
      "A free app for the whole family: log feeds, sleep and diapers in one tap, share the care, and keep your baby's photos, videos and stories. On iPhone and Android.",
    ogAlt: 'Child Life — care for your baby together and keep their whole childhood',
  },
  skipToContent: 'Skip to main content',
  nav: {
    homeLabel: 'Child Life — home',
    sectionsLabel: 'Page sections',
    links: {
      care: 'Care',
      understand: 'Week by week',
      memories: 'Memories',
      family: 'Family',
      faq: 'FAQ',
    },
    download: 'Get it free',
    downloadShort: 'Get the app',
    switchLabel: 'Xem trang này bằng tiếng Việt',
    switchShort: 'VI',
  },
  languageSuggestion: {
    text: 'This page is also available in English.',
    action: 'View in English',
    dismiss: 'Dismiss',
  },
  stores: {
    appStore: { prefix: 'Download on the', name: 'App Store' },
    googlePlay: { prefix: 'Get it on', name: 'Google Play' },
    comingSoon: 'Child Life is coming soon to {store}. See you there!',
    close: 'Close',
  },
  mock: {
    baby: 'Teddy',
    babyAge: 'Teddy · 3 weeks',
    date: 'Thursday, 8 October',
    live: {
      app: 'Child Life',
      shared: 'Family can see',
      title: 'Teddy is asleep',
      sub: 'Since 21:42 · started by Dad',
      timer: '1:27:06',
      wake: 'Woke up',
      editStart: 'Edit start time',
    },
    bottleWidget: { label: 'Bottle', ago: '45 min ago', meta: '120 ml · Mum', button: '+ 120 ml' },
    circular: { sleep: '1:27', feed: '45m', sleepLabel: 'Sleep', feedLabel: 'Feed' },
  },
  hero: {
    eyebrow: 'Free for the whole family',
    title: ['Care for your baby together.', 'Keep every moment', 'as they grow.'],
    lead: 'A private space for the whole family: log feeds and sleep in one tap, get reminders at the right time and tips for every week of age — and keep every moment of your baby growing up.',
    caption: 'Free on iPhone and Android.',
    proofInitials: ['M', 'D', 'N', 'G'],
    proof: "Parents, nannies and grandparents — everyone has a place by your baby's side",
    chips: [
      { title: 'Bottle · 120 ml', sub: 'Mum · 2 min ago' },
      { title: "Grandma loved Teddy's photo", sub: 'just now' },
    ],
    today: {
      title: 'Today',
      tiles: {
        bottle: { label: 'Bottle', value: '120 ml', meta: ['45 min ago', 'Logged by Mum'] },
        breast: {
          label: 'Breastfeed',
          value: '15 min',
          meta: ['Ended 3 h 35 min ago', 'Logged by Mum'],
        },
        sleep: { label: 'Sleep', value: 'Awake 2 h', meta: ['Woke at 13:05', 'Logged by Dad'] },
        diaper: { label: 'Diaper', value: 'Wet', meta: ['1 h 25 min ago', 'Logged by Lan'] },
        pump: { label: 'Pumping', value: '90 ml', meta: ['2 h ago', 'Logged by Mum'] },
        growth: { label: 'Growth', value: '4.3 kg', meta: ['54.5 cm', '+0.4 kg · today'] },
      },
      reminder: {
        label: 'Reminders · 3',
        title: '6-in-1 vaccine',
        when: 'Saturday 08:30 · in 2 days',
      },
      section: { title: 'Today', link: 'History' },
    },
    album: {
      title: 'Albums',
      count: '4 albums',
      newAlbum: 'New album',
      albums: [
        { name: 'Favourites', meta: '18 photos · 2 videos', shared: false },
        { name: 'Bath time', meta: '12 photos · 3 videos', shared: true },
        { name: 'Sweet dreams', meta: '28 photos · 1 video', shared: false },
        { name: 'Tiny hands', meta: '9 photos', shared: true },
      ],
      segments: ['Journal', 'Photos', 'Albums', 'Stories'],
      navActive: 'Memories',
      navInitial: 'M',
    },
  },
  quick: {
    eyebrow: 'Hands full',
    title: 'Baby in your arms, logged in one tap.',
    lead: "No need to open the app or remember the time. One tap on your phone's screen and it's done — so you can stay with your baby a little longer.",
    labels: ["Right on your phone's screen", 'Even when your phone is locked'],
    large: {
      status: 'Awake 2 h',
      statusSub: 'Woke at 13:05 · slept 7 h 50 today',
      sleepButton: 'Sleep',
      recentTitle: 'Recent',
      recent: [
        { time: '14:20', label: 'Bottle · 120 ml', who: 'Mum' },
        { time: '13:40', label: 'Diaper · Wet', who: 'Lan' },
        { time: '11:45', label: 'Slept 1 h 20 min', who: 'Dad' },
      ],
      totals: 'Today: 2 bottles 240 ml · 1 breastfeed · 2 diapers',
    },
    tiles: {
      bottle: { label: 'Bottle', value: '45 min' },
      breast: { label: 'Breast', value: '3 h 35' },
      sleep: { label: 'Sleep', value: 'up 2 h' },
      diaper: { label: 'Diaper', value: '1 h 25' },
    },
    mediumMeta: '2 feeds · slept 7 h 50 today',
    logged: { title: 'Just now', meta: 'Logged 120 ml · You', undo: 'Undo', edit: 'Edit' },
    note: "One tap and it's logged",
    steps: [
      { title: 'Tap once', sub: 'Right after a feed' },
      { title: 'Saved for you', sub: 'Tapped by mistake? Fix it right away' },
      { title: 'Everyone sees it', sub: 'Nobody has to ask “has the baby eaten?”' },
    ],
  },
  care: {
    eyebrow: 'Everyday care',
    title: "Understand your baby's day at a glance.",
    lead: 'How much they drank, how long they slept, when the last diaper was — all clear on one screen. Nothing to remember, no guessing, even at 3 a.m.',
    bullets: [
      {
        title: "Your baby's whole day at a glance",
        sub: 'Spot their feeding and sleep rhythm easily',
      },
      { title: 'Timers for sleep and breastfeeding', sub: 'A glance at your phone tells you' },
      { title: "Numbers ready for the doctor's visit" },
    ],
    bottle: { label: 'Bottle', value: '120 ml', meta: ['45 min ago', 'Logged by Mum'] },
    sleep: { label: 'Sleep', value: 'Asleep', meta: ['01:27:06 · since 21:42', 'Started by Dad'] },
    chip: 'Keeps counting with your screen off',
    rhythm: {
      title: 'Logged today',
      totals: [
        ['Bottle', '2 feeds · 240 ml'],
        ['Breastfeed', '1 feed · 15 min'],
        ['Sleep (done)', '7 h 50'],
        ['Diaper', '2 changes'],
      ],
      axis: ['0h', '6h', '12h', '18h', '24h'],
      legend: ['Sleep', 'Bottle', 'Breast', 'Diaper'],
    },
  },
  cocare: {
    eyebrow: 'Care together',
    title: 'The whole family cares, nobody has to ask twice.',
    lead: 'Who fed the baby, who changed the diaper, who rocked them to sleep — everyone sees it. Hand over to each other smoothly, without texting “when did the baby last eat?”.',
    bullets: [
      'Know exactly where the care is up to',
      'Rest easy at work while baby is with grandma or the nanny',
      'Log without a connection, nothing gets lost',
    ],
    initials: { mother: 'M', father: 'D', grandma: 'G', nanny: 'N' },
    chip: 'You choose who sees what',
    feed: {
      title: 'Just logged',
      rows: [
        ['Bottle 120 ml', 'Dad · 13:05'],
        ['Diaper change', 'Nanny · 14:20'],
        ['Slept 1 h 20', 'Mum · 15:40'],
      ],
    },
  },
  memories: {
    eyebrow: 'Memories',
    title: "A home for your baby's whole childhood.",
    lead: "Photos, videos and little stories, arranged by your baby's age, month by month. No more getting lost in thousands of phone photos, no fear of losing them — open it and watch your baby grow.",
    timeline: [
      { age: 'Day one', title: 'Coming home' },
      { age: '5 weeks', title: 'First smile' },
      { age: '4 months', title: 'First roll' },
      { age: '9 months', title: 'First tooth' },
      { age: '1 year', title: 'First birthday' },
      { age: '2 years', title: 'Off and running' },
      { age: '3 years', title: 'First day of school' },
    ],
    timelineEnd: '…and every year after',
    tiles: {
      photos: {
        title: "Your baby's photos, all in one place",
        body: 'No more mixed in with screenshots and receipts. Mark the ones you love most and find them again in seconds.',
        chip: 'Favourites · 48',
      },
      story: {
        title: "Your baby's story",
        body: "From what you've logged, the app suggests a little story. Change a few words so it sounds like you, then send it to family.",
        letter: {
          greeting: 'Dear Teddy,',
          body: 'On Monday morning, Mum had just finished our usual lullaby when you suddenly smiled. We all stood still for a few seconds, afraid a single breath would make it disappear.',
          signature: '— Mum, autumn 2026',
        },
        moment: {
          caption: 'First smile · 5 Oct',
          quote: '“As if you knew the lullaby too.”',
          tag: 'TEDDY · 3 WEEKS OLD',
        },
      },
      family: {
        title: 'Grandparents far away still see them grow',
        body: 'New photos reach grandma and grandpa straight away, and they can send a heart right back. No more forwarding photos one by one.',
        notifications: [
          { initial: 'G', text: "Grandma loved Teddy's photo", when: 'just now' },
          { initial: 'G', text: 'Grandpa loved 3 new photos', when: '5 min ago' },
          { initial: 'A', text: 'Aunt Lan loved the story', when: 'yesterday' },
        ],
      },
    },
  },
  night: {
    eyebrow: 'For wakeful nights',
    title: 'Easy on the eyes for midnight feeds.',
    lead: 'In the evening the screen softens by itself: a warm dark background, large text, no glare. Your baby drifts back to sleep, and so can you.',
    checks: [
      'Turns on at the time you choose, nothing to remember',
      'Big buttons you can tap one-handed while holding your baby',
    ],
    sleepWidget: { label: 'Asleep', sub: 'Since 21:42 · Dad' },
  },
  roles: {
    eyebrow: 'Privacy',
    title: "Your baby's photos, for family only.",
    lead: "Everyone in the family sees just what they need to. You're always the one who decides.",
    allowed: 'Allowed',
    notAllowed: 'Not allowed',
    cards: [
      {
        initial: 'M',
        role: 'Parents',
        description: 'Decide everything',
        permissions: [
          { allowed: true, title: 'Care', sub: "See and log all of the baby's care" },
          { allowed: true, title: 'Memories', sub: 'Keep every photo, video and story' },
          {
            allowed: true,
            title: 'Invite family',
            sub: 'Who to invite and what they see — your call',
          },
        ],
      },
      {
        initial: 'N',
        role: 'Caregivers',
        description: 'Nannies, home helpers',
        permissions: [
          { allowed: true, title: 'Care', sub: "Log the baby's care during the day" },
          { allowed: false, title: 'Memories', sub: "Don't see the baby's photos and memories" },
          { allowed: false, title: 'Invite family', sub: 'No' },
        ],
      },
      {
        initial: 'G',
        role: 'Relatives',
        description: 'Grandparents, aunts and uncles',
        permissions: [
          { allowed: false, title: 'Care', sub: "Don't see daily feeds and sleep" },
          { allowed: true, title: 'Memories', sub: 'See the photos and stories parents share' },
          { allowed: false, title: 'Invite family', sub: 'No' },
        ],
      },
    ],
    notes: [
      'For every new photo you choose who sees it: the whole family or just parents. Change it any time.',
      "Your baby's photos never show on the lock screen, and links you send expire on their own.",
    ],
  },
  cta: {
    title: ['Less to remember.', 'More time with your baby.'],
    sub: 'Free on iPhone and Android. Invite the whole family in a minute.',
    caption: 'Free for the whole family',
  },
  faq: {
    title: 'Frequently asked questions',
    sub: ['Still wondering about something? Just ', 'drop us a line', '.'],
    items: [
      {
        q: 'What age is Child Life for?',
        a: "From the day your baby is born. In the early years the app helps you with everyday care; as they grow, it's where their photos and stories live.",
        open: true,
      },
      {
        q: 'Does it cost anything?',
        a: "No. The whole family uses it for free, with room for thousands of your baby's photos. If you need more space, just message us.",
        open: true,
      },
      {
        q: "Can grandparents who aren't good with phones use it?",
        a: "Yes. Parents send an invite, and grandparents just tap it to see their grandchild's photos and stories. Simple screens, clear text, few buttons.",
        open: false,
      },
      {
        q: "Who can see my baby's photos and information?",
        a: 'Only the people you invite into your family. Parents decide who sees what: caregivers only see the daily care, relatives only see the photos and stories you share.',
        open: false,
      },
      {
        q: 'Does it work on Android?',
        a: 'Yes. Child Life is on both iPhone and Android, so the whole family can care for your baby together whatever phone they use.',
        open: false,
      },
    ],
  },
  footer: {
    copyright: '© 2026 Child Life',
    privacy: 'Privacy',
    terms: 'Terms',
    contact: 'Contact',
    email: contactEmail,
    languageLabel: 'Language',
    linksLabel: 'Footer links',
  },
  legal: {
    privacy: {
      meta: {
        title: 'Privacy — Child Life',
        description:
          "Child Life's privacy policy: how we protect your baby's photos, videos and information.",
      },
      title: 'Privacy',
      status: 'In preparation',
      paragraphs: [
        "Child Life's full privacy policy will be published here before the app launches.",
        "Your baby's photos, videos and information are only for the people you invite into your family. You decide who sees what.",
      ],
      contactLead: 'If you have a question about your data, write to us:',
    },
    terms: {
      meta: {
        title: 'Terms of use — Child Life',
        description: 'Terms of use for the Child Life app.',
      },
      title: 'Terms of use',
      status: 'In preparation',
      paragraphs: [
        'The full Child Life terms of use will be published here before the app launches.',
      ],
      contactLead: 'If you have a question, write to us:',
    },
    back: 'Back to home',
  },
};
