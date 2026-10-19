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
        "Say it in one sentence and Lumi drafts the feed, sleep and nappy logs; snap a receipt and it becomes an expense; ask anything and it answers from your child's own logs. You review before anything is saved.",
    },
    hero: {
      eyebrow: 'Lumi · The helper inside Child Life',
      title: ['Send one message.', 'Lumi drafts the log.'],
      lead: "Lumi is the whole family's assistant in Child Life. Type as if you were texting, snap a photo or ask a question — Lumi drafts the logs, answers from your child's own records and suggests one small thing for today.",
      tryNow: 'Open Lumi in the app',
      plans: 'See plans',
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
    day: {
      eyebrow: 'A day with Lumi',
      title: 'From the first morning feed to the end-of-month video.',
      lead: 'Six familiar moments, each needing just a sentence or a photo.',
      cards: [
        {
          time: '06:30',
          title: 'Holding the baby, still logging',
          body: 'Say one sentence, Lumi drafts the log.',
        },
        {
          time: '10:15',
          title: 'Receipts become expenses',
          body: 'Snap the receipt, Lumi fills in the amount.',
        },
        {
          time: '13:00',
          title: 'Ask and know',
          body: 'Answers from your logs, with the source to open.',
        },
        {
          time: '17:30',
          title: 'What should they eat today?',
          body: 'Age-appropriate dishes that avoid what your child reacted to.',
        },
        {
          time: '21:30',
          title: 'Bedtime has been hard lately',
          body: 'Lays recent notes side by side.',
        },
        {
          time: 'End of month',
          title: 'A month old, a little film',
          body: 'Pick photos and a template for a one-month video.',
        },
      ],
    },
    quickNav: {
      label: 'On this page:',
      items: ['Examples', 'Ideas for your baby', 'How it works', 'Plans', 'FAQ'],
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
    plans: {
      eyebrow: 'Plans',
      title: 'Start free. Add more help when your family needs it.',
      lead: 'Every plan has the same features. They differ in Lumi help credits and memory videos each month.',
      monthly: 'Monthly',
      yearly: 'Yearly',
      perMonth: '/ month',
      perYear: '/ year',
      credits: 'help credits / month',
      tiers: [
        {
          name: 'Free',
          tagline: 'To get started',
          credits: '30',
          photos: '≈ 10 receipt or note photos',
          videos: '1 memory video / month',
          price: '0 ₫',
          yearPrice: '0 ₫',
          sub: 'No card needed',
          yearSub: 'No card needed',
          button: 'Start free',
        },
        {
          name: 'Plus',
          tagline: 'For busy days',
          credits: '300',
          photos: '≈ 100 receipt or note photos',
          videos: '5 memory videos / month',
          price: '79,000 ₫',
          yearPrice: '790,000 ₫',
          sub: 'or 790,000 ₫/year · 2 months free',
          yearSub: '≈ 65,800 ₫/month · 2 months free',
          button: 'Upgrade to Plus',
        },
        {
          name: 'Pro',
          tagline: 'For the whole family',
          credits: '1,000',
          photos: '≈ 330 receipt or note photos',
          videos: '15 memory videos / month',
          price: '179,000 ₫',
          yearPrice: '1,790,000 ₫',
          sub: 'or 1,790,000 ₫/year · 2 months free',
          yearSub: '≈ 149,200 ₫/month · 2 months free',
          button: 'Upgrade to Pro',
        },
      ],
      features: {
        all: 'Everything Lumi can do',
        templates: 'All card & video templates',
        drafts: 'Editing and confirming drafts costs nothing extra',
      },
      note: 'Prices include VAT, paid through the App Store / Google Play. The yearly plan saves 2 months. Cancel renewal any time in your store settings.',
      table: {
        caption: 'Compare plans',
        feature: 'Feature',
        price: 'Price per month',
        credits: 'Help credits per month',
        rows: [
          'Log with one sentence',
          "Q&A from your child's logs",
          'Read receipt and note photos (≈3 credits/photo)',
          "Look back over recent days & today's suggestion",
          'Weekly family summary',
          "Your child's own rhythm",
          'All card & video templates',
        ],
        videos: 'Memory video exports per month',
        fallback: 'Direct logging & safety guidance when credits run out',
        yes: 'Included',
      },
      creditsInfo: {
        title: 'What is a help credit?',
        body: 'A credit is only used when Lumi has to think for you. Credits refresh at the start of each period.',
        rules: [
          ['Everyday feed, sleep and diaper logs, or a quick look at the journal', 'Free'],
          ['A long message or a question Lumi has to think about', '1 credit'],
          ['Reading one receipt or note photo', '≈ 3 credits'],
          ['Follow-ups, edits or confirming drafts in the same task', 'Free'],
          ['System error, retry', 'Free'],
          ['Out of credits', 'Keep logging directly and viewing logs as usual'],
        ],
      },
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
          q: 'What happens when I run out of credits?',
          a: 'You can still log directly and view your logs as usual; essential health guidance stays open. Credits refresh at the start of the next period.',
          open: false,
        },
        {
          q: 'Is anything missing from the Free plan?',
          a: 'No. Everything Lumi does is in the Free plan; the plans differ only in monthly credits.',
          open: false,
        },
        {
          q: 'Can I switch plans mid-way?',
          a: 'Yes. You switch plans in the app; renewals and cancellations are handled by the App Store / Google Play.',
          open: false,
        },
        {
          q: 'Who in the family shares the credits?',
          a: "The whole family shares the household's credits. Only the family owner buys and manages the plan.",
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
      plans: 'See plans',
    },
  },
  // V8 home (Figma 735:5377 / 736:65570): engineering drafts for owner review (D-012).
  homePage: {
    hero: {
      eyebrow: 'Child Life · Starting with the first year',
      title: 'Care for your baby together, and keep every moment as they grow.',
      lead: "Log feeds, sleep and diapers so the whole family can follow along. Save photos, make videos and keep your baby's firsts.",
      support: 'Start with the first year. Stay with your child as they grow.',
      seeApp: 'See the app in action',
      vision: 'A companion for your child — from their first days to growing up.',
      now: 'In the app now',
      soon: 'Coming up',
      feed: { title: 'Bottle · 120 ml', sub: 'Dad logged it · 2 min ago' },
      smile: { title: 'First smile', sub: 'Saved to Memories' },
      video: { title: "Teddy's one-month video", meta: '0:45 · from photos you picked' },
    },
    values: {
      eyebrow: 'What Child Life does',
      title: 'Child Life helps your family with three things.',
      lead: "Each one works from your baby's very first year.",
      cards: [
        {
          title: 'Daily care',
          body: 'Log feeds, sleep and diapers and set reminders. Everyone knows how the baby was just cared for.',
        },
        {
          title: 'Understand each stage',
          body: "Read the journal, track milestones and find content for your baby's age.",
        },
        {
          title: 'Keep what matters',
          body: "Save photos privately, and make cards and videos from your baby's moments.",
        },
      ],
      mock: {
        rows: [
          ['Bottle 120 ml', '9:00'],
          ['Slept 1 h 20 min', '10:40'],
          ['Diaper change', '11:05'],
        ],
        week: {
          title: "Baby's week · 4 months",
          body: 'Babies often start reaching for things. Tip: keep a toy within reach.',
        },
        milestone: ['Milestone: Rolls over', 'logged'],
      },
    },
    memories: {
      eyebrow: 'Memories',
      title: "Today's photos, kept as memories to look back on.",
      lead: "Pick your baby's photos to make a one-month video or a milestone card, or save them to your family's private album.",
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
        body: 'Grandparents far away can still follow along.',
        initial: 'G',
        seen: 'Grandma loved 3 new photos',
      },
      alsoLabel: 'Also:',
      also: ["Your baby's journal", 'Messages for your child', 'First-year book'],
      soon: 'Coming soon',
      button: 'See memory templates',
    },
    family: {
      eyebrow: 'Caring together',
      title: 'Dad logs it, Mom sees it. No one has to ask again.',
      bullets: [
        'Log and read one shared journal.',
        'Reminders go to whoever is caring for the baby.',
        "Parents, caregivers and relatives each see what's right for them.",
      ],
      trust: "You choose who sees your baby's photos and details.",
      steps: [
        {
          initial: 'D',
          meta: 'Dad · 09:00',
          title: 'Dad logs a feed',
          body: "Bottle, 120 ml — one tap and it's done.",
        },
        {
          initial: 'M',
          meta: 'Mom · 09:01',
          title: 'Mom sees it right away',
          body: '“Dad just logged: Bottle, 120 ml at 9:00.”',
        },
        {
          initial: '✓',
          meta: 'Family',
          title: 'No need to ask',
          body: 'The next feed already has a reminder for whoever is caring.',
        },
      ],
    },
    wrist: {
      chip: 'On your wrist',
      title: 'Holding your baby? Log it on your watch.',
      lead: 'One tap to log a feed, sleep or diaper — the family sees it on their phones right away.',
      apple: 'Apple Watch',
      wear: 'Android watches (Wear OS) · Coming soon',
      wearLabel: 'Wear OS',
      round: { asleep: 'Asleep' },
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
    detail: {
      eyebrow: 'A day made for your child',
      title: ['No need to think of a question.', 'What matters is already waiting.'],
      lead: 'Each time you open the app, “Today for your baby” puts the information and ideas that matter for your child first — with the reason each one appears.',
      modes: [
        {
          name: 'Lumi',
          sub: 'You tell or ask — Lumi handles it.',
          example: '“Fed 120 ml at 9” → Lumi drafts the log for you to save.',
        },
        {
          name: 'Today for your baby',
          sub: 'You open the app — what matters is already there.',
          example:
            'No need to ask: “Look back at sleep” appears because you logged 2 hard evenings.',
        },
      ],
      modesNote: 'Both use what your family has logged, but serve two different moments.',
      steps: ['What you logged', 'What you see today', 'You decide'],
      scenarios: [
        {
          logged: ['Hard to settle · Tue', 'Hard to settle · Wed', '6 sleeps'],
          decide: ['See related logs', 'Hide sleep this week'],
        },
        {
          logged: ['7 months', 'Tried: pumpkin, sweet potato', 'Reaction logged: egg'],
          decide: ['See dishes and ingredients', 'Save to try', 'Not a fit'],
        },
        {
          logged: ['Milestone: smiles back', '3 photos picked'],
          decide: ['Make a card from the photos', 'Later'],
        },
      ],
      controlTitle: "You're always in control:",
      controls: [
        'Pick the topics you care about',
        "Hide ideas that don't fit",
        'Edit what you logged',
        'Say what helped',
      ],
      note: 'Sample content. Meal and activity ideas come from a content library awaiting expert review; they will only be presented as available once live.',
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
    title: "Your baby's photos, cards, videos and journal.",
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
