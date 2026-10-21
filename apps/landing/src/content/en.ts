import { contactEmail } from '../site';
import type { Content } from './types';

/** English — drafted by engineering from the Vietnamese source (D-012); needs owner review (G-081).
 *  Mirrors the PROPOSED replacements in vi.ts. */
export const en: Content = {
  locale: 'en',
  languageName: 'English',
  meta: {
    title: 'Child Life — Grow up together, one step at a time',
    description:
      'A free app that helps the whole family care for your child, understand them week by week and keep their journey of growing up — starting with the first year. On iPhone and Android.',
    ogAlt: 'Child Life — grow up together, one step at a time',
  },
  skipToContent: 'Skip to main content',
  nav: {
    homeLabel: 'Child Life — home',
    sectionsLabel: 'Page sections',
    links: {
      care: 'Care',
      memories: 'Memories',
      lumi: 'Lumi',
      firstYear: 'First year',
      faq: 'FAQ',
    },
    start: 'Get started',
    download: 'Get it free',
    menuOpen: 'Open menu',
    menuClose: 'Close menu',
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
    caption: 'Free on iPhone and Android.',
    captionSoon: 'Coming soon to iPhone and Android.',
    close: 'Close',
  },
  closing: {
    title: "Start with your baby's first year.",
    sub: 'Logs, reminders and memories — the whole family in one place.',
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
    push: { app: 'CHILD LIFE', now: 'now' },
  },
  hero: {
    proofInitials: ['M', 'D', 'N', 'G'],
  },
  quick: {
    eyebrow: 'Hands full',
    title: 'Log fast from widgets and the lock screen.',
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
  // Lumi page (Figma 650:4798): engineering drafts for owner review (D-012). Q-039: the plans are
  // not the app's single Premium plan (33-landing-lumi-page §16); FAQ answers 2–6 are PROPOSED.
  lumiPage: {
    meta: {
      title: "Lumi — your family's assistant in Child Life",
      description:
        "Lumi reads your child's logs, milestones, meals and reminders in Child Life — logs from one message and answers for your child. You review before anything is saved.",
    },
    hero: {
      eyebrow: 'Lumi · The helper inside Child Life',
      title: ['Lumi understands', "your child's whole journey."],
      lead: 'Lumi reads the logs, milestones, meals, memories and reminders in Child Life — to log for you, answer and suggest what fits your child. Free for every family.',
      tryNow: 'Open Lumi in the app',
      promises: [
        "You confirm before it's saved",
        "Answers from your child's logs",
        'The family uses it by role',
      ],
      mock: {
        name: 'Lumi',
        family: "Teddy's family assistant",
        ask: 'Fed 120 ml at 9, asleep from 9:30, nappy at 10',
        reply: 'I drafted 3 logs — check them, then save:',
        drafts: [
          { title: 'Bottle · 120 ml', sub: '9:00' },
          { title: 'Sleep', sub: 'from 9:30' },
          { title: 'Nappy', sub: '10:00' },
        ],
        draft: 'Draft',
        saveAll: 'Save all 3',
        ask2: 'Bedtime has been hard these past few days',
        reply2:
          'On 2 of the last 3 evenings you noted “hard to settle”, both after 9 pm. Want to look at the sleeps around then?',
        composer: 'Tell, ask or send Lumi a photo…',
        saved: '3 logs saved',
        expense: { title: 'Nappies · 289,000 ₫', sub: 'From a receipt photo → Spending' },
        sample: 'Sample conversation',
      },
    },
    benefits: {
      eyebrow: 'What Lumi does for your family',
      title: 'Less to remember, more time with your child.',
      cards: [
        {
          title: 'Quick when your hands are full',
          body: 'One sentence instead of many taps. Lumi splits it into the right logs.',
        },
        {
          title: 'Understand your child from your own logs',
          body: 'Lumi answers from what your family has logged, with the source to open.',
        },
        {
          title: 'One small thing for today',
          body: "Ideas that fit your child's age and what you've logged — you pick what suits you.",
        },
        {
          title: 'Keep every moment',
          body: 'Turn photos on your phone into cards and short films for the first milestones.',
        },
      ],
    },
    modules: {
      eyebrow: 'One assistant that knows every part of the app',
      title: 'Ask anything about your child.',
      lead: 'Lumi connects everything about your child, so its answers fit your child — never generic.',
      sub: 'Reads from 6 parts of Child Life',
      items: [
        {
          title: 'Care',
          sub: 'Feeds, sleep, nappies',
          q: 'How much did baby drink today?',
          a: '6 feeds · 720 ml',
        },
        {
          title: 'Development',
          sub: 'Milestones & ideas by age',
          q: 'What can an 8-month-old usually do?',
          a: 'Crawling, sitting steady · 3 milestones',
        },
        {
          title: 'Nutrition',
          sub: 'Solids & recipes',
          q: 'What can a 6-month-old eat?',
          a: 'Smooth porridge, pumpkin, banana',
        },
        {
          title: 'Memories',
          sub: 'Photos, cards, videos',
          q: "Find baby's first smile",
          a: 'Found 3 photos · 5 weeks',
        },
        {
          title: 'Family',
          sub: 'Caregivers & handovers',
          q: 'Who looked after baby today?',
          a: 'Dad logged 4 times · Grandma 2',
        },
        {
          title: 'Reminders',
          sub: 'Vaccines & reminders',
          q: 'When is the next vaccine?',
          a: '6-in-1 · next Monday',
        },
      ],
      canLabel: 'Lumi can:',
      can: [
        'Log from one message',
        'Answer from your logs',
        'Weekly summary',
        'Find photos',
        'Ideas by age',
      ],
    },
    how: {
      eyebrow: 'How Lumi works',
      title: 'Lumi drafts. You decide.',
      steps: [
        { title: 'Tell, ask or snap', body: 'Type like a message, or send a receipt or a note.' },
        {
          title: 'Lumi drafts',
          body: 'Puts each thing in the right place and asks about anything missing or unclear.',
        },
        {
          title: 'You review and save',
          body: 'Edit, drop or save each one. Lumi never saves on its own.',
        },
      ],
      trust: [
        'Only your family, with the access you give',
        'Photos sent to Lumi are only read for their content; you choose whether to keep the original',
        "Lumi is not a doctor and does not diagnose. When you're worried about health, Lumi points you to safety guidance and the emergency number",
      ],
    },
    faq: {
      eyebrow: 'FAQ',
      title: 'What parents often ask about Lumi.',
      items: [
        {
          q: 'Does Lumi write to the log by itself?',
          a: 'No. Lumi drafts, you review and tap save. You can edit or drop each one.',
          open: true,
        },
        {
          q: 'What does Lumi base its answers on?',
          a: "On what your family has logged in Child Life — feeds, sleep, nappies, growth, milestones, solids, vaccines and reminders — plus reference content for your child's age. Each answer links back to that part of the app.",
          open: false,
        },
        {
          q: 'Does Lumi replace a doctor?',
          a: "No. Lumi does not diagnose. When you're worried about your child's health, Lumi points you to safety guidance and the emergency number; contact a doctor or clinic when needed.",
          open: false,
        },
        {
          q: 'Does Lumi cost anything?',
          a: "Every family can use Lumi for free. Everyday logging and quick looks at your logs don't use credits; tasks that need more thinking, like reading a receipt photo, have a monthly limit.",
          open: false,
        },
        {
          q: "How is my child's information used?",
          a: 'Lumi only reads what you send and the logs you are allowed to see, to answer and draft. You agree before using it and can turn it off at any time.',
          open: false,
        },
      ],
    },
    cta: {
      title: 'Let Lumi handle the note-taking. You spend the time with your child.',
    },
  },
  // V8 home (Figma 735:5377 / 736:65570): engineering drafts for owner review (D-012).
  homePage: {
    hero: {
      eyebrow: ['Child Life · ', 'Growing up together'],
      title: 'Grow with your child, moment by moment.',
      lead: 'From daily care and tracking development to keeping memories — Child Life brings the whole family together as your child grows.',
      firstYear: "Start with your baby's first year",
      now: 'In the app now',
      next: 'Next stage',
      later: 'In the future',
      feed: { title: 'Bottle · 120 ml', sub: 'Dad logged it · 2 min ago' },
      learn: { title: 'Learning', sub: 'How did they learn today?' },
      video: { title: "Teddy's one-month video", meta: '0:45 · from photos you picked' },
    },
    values: {
      eyebrow: "How Child Life helps in your baby's first year",
      title: 'Child Life helps your family with three things.',
      pillars: ['Care', 'Development', 'Memories'],
      cards: [
        {
          title: 'Daily care',
          body: 'Log feeds, sleep and diapers; get reminders for care, nutrition and solids. Everyone knows how the baby was just cared for.',
        },
        {
          title: 'Understand each stage',
          body: "Track milestones, get tips for your baby's age and keep a journal of them growing up.",
        },
        {
          title: 'Keep what matters',
          body: "Finds your baby's photos for you, makes cards and videos, and keeps them in a private family album.",
        },
      ],
      rows: [
        [
          { title: 'Feeds · sleep · diapers', sub: 'One-tap logging' },
          { title: 'Care reminders', sub: 'Lunch solids · 11:30', chip: 'Nutrition' },
          { title: 'Caring together', sub: 'Dad just logged a feed · 2 min' },
        ],
        [
          { title: 'Milestones', sub: 'Rolls over · 4 months', chip: '✓ Logged' },
          { title: 'Tips for their age', sub: '10 minutes of tummy time', chip: '4 months' },
          { title: 'Growing-up journal', sub: 'Week 18 · 6 entries' },
        ],
        [
          { title: "Finds your baby's photos", sub: '8 new photos waiting to be saved' },
          { title: 'Memory cards & videos', sub: '6 months old', chip: 'Make one' },
          { title: 'Private family album', sub: 'Invited people only' },
        ],
      ],
      button: 'See every feature for the first year',
    },
    people: { mom: 'M', dad: 'D', grandma: 'G', grandpa: 'G', nanny: 'N' },
    restart: {
      eyebrow: 'Whether your baby is 2 months or 6',
      title: "It's never too late to start.",
      lead: 'Even if your baby is already a few months old, Child Life helps with care, helps you understand them and keeps every moment — including the days already gone.',
      head: 'Teddy started Child Life at…',
      ages: ['Newborn', '2 months', '6 months', '9 months'],
      timeline: ['Birth', 'Today · 6 months', '1 year'],
      sortLabel: 'Child Life sorts it out for you',
      rows: [
        {
          title: 'Found 214 photos since birth',
          sub: 'Sorted by month · waiting for you to choose',
        },
        {
          title: 'Past milestones: rolling over, laughing out loud',
          sub: 'Tick them off if your baby already does them',
          chip: '3 milestones',
        },
        {
          title: 'Tips & reminders for 6 months',
          sub: 'Solids, sleep, next vaccines',
          chip: 'From today',
        },
      ],
      points: [
        {
          title: 'Care support from today',
          body: "Enter your baby's age and reminders, solids tips and the care schedule match their current stage.",
        },
        {
          title: "Understand the stage they're in",
          body: 'See where your baby is in their development and which milestones come next.',
        },
        {
          title: 'Keep the days already gone',
          body: 'Older photos on your phone are found and sorted by month, so no page of the album is missing.',
        },
      ],
      button: "Start with your baby's age",
    },
    memories: {
      eyebrow: 'Memories',
      title: "Today's photos, kept as memories to look back on.",
      lead: "Child Life finds your baby's photos, helps you pick and save them, makes cards and videos, then keeps them in a private album for the whole family.",
      steps: [
        { title: 'Finds photos', sub: "Your baby's new photos", tags: ['Automatic'] },
        { title: 'Pick & save', sub: 'Keep the best, drop duplicates', tags: ['One tap'] },
        { title: 'Cards & videos', sub: 'From ready-made templates', tags: ['Cards', 'Video'] },
        {
          title: 'Album & sharing',
          sub: 'Just for family, or share outside',
          tags: ['Family', 'Link'],
        },
        { title: 'Stories & journal', sub: 'Write their story down', tags: ['Journal'] },
        { title: 'Milestones', sub: "Your baby's firsts", tags: ['Milestones'] },
      ],
      quote: '“Today you laughed out loud for the first time…”',
      firsts: ['★ Rolls over', '★ First tooth'],
      video: {
        title: 'Memory videos',
        body: 'Pick photos and a template and get a video for one month, 100 days or the first birthday to share with the family.',
        button: 'Watch a sample',
      },
      card: {
        title: 'Milestone cards',
        body: 'One month, 100 days, first roll-over — pick a template and photos and send it to the grandparents.',
        bodyShort: 'Pick a template and photos, send it to the grandparents.',
      },
      thenNow: {
        title: 'Then & now',
        body: 'Put two photos side by side to see how much your baby has grown.',
        bodyShort: "Two photos, and you see how they've grown.",
      },
      album: {
        title: 'Private family album',
        body: 'The whole family can view and comment. Share outside with a link when you want.',
        initial: 'G',
        seen: 'Grandma loved 3 new photos',
      },
      button: 'See memory templates',
    },
    family: {
      eyebrow: 'Caring together',
      title: 'Dad logs it, Mom sees it. No one has to ask again.',
      bullets: [
        'Parents, grandparents and caregivers on one journey.',
        'Shift handovers: everyone knows what the baby just ate, how they slept and what comes next.',
        'Everyone has their own access: some log care, some only see photos.',
      ],
      trust: "You choose who sees your baby's photos and details.",
      lock: 'Only people you invite can see this',
      members: [
        { name: 'Dad', role: 'Logs & sees everything' },
        { name: 'Mom', role: 'Manages the family' },
        { name: 'Grandparents', role: 'See photos, comment' },
        { name: 'Nanny', role: 'Logs feeds, sleep, diapers' },
      ],
      handover: {
        title: 'Shift handover · Mom → Nanny',
        time: '13:55',
        items: [
          { title: 'Fed 120 ml', sub: 'at 13:00' },
          { title: 'Asleep', sub: 'since 13:30' },
          { title: 'Next reminder', sub: 'Vitamin D 15:00' },
        ],
        note: '“A bit fussy this afternoon, remember to burp after feeds.” — Mom',
        done: 'Nanny accepted the handover',
      },
    },
    wrist: {
      chip: 'On your wrist',
      title: 'Holding your baby? Log it without opening the app.',
      lead: 'One tap on your watch, a Home Screen widget or an iOS control — or just ask Siri. The family sees it on their phones right away.',
      leadShort: 'One tap on your watch, a widget or an iOS control — or ask Siri.',
      platforms: ['Apple Watch', 'Wear OS · Coming soon', 'Widgets', 'iOS Controls', 'Siri'],
      apple: 'Apple Watch',
      wearLabel: 'Wear OS',
      round: { asleep: 'Asleep' },
      widget: { label: 'WIDGET', baby: 'Teddy · last feed', value: '2 h 15 m ago' },
      controls: { label: 'iOS CONTROLS', items: ['Feed', 'Sleep', 'Diaper'] },
      siri: {
        head: 'Hey Siri…',
        lines: [
          { say: '“Lumi, log a 120 ml feed.”', reply: 'Logged a 120 ml bottle at 9:00.' },
          { say: "“When was Teddy's last feed?”", reply: '2 h 15 m ago, a 120 ml bottle.' },
          { say: "“Start Teddy's sleep.”", reply: 'Timing sleep since 9:30.' },
        ],
      },
    },
    assistant: {
      eyebrow: 'Lumi · The assistant in Child Life',
      title: 'Send one message, Lumi does the logging.',
      lead: "Lumi drafts entries from your messages and answers from your baby's journal. When you open the app, you also see suggestions based on what you've logged.",
      chat: {
        title: 'You message, Lumi logs',
        body: 'One sentence becomes several entries. Ask, and the answer comes from the journal.',
      },
      today: {
        title: 'Open the app, and what you need is already there',
        body: "Suggestions come with a reason — based on what you've logged.",
      },
      floats: [
        '3 entries saved',
        'You confirm before saving',
        'A reason for every suggestion',
        'Hide or change them any time',
      ],
      cta: 'Discover Lumi',
      note: 'Illustrative example. Lumi takes text and photos; you check and tap save.',
      ask: {
        title: 'Try asking Lumi',
        sub: "· Lumi knows your baby's journal, milestones and memories",
        questions: [
          'What can a 6-month-old eat?',
          'Suggest activities for today',
          "Summarise this week's journal",
          'When was the last feed?',
        ],
        foods: ['Smooth rice porridge', 'Mashed pumpkin', 'Banana', 'Sweet potato'],
        foodsNote: 'Try one new food every 3 days.',
        activities: [
          { title: 'Tummy time', time: '10 min' },
          { title: 'Picture books', time: '5 min' },
        ],
        days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        week: ['Avg sleep 13 h', '42 feeds'],
        last: {
          value: '2 h 15 m',
          meta: 'ago · 120 ml bottle · logged by Dad',
          next: 'Next feed around 11:30',
        },
      },
    },
    alerts: {
      eyebrow: 'Reminders & personalisation',
      title: 'Never miss the moments that matter.',
      lead: "Child Life reminds you at the right time, based on your baby's age and routine — from feeds and milestones to new foods and photos you haven't saved yet.",
      leadShort:
        "Timely reminders based on your baby's age and routine — feeds, milestones, new foods and unsaved photos.",
      modules: [
        { title: 'Care', body: 'Feeds, sleep, vaccines' },
        { title: 'Development', body: 'Upcoming milestones, play ideas for their age' },
        { title: 'Nutrition', body: 'New foods, solids schedule' },
        { title: 'Memories', body: 'Photos to save, monthly milestones, birthdays' },
      ],
      note: "You choose what you get and when. Nothing is sent during your baby's sleep time.",
      date: 'Saturday, 18 January',
      time: '9:41',
      notices: [
        {
          title: '8 new photos of your baby',
          when: 'now',
          body: "Waiting to be saved — let's keep these moments.",
          bodyShort: "Let's keep these moments.",
        },
        {
          title: 'Teddy is one today!',
          when: '8:00',
          body: "Make a birthday card from the whole year's photos.",
          bodyShort: "Make a birthday card from the whole year's photos.",
        },
        {
          title: 'Milestone coming up: standing alone',
          when: 'yesterday',
          body: '11 months — 3 games to help them practise standing.',
          bodyShort: '3 games to help them practise standing.',
        },
        {
          title: 'Lunch idea',
          when: 'yesterday',
          body: 'Pumpkin and chicken porridge suits your baby right now.',
          bodyShort: 'Pumpkin and chicken porridge suits your baby right now.',
        },
      ],
      more: '+2 care reminders',
    },
    tools: {
      eyebrow: 'Tools',
      title: 'And small tools for every day.',
      cards: [
        {
          title: 'Feed & sleep reminders',
          body: 'On-time reminders for whoever is caring.',
          chip: 'Next feed · 11:30',
        },
        { title: 'Milestones', body: 'Mark and keep the firsts.', chip: 'Rolls over ✓' },
        {
          title: "Tips for your baby's age",
          body: "Each week, what's common at your baby's age.",
          chip: 'Week 16',
        },
        {
          title: 'Baby care & solids library',
          body: 'Short reads and recipes for each stage.',
          chip: 'Pumpkin congee',
        },
        {
          title: 'First aid for children',
          body: "Step-by-step help when it's urgent.",
          chip: 'Choking',
        },
        {
          title: 'Baby expenses',
          body: "Parents see together what's been spent on the baby.",
          chip: '289,000 ₫',
        },
        {
          title: 'Customise & night mode',
          body: 'Show only what you need; easy on the eyes at night.',
          chip: 'Night mode',
        },
        { title: 'Apple Watch', body: 'Quick logging right on your watch.', chip: 'One-tap log' },
      ],
      button: 'See everything in First year',
    },
    journey: {
      eyebrow: 'Journey',
      title: 'Your child grows, and the journey goes on.',
      lead: 'Today Child Life is for the first year. The next stages are being built together with families.',
      now: 'In the app now',
      soon: 'In development',
      more: 'Learn more',
      bodies: [
        "Care for and understand your baby, and keep the first year's memories.",
        'Play, first words and first habits.',
        "“Why?” questions, drawings and your child's own stories.",
        "Hobbies, small projects and your child's own plans.",
      ],
    },
    trust: {
      eyebrow: 'Free & trusted',
      title: 'Start for free. Your family stays in control.',
      points: [
        'Logging, reminders, milestones and basic memories are free.',
        'Lumi comes with a limited number of free uses each month.',
        'Need more? You can move to a bigger Lumi plan at any time.',
        "Your family chooses who sees your baby's photos and details.",
      ],
      faq: [
        {
          q: 'What age is the app for right now?',
          a: 'For now Child Life focuses on the first year, from birth to 12 months. The later stages are in development.',
          open: true,
        },
        {
          q: 'Does it cost anything?',
          a: 'Logging, reminders, milestones and basic memories are free for the whole family. Lumi has free uses every month; upgrade if you need more.',
          open: false,
        },
        {
          q: 'How do grandparents and caregivers use it?',
          a: 'Parents invite grandparents, relatives or a caregiver to the family. Caregivers log and see the daily care; grandparents and relatives see the photos and stories parents share.',
          open: false,
        },
        {
          q: "Who can see my baby's photos and details?",
          a: 'Only the people you invite into your family. Parents decide who sees what: caregivers only see the daily care, relatives only see the photos and stories you share.',
          open: false,
        },
        {
          q: 'What happens when I run out of Lumi uses?',
          a: 'You can still log directly and view your logs as usual; essential health guidance stays open. Credits refresh at the start of the next period.',
          open: false,
        },
      ],
    },
  },
  firstYearPage: {
    meta: {
      title: "Your baby's first year — Child Life",
      description:
        "Logs and reminders for the whole family, age-based tips, first aid, starting solids and a home for your baby's memories — ready to use today.",
    },
    hero: {
      badge: 'In the app now',
      title: "Your baby's first year, all in one app.",
      lead: "Logs and reminders for the whole family, age-based tips, first aid, starting solids and a home for your baby's memories — ready to use today.",
    },
    jump: { label: 'Jump to:', navLabel: 'Jump to a section' },
    groups: [
      { title: 'Log & remind', sub: 'Log in a few taps, reminded right on time.' },
      { title: 'Caring together', sub: 'Parents, grandparents and caregivers share one log.' },
      {
        title: 'Know your baby by age',
        sub: "Milestones, vaccinations, reading and first aid for your baby's age.",
      },
      { title: 'Memories', sub: "Keep your baby's firsts." },
      { title: 'Tools', sub: 'Night mode, a home screen your way and Apple Watch.' },
    ],
    vaccines: {
      eyebrow: "Your baby's health",
      title: 'Vaccinations and growth charts.',
      lead: "Know which shots your baby has had, what's next and how they're growing — no digging through the health book.",
      bullets: [
        {
          title: 'Vaccinations by age',
          sub: 'Tick off each dose and get a reminder before the next one, for the whole family.',
        },
        {
          title: 'Weight and length against WHO standards',
          sub: 'Easy-to-read charts that never score or compare your baby.',
        },
        {
          title: 'Nutrition by stage',
          sub: 'Reference milk amounts and the nutrients to watch at each age.',
        },
      ],
      note: "For reference, reviewed by experts. Follow your clinic for your baby's exact vaccination schedule.",
      mock: {
        title: 'Vaccinations · Teddy',
        columns: ['Birth', '2 mo', '3 mo', '4 mo', '6 mo', '9 mo'],
        rows: ['Hepatitis B', 'BCG', '6-in-1', 'Pneumococcal', 'Rotavirus', 'Measles'],
        done: 'Given',
        due: 'Coming up',
        next: 'Next dose: 6-in-1 · dose 3 · 17 Nov',
        growth: { label: 'Weight', value: '7.8 kg', chip: 'Within the WHO range' },
      },
    },
  },
  stagePage: {
    band: "In development — this stage isn't in the app yet. Child Life is currently for the first year (0–12 months).",
    status: 'In development',
    available: 'In the app now',
    lead: 'This is the direction for the {ages} stage; scope and timing will be updated.',
    useFirstYear: 'Use Child Life for the first year',
    eyebrow: "What we're preparing",
    titles: [
      'Three experiences for the toddler years.',
      'Three experiences for ages 3–6.',
      'Three experiences for ages 6–12.',
    ],
    note: 'The experiences above are directions in development and are not in the app yet.',
  },
  lumiJourney: {
    planned: 'In the works',
    stages: [
      {
        sub: 'Gentler for the whole family.',
        items: [
          { title: 'Say it once, logged in the right place.' },
          { title: "Ask about your baby's log." },
          { title: "Today's weaning ideas." },
        ],
      },
      {
        sub: 'Less wondering what to play, more things to try together.',
        items: [
          {
            title: 'What shall we play today?',
            body: "Short activity ideas for their age, the interests you've noted and what you have at home.",
          },
          {
            title: 'Every first word, never forgotten.',
            body: 'Gather the funny sayings, the laughter and the small steps into their journal.',
          },
          {
            title: 'Small habits, built together.',
            body: 'Simple steps for bedtime, brushing teeth or tidying toys, the way your family chooses.',
          },
        ],
      },
      {
        sub: 'More ideas for endless questions.',
        items: [
          {
            title: '“Why?” becomes playtime.',
            body: 'Turn what they wonder about into a story, a game or an activity to explore together.',
          },
          {
            title: 'Their day, easier to talk about.',
            body: 'From a few of your notes, questions to chat with them about their day at school.',
          },
          {
            title: 'Little drawings, big stories.',
            body: 'Keep their artwork with their own words, then gather it into a collection year by year.',
          },
        ],
      },
      {
        sub: 'Closer by their side, with room to grow on their own.',
        items: [
          {
            title: 'Their ideas get a place to start.',
            body: 'Break a small project into doable steps — planting, model making or writing a story.',
          },
          {
            title: 'Plans they help choose.',
            body: 'Plan school, chores and time for hobbies; you adjust them together.',
          },
          {
            title: 'A year through their eyes.',
            body: 'Gather their achievements, stories and proud moments into a keepsake in their own voice.',
          },
        ],
      },
    ],
  },
  // "Made for your child" (Figma 699:5798, home) and "A day made for your child" (700:5832, Lumi
  // page): engineering drafts for owner review (D-012). Q-039: meal ideas await expert review.
  forBaby: {
    mock: {
      initial: 'T',
      name: "Teddy's today",
      date: 'Thursday · 3 things worth a look',
      sample: 'Sample',
      why: 'Why you see this card',
      cards: [
        {
          title: 'Look back at sleep',
          body: 'On the last 2 evenings your child was hard to settle, both after 9 pm.',
          why: 'You logged “hard to settle” on the last 2 days.',
          action: 'See related logs',
        },
        {
          title: 'Ideas for the next meal',
          body: 'Pumpkin oat congee · Mashed sweet potato',
          why: "Based on age, foods tried and the reactions you've logged.",
          action: 'See dishes and ingredients',
        },
        {
          title: 'Keep the first smile',
          body: 'The 3 photos you picked yesterday are ready.',
          why: 'You just marked the “smiles back” milestone.',
          action: 'Make a card from the photos',
        },
      ],
      footnote: 'You choose which topics show here, and hide or edit them any time.',
    },
  },
  journey: {
    label: 'Journey',
    number: 'Stage {n}',
    prevNextLabel: 'Stages',
    stages: [
      {
        name: 'The very first days',
        ages: '0–12 months',
        title: 'The very first days.',
        lead: "Getting to know each other one feed and one nap at a time — and keeping your child's firsts.",
      },
      {
        name: 'Exploring the world',
        ages: '1–3 years',
        title: 'Exploring the world.',
        lead: 'Toddling, first words and small new habits, together.',
      },
      {
        name: 'Curious and growing',
        ages: '3–6 years',
        title: 'Curious and growing.',
        lead: 'Playing, reading, drawing and answering an endless stream of “why?”.',
      },
      {
        name: 'A world of their own',
        ages: '6–12 years',
        title: 'A world of their own.',
        lead: 'Gently by their side as they grow independent, with interests and dreams of their own.',
      },
    ],
  },
  home: {
    lumi: {
      mock: {
        logAsk: 'Baby had 120 ml at 9, asleep from 9:30',
        drafts: [
          { title: 'Bottle · 120 ml', sub: '9:00' },
          { title: 'Sleep', sub: 'from 9:30' },
        ],
        draft: 'Draft',
        dataAsk: 'How did baby feed today?',
        dataAnswer: '5 bottle feeds · 580 ml in total. Last one at 14:20.',
        dataSource: 'Open the source log',
        sleepAsk: 'Baby has trouble falling asleep lately',
        sleepAnswer:
          '2 of the last 3 evenings had a hard time settling, both after 21:00. Look at the sleeps around them?',
        sleepSources: ['6 sleeps', '2 notes'],
        mealAsk: 'What can Teddy eat today?',
        mealAnswer: 'Ideas for 7 months, without egg since you noted a rash:',
        meals: ['Pumpkin porridge', 'Mashed sweet potato'],
        receipt: {
          title: 'Diapers · 289,000 ₫',
          sub: 'Expense · today',
          note: 'The date on the receipt is blurry — Lumi asks before saving.',
          amount: '289,000 ₫',
        },
        video: "Teddy's first month · 0:45",
      },
    },
    keepsakes: {
      mock: {
        video: {
          template: 'Template · First year',
          caption: 'First roll-over · 4 months',
          time: '0:16 / 0:45',
          music: 'Music: Gentle lullaby',
          milestones: '3 milestones',
        },
        card: {
          title: '100 days',
          sub: 'Teddy · 18.01.2027',
          options: ['1 month', '100 days', 'First roll-over'],
          save: 'Save PNG',
        },
        journal: {
          initial: 'M',
          name: 'Mum',
          time: '12/10 · 21:30',
          text: 'Today you watched me all morning and giggled when I sang.',
          duration: '0:18',
          saved: 'Saved to the memory timeline',
        },
        thenNow: {
          then: '1 month',
          now: '12 months',
          video: 'Make a transition video',
          collage: 'Save collage',
        },
        voice: {
          initial: 'G',
          length: '0:32',
          from: 'Grandma · voice message',
          textInitial: 'D',
          textName: 'Dad',
          text: '“My boy, every day with you is a happy day.”',
          privacy: 'Only family can listen',
        },
        book: {
          cover: ['First year', 'of Teddy'],
          month: 'Month 6',
          caption: 'First solid meal',
          pdf: 'PDF · 48 pages',
          print: 'Order a photo book',
        },
      },
    },
    watch: {
      eyebrow: 'Apple Watch',
      title: ['Baby in your arms,', 'every feed still logged.'],
      lead: 'Log feeds, sleep and diapers right on your watch with one tap — no need to find your phone.',
      bullets: [
        {
          title: 'Log with one tap',
          sub: 'Turn the crown to pick the bottle amount; wet or dirty diaper in one tap.',
          subShort: 'Turn the crown for ml; diapers in one tap.',
        },
        {
          title: 'Time breastfeeds, sleep and pumping',
          sub: 'Switch sides or stop in a moment — even with a double tap when your hands are full.',
          subShort: 'Switch sides or stop when your hands are full.',
        },
        {
          title: 'Timely reminders, quick glances',
          sub: 'Notifications come with a log button; your watch face shows the time since the last feed.',
          subShort: 'Notifications with a log button; time since the last feed.',
        },
        {
          title: 'No phone needed nearby',
          sub: "Logs are saved on the watch and sync to the family once you're online.",
          subShort: 'Saved on the watch, synced once online.',
        },
      ],
      note: 'For Apple Watch, works with the iPhone app',
      mock: {
        baby: 'Teddy',
        time: '9:41',
        tiles: [
          { label: 'Bottle', value: '2:15', caption: 'since last feed' },
          { label: 'Breast', value: '3:35', caption: 'since last feed' },
          { label: 'Sleep', value: '0:42', caption: 'asleep' },
          { label: 'Diaper', value: '1:25', caption: 'since last time' },
          { label: 'Pumping', value: '5:10', caption: 'since last time' },
          { label: 'Reminder', value: '17:00', caption: 'feed reminder' },
        ],
        breast: {
          title: 'Breast',
          left: 'Left',
          leftValue: '8:12',
          right: 'Right',
          rightValue: '4:20',
          total: 'Total 12:32 · on the left',
          switchSide: 'Switch side',
          stop: 'Stop',
        },
        notify: {
          app: 'CHILD LIFE',
          title: 'Time for the feed you set',
          sub: 'Last feed 14:45 · 120 ml',
          log: 'Log bottle 120 ml',
          snooze: 'Remind me in 15 min',
        },
      },
    },
    yourWay: {
      eyebrow: 'Your way',
      title: "Your family's app, at your family's pace.",
      lead: "Show only what you need. Hide what you don't use.",
      bullets: [
        {
          title: 'Turn on, off and reorder the Today screen',
          sub: 'Bottle or breast, pumping or not — your family decides.',
          subShort: 'Bottle or breast, pumping or not — your family decides.',
        },
        {
          title: 'Night mode',
          sub: 'A dark screen, large text, quick logging at 3 am.',
          subShort: 'A dark screen, large text, quick logging at 3 am.',
        },
        {
          title: 'Your own spending categories',
          sub: 'Add, edit and hide categories to match how your family spends.',
          subShort: 'Add, edit and hide categories to match how your family spends.',
        },
      ],
      mock: {
        title: 'Customise Today',
        rows: [
          { title: 'Quick tiles', body: 'Feeds, sleep, diapers, pumping, growth' },
          { title: 'Upcoming reminders', body: '3 reminders on' },
          { title: 'Daily rhythm', body: '24-hour chart' },
        ],
        chips: ['Bottle', 'Breast', 'Sleep', 'Diaper', 'Pumping'],
        night: 'Gentle night mode',
      },
    },
  },
  reminders: {
    eyebrow: 'Reminders',
    title: 'Feed and sleep reminders for the right people.',
    lead: 'Set feed and sleep reminders at fixed times or counted from the last log. Once someone logs, the reminder turns off for everyone.',
    leadShort:
      'Feed and sleep reminders at fixed times or counted from the last log. Once someone logs, it turns off for everyone.',
    bullets: [
      {
        title: 'Two ways to remind',
        sub: 'At set times, or after the last feed or sleep',
        subShort: 'At set times, or after the last log',
      },
      {
        title: 'Choose who gets reminded',
        sub: "Parents and caregivers — grandparents aren't disturbed",
        subShort: 'Parents and caregivers',
      },
      {
        title: 'Act right from the notification',
        sub: 'Log it, snooze or skip in a single tap',
        subShort: 'Log, snooze or skip',
      },
    ],
    notification: {
      title: 'Time for the feed you set',
      sub: 'Last feed 11:45 · 3 hours ago',
      subShort: 'Last feed 11:45',
      log: 'Log feed',
      snooze: 'Snooze 15 min',
      snoozeShort: 'Snooze',
      skip: 'Skip',
    },
    rule: { title: 'Feed reminder', sub: '3 hours after the last feed', next: 'Next 14:45' },
    fixed: { title: 'Get ready for sleep', times: ['09:00', '13:00', '19:30'] },
    done: 'Dad Tuấn logged at 14:52 · reminder off',
    doneShort: 'Dad Tuấn logged · reminder off',
  },
  understand: {
    eyebrow: 'Week by week',
    title: 'Age-based tips: your baby this week.',
    lead: "Tips for your baby's exact age, the expected Wonder Weeks calendar and the moments worth remembering — so you worry less and enjoy more.",
    leadShort:
      "Tips for your baby's age, the expected Wonder Weeks and the moments worth remembering.",
    columns: [
      {
        title: 'Age-based tips',
        body: 'One short card per stage: how your baby is doing, what you can try, with related articles and milestones.',
      },
      {
        title: 'Wonder Weeks',
        body: 'An expected calendar based on the due date, with a reminder 3 days ahead. Read what your baby is learning and note what you see.',
      },
      {
        title: 'Milestones',
        body: 'Pick a suggested milestone or create your own, like “First trip to the countryside”. Add photos and notes — and keep it as a memory.',
      },
    ],
    age: {
      chips: ['3–4 weeks', 'Teddy · 3 weeks'],
      title: 'Follows faces, knows familiar voices',
      points: [
        'Talk and sing softly while your baby is awake',
        'Some tummy time, with a grown-up close by',
      ],
      footer: '2 articles · 2 common milestones',
    },
    wonder: {
      badge: 'Wonder Week 1',
      countdown: 'In 3 days',
      title: 'Changing sensations',
      dates: 'Expected weeks 4–5 · 11/10 – 18/10',
      signsLabel: 'Common signs',
      signs: ['Fussier', 'Clingy', 'Unsettled sleep'],
      learningLabel: 'What your baby is learning',
      learning: 'Sensing sound, light and smell more clearly',
      reminder: 'Remind me 3 days ahead',
    },
    milestone: {
      chips: ['Observed', 'Social'],
      title: 'Smiles back',
      note: '08/10/2026 · Mum · “Smiled when I sang after the morning feed.”',
      saved: 'Saved to Memories',
    },
    note: 'Written and reviewed by the Child Life expert team. Wonder Weeks are only an estimate — every baby has their own pace, and the app never scores or compares your baby.',
    noteShort:
      'Written and reviewed by our expert team. Wonder Weeks are only an estimate — every baby has their own pace.',
  },
  library: {
    eyebrow: 'Library & weaning',
    title: 'A library for baby care and starting solids.',
    lead: 'The baby care and weaning libraries are written, reviewed and kept up to date by our expert team. Search by topic or age — save articles for when you need them.',
    leadShort:
      'Written and reviewed by our expert team. Search by topic or age — save articles for when you need them.',
    bullets: [
      {
        title: 'Search and filter fast',
        sub: 'By topic, age and reading time',
        subShort: 'By topic and age',
      },
      {
        title: 'Save to read again',
        sub: "When an article is updated, you'll see it right away",
        subShort: 'See updates right away',
      },
      {
        title: 'Weaning diary',
        sub: 'Meals, how much your baby ate and the foods they tried',
        subShort: 'Meals and the foods they tried',
      },
    ],
    search: 'Baby startles in their sleep…',
    ageChip: '0–3 months',
    articles: [
      { tag: 'Sleep', title: 'Newborn sleep', meta: '6 min read · reviewed by our experts' },
      {
        tag: 'Weaning · Recipe',
        title: 'Pumpkin porridge for first tastes',
        meta: '15 min · 6–7 months',
      },
    ],
    articleMetaShort: '6 min read',
    solids: {
      label: 'Weaning today',
      meal: 'Pumpkin porridge · 4 spoons',
      triedLabel: 'Foods tried · 14',
      foods: ['Rice', 'Pumpkin', 'Carrot', 'Avocado', 'Banana'],
      newFood: 'Sweet potato',
      more: '+8',
      moreShort: '+9',
    },
    saved: 'Saved to Library',
  },
  firstAid: {
    eyebrow: 'First aid',
    title: 'First aid for children, step by step.',
    lead: 'Common little emergencies — fever, falls, minor burns, insect bites — explained briefly and calmly so you can look after your baby with a clear head.',
    leadShort:
      'Fever, falls, minor burns, insect bites — explained briefly and calmly so you can stay calm.',
    bullets: [
      {
        title: 'Common situations',
        sub: 'Fever, falls, minor burns, choking, insect bites…',
        subShort: 'Fever, falls, minor burns, choking, insect bites…',
      },
      {
        title: 'Step by step, illustrated',
        sub: 'Easy to read even with your baby in your arms',
        subShort: 'Easy to read even with your baby in your arms',
      },
      {
        title: 'Reviewed with medical experts',
        sub: 'Always reminds you to ask a doctor when needed',
        subShort: 'Always reminds you to ask a doctor when needed',
      },
    ],
    card: {
      title: 'First aid',
      sub: 'Step-by-step, easy to follow',
      topics: ['Choking', 'Fever', 'Minor burn', 'Falls, bumps', 'Insect bites', 'Nosebleed'],
      step: { label: 'Minor burn · step 1/4', text: 'Stay calm and follow the illustrated steps' },
    },
  },
  care: {
    eyebrow: 'Everyday care',
    title: "Your baby's day in one log, clear at a glance.",
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
    title: 'The whole family keeps one log.',
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
    title: 'From the photos on your phone to memories the whole family keeps.',
    lead: "Child Life finds your baby's photos for you and sorts them by milestone, month and week; then helps you make videos and cards, share with family and turn them into stories.",
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
    stepChip: 'Step {n}',
    steps: [
      {
        label: 'Find & pick photos',
        title: 'Found for you — just pick and save',
        body: 'New photos of your baby are recognised and gathered. Save them all or pick the best ones — duplicates and blurry shots are filtered out.',
        tags: ['Automatic', 'Quick pick', 'Private'],
      },
      {
        label: 'View by milestone, month, week',
        title: 'Look back by milestone, month or week',
        body: "One tap to switch views: by your baby's firsts, by month of age, or week by week lately.",
        tags: ['Milestones', 'Months', 'Weeks'],
      },
      {
        label: 'Make videos, cards',
        title: 'Videos and cards in a few taps',
        body: 'Pick a monthly, 100-day or birthday template — the app puts the photos, music and words together for you.',
        tags: ['Video', 'Card'],
      },
      {
        label: 'Family album',
        title: 'A private album the whole family enjoys',
        body: 'Invite grandparents and relatives. Everyone can look, send a heart and comment on each photo.',
        tags: ['Share', 'Comment', 'Heart'],
      },
      {
        label: 'Stories & sharing',
        title: 'Suggested stories, shared beyond the family',
        body: 'The app suggests a story from your photos and journal. Change a few words, then post it on social media when you like.',
        tags: ['Stories', 'Social media'],
      },
    ],
    found: {
      title: 'Found 8 new photos of Teddy',
      sub: 'Taken today · 2 duplicates hidden',
      saveAll: 'Save all',
      pick: 'Choose photos',
    },
    views: ['Milestones', 'Months', 'Weeks'],
    clip: '0:45 · 6 months old',
    card: { title: '100 days', meta: 'Teddy · 18 Jan' },
    share: { label: 'Share:', targets: ['Facebook', 'Instagram', 'Zalo', 'Save image'] },
    tiles: {
      photos: {
        chip: 'Favourites · 48',
      },
      story: {
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
    title: 'Night mode for late-night feeds.',
    lead: 'In the evening the screen softens by itself: a warm dark background, large text, no glare. Your baby drifts back to sleep, and so can you.',
    checks: [
      'Turns on at the time you choose, nothing to remember',
      'Big buttons you can tap one-handed while holding your baby',
    ],
    sleepWidget: { label: 'Asleep', sub: 'Since 21:42 · Dad' },
  },
  roles: {
    eyebrow: 'Privacy',
    title: "You choose who sees your baby's photos and details.",
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
        q: 'Who writes the tips in the app?',
        a: "The Child Life expert team writes, reviews and updates the age cards, articles and guides in the app. They are for reference and don't replace a doctor's advice — if something seems wrong, ask your doctor.",
        open: false,
      },
      {
        q: 'Is the Wonder Weeks calendar right for every baby?',
        a: "Not exactly. It's an estimate based on your baby's due date, and every baby has their own pace — some earlier, some later. The app never scores or compares your baby; it just helps you know what may be coming.",
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
