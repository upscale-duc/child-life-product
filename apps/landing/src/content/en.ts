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
      journey: 'Journey',
      firstYear: 'First year',
      lumi: 'Lumi',
      stages: 'Stages',
      memories: 'Memories',
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
    push: { app: 'CHILD LIFE', now: 'now' },
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
      title: ['Say it once.', 'Lumi logs it and remembers it.'],
      lead: "Lumi is the whole family's assistant in Child Life. Type as if you were texting, snap a photo or ask a question — Lumi drafts the logs, answers from your child's own records and suggests one small thing for today.",
      tryNow: 'Try Lumi',
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
    more: {
      eyebrow: 'And much more',
      title: 'Lumi grows with your family.',
      lead: "The more you log, the better Lumi knows your family's rhythm — to remind you at the right time and suggest things that fit.",
      cards: [
        {
          title: 'Note photo → reminders',
          body: 'Snap a handwritten note or a notice board, and Lumi splits it into reminders for you to pick and save.',
        },
        {
          title: 'Weekly summary for the family',
          body: 'A short note each week: how your child ate and slept, new milestones, what is coming — shared with grandparents by role.',
        },
        {
          title: "Your child's own rhythm",
          body: 'Puts the changes you logged next to a reference stage calendar — Stage N (Wonder Weeks) is only for comparison.',
        },
        {
          title: 'Childcare Q&A',
          body: 'Ask about sleep, solids or hygiene — Lumi answers from the content library and points to safety guidance when needed.',
        },
      ],
      mock: {
        reminders: ['Buy size M nappies · Saturday', '2-month check-up · 9 am Thu'],
        note: ['Buy size M nappies', '2-month check-up 9 am Thu'],
        week: {
          title: "Teddy's week",
          body: 'Slept longer on 2 nights · new milestone “laughs out loud” · vaccination next week.',
        },
        rhythm: {
          title: 'Stage 2 (Wonder Weeks) · reference',
          body: 'You logged: clingier for 3 days, one extra night feed.',
        },
        ask: 'How many naps does a 4-month-old take?',
        reply: 'From the library: usually 3–4 naps… (sample content · awaiting review)',
      },
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
        "Lumi is not a doctor. When you're worried about health, Lumi points you to safety guidance and the emergency number",
      ],
    },
    plans: {
      eyebrow: 'Plans',
      title: 'Everything Lumi does, for every family.',
      lead: "The three plans differ only in monthly help. Pick what fits your family's pace — switch any time.",
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
        body: 'Each time Lumi does something for you uses one credit. Credits refresh at the start of each period.',
        rules: [
          ['One log sentence or one question', '1 credit'],
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
  lumiJourney: {
    eyebrow: 'Lumi grows with your child',
    title: 'As your child grows, Lumi grows too.',
    lead: "Today Lumi helps you through the first year. At each later stage Lumi will gain new ways to help — right for your child's age and your family's rhythm.",
    current: 'Available',
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
    outroTitle: 'Start today. The next stages are on their way.',
    outroBody:
      'Everything above is a direction in development. Scope and timing will be updated stage by stage.',
    explore: 'Explore Lumi today',
    tryNow: 'Try Lumi today',
  },
  // "Made for your child" (Figma 699:5798, home) and "A day made for your child" (700:5832, Lumi
  // page): engineering drafts for owner review (D-012). Q-039: meal ideas await expert review.
  forBaby: {
    eyebrow: 'Made for your child, from what you log',
    title: ['Every baby has their own rhythm.', 'Every day, one idea that fits.'],
    lead: 'From feeds, sleep and foods tried to new milestones, Child Life helps you look back at what is changing and pick one small thing for today.',
    values: [
      {
        title: 'See recent days clearly',
        body: 'Related logs sit side by side, so it is easy to look back when eating or sleeping patterns change.',
      },
      {
        title: 'Less searching, more that fits',
        body: "Meal, activity and reading ideas based on your child's age, what you've logged and what your family cares about.",
      },
      {
        title: 'Never let a milestone slip by',
        body: 'From a milestone you just logged, ideas to keep it as a story, card or video for the whole family.',
      },
    ],
    cta: 'See a day made for your child',
    control: 'You choose what fits, edit what you logged and tell us which ideas help.',
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
    highlightsTitle: 'At this stage, Child Life is with you',
    prev: '← Previous stage',
    next: 'Next stage →',
    backLabel: 'Back to',
    backTitle: 'The whole journey',
    ctaTitle: ['Start the journey with your child', 'today.'],
    stages: [
      {
        name: 'The very first days',
        ages: '0–12 months',
        title: 'The very first days.',
        lead: "Getting to know each other one feed and one nap at a time — and keeping your child's firsts.",
        chips: ['Everyday care', 'Week by week', 'Keep the moments'],
        highlights: null,
        quote: null,
      },
      {
        name: 'Exploring the world',
        ages: '1–3 years',
        title: 'Exploring the world.',
        lead: 'Toddling, first words and small new habits, together.',
        chips: ['Daily rhythm', 'Play & movement', 'First words'],
        highlights: [
          {
            title: 'First steps',
            body: 'Capture the wobbly first steps, the first words and the first trips away from home.',
          },
          {
            title: 'Small daily rhythms',
            body: 'The whole family keeps track of meals and naps, and gently builds first habits.',
          },
          {
            title: 'Play together',
            body: 'Ideas for play, movement and conversation that suit their age.',
          },
        ],
        quote: 'First steps, the moments the whole family cheers — all worth keeping.',
      },
      {
        name: 'Curious and growing',
        ages: '3–6 years',
        title: 'Curious and growing.',
        lead: 'Playing, reading, drawing and answering an endless stream of “why?”.',
        chips: ['Learning through play', 'Feelings', 'Their creations'],
        highlights: [
          {
            title: 'Learning through play',
            body: 'Read stories, draw and make little things together.',
          },
          {
            title: 'All the “why?” questions',
            body: 'Keep what they wonder about and the funny things they say.',
          },
          {
            title: 'Growing up bit by bit',
            body: 'Practise doing things on their own and naming their feelings.',
          },
        ],
        quote: 'Every “why?” is a small memory worth saving.',
      },
      {
        name: 'A world of their own',
        ages: '6–12 years',
        title: 'A world of their own.',
        lead: 'Gently by their side as they grow independent, with interests and dreams of their own.',
        chips: ['Interests', 'Independence', 'Look back on the journey'],
        highlights: [
          {
            title: 'What they love',
            body: "Keep their hobbies, projects and the things they're proud of.",
          },
          {
            title: 'Independent, their way',
            body: 'Set small goals as a family; your child takes the lead.',
          },
          {
            title: 'Their own space',
            body: 'Stay close while respecting the world they are building.',
          },
        ],
        quote: "They have a world of their own now. You're still here whenever they need you.",
      },
    ],
  },
  home: {
    hero: {
      eyebrow: 'Child Life · Growing up together',
      title: ['Grow up together,', 'one step at a time.'],
      lead: 'An ecosystem that helps parents care for, understand and walk alongside their child — from the very first days to adulthood.',
      promises: [
        'Everyday care, with the whole family in sync',
        'Understand your child through every stage',
        'Walk alongside them and keep their journey',
      ],
      explore: "See your child's journey",
      art: {
        feed: { title: 'Bottle · 120 ml', sub: 'Mum logged · 2 min ago' },
        smile: { title: 'First smile', sub: 'Saved to Memories' },
        love: "Grandma loved Teddy's photo",
      },
    },
    chapters: {
      eyebrow: 'Growing up',
      title: 'With your child at every stage.',
      lead: 'At every stage of growing up, Child Life helps you care for your child, understand them and keep what matters.',
      available: 'In the app',
      explore: 'Explore the first year',
      view: 'See this stage',
    },
    firstYear: {
      eyebrow: 'Stage 1 · The first year',
      title: "Your baby's first year, gentler for the whole family.",
      lead: 'Everyday care, understanding your baby week by week and keeping the firsts — all in one app.',
      leadShort: 'Everyday care, understanding your baby week by week and keeping the firsts.',
      more: 'See the first year in detail',
      detail: {
        eyebrow: 'Stage 1 · 0–12 months',
        title: 'See the whole first year',
        body: 'Every part in detail: quick logging, reminders, vaccine schedule, solids, first aid, night mode and who sees what.',
      },
    },
    stages: {
      eyebrow: 'Next stages',
      title: 'As your child grows, Child Life grows too.',
      lead: 'After the first year, each stage brings new ways to care, new things to watch for and new memories. These stages are on the way.',
      firstName: 'First year',
      current: 'available',
      soon: 'Coming soon',
      preview: 'Preview stage {n}',
      lumiLabel: 'Lumi at this stage',
      lumiTeasers: [
        'What shall we play today?',
        '“Why?” becomes playtime',
        'Their ideas get a place to start',
      ],
    },
    lumi: {
      eyebrow: 'New · Lumi · your companion assistant',
      title: "Meet Lumi — a little assistant for your baby's first year.",
      lead: 'Holding the baby and still logging the feed on time. Ask one question and see how your baby ate and slept today. Lumi handles the notes and the summing up; you just review and tap save.',
      cta: 'Explore Lumi',
      name: 'Lumi',
      suggestions: [
        '“Baby just had 120 ml at 9”',
        '“How long did baby sleep today?”',
        'Weaning ideas',
        'Make a one-month video',
        'Snap a diaper receipt',
        '“Baby has been sleeping badly lately”',
      ],
      features: [
        {
          title: 'Say it once, logged in the right place',
          body: 'Type one line as if texting family — Lumi splits it into feed, sleep and diaper entries for you to review.',
        },
        {
          title: 'Ask in your own words',
          body: "“How did baby feed today?” — Lumi answers from your baby's own log, with the source to open.",
        },
        {
          title: 'Look back at the last few days',
          body: 'When sleep or feeds get harder, Lumi lines up recent entries so you can see more clearly.',
        },
        {
          title: 'What can baby eat today?',
          body: "Age-based ideas from the library, avoiding foods you've noted a reaction to.",
        },
        {
          title: 'Snap the receipt, expense done',
          body: 'Snap a diaper or milk receipt — Lumi drafts the expense and checks anything unclear before saving.',
        },
        {
          title: 'Turn photos into memories',
          body: 'Pick photos and a template; Lumi helps turn them into a card or a short film for the first milestones.',
        },
      ],
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
      eyebrow: "Your child's memories",
      title: 'Not just kept, but told.',
      lead: "Videos, cards, journals, messages and even a book — made from your family's own photos and words.",
      cards: [
        {
          format: 'MP4 video',
          title: 'Memory story',
          body: "A memory video from ready-made templates, with photos, words, music and your child's milestones.",
        },
        {
          format: 'PNG/JPG image',
          title: 'Milestone magic',
          body: 'Beautiful milestone cards: one month, 100 days, first roll-over… save the image or send it to the family.',
        },
        {
          format: 'Journal',
          title: 'Little moments',
          body: "A short post with photos or videos, saved straight to your child's memory timeline.",
        },
        {
          format: 'Photo / Video',
          title: 'Then and now',
          body: "Compare your child's photos from two moments, and make a transition video from then to now.",
        },
        {
          format: 'Voice + text',
          title: 'Love from the family',
          body: 'Voice or written messages from parents and grandparents — kept for your child to hear when they grow up.',
        },
        {
          format: 'PDF / Printed book',
          title: 'First-year book',
          body: "A book of your child's first 12 months — download the PDF or order a printed photo book.",
        },
      ],
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
    growUp: {
      eyebrow: 'One record that grows with them',
      title: 'What you save today, they will look back on when they grow up.',
      body: "From the first birthday to the first day of school and the dreams at twelve — your child's story stays in one place and never gets lost as they grow.",
      bodyShort: 'From the first birthday to the dreams at twelve — all in one place.',
      years: [
        { year: 'Age 1', caption: '2027 · First birthday' },
        { year: 'Age 6', caption: '2032 · First day of school' },
        { year: 'Age 12', caption: '2038 · Dreams of their own' },
      ],
    },
    faq: {
      items: [
        {
          q: 'What is Child Life?',
          a: 'An ecosystem that helps parents care for, understand and walk alongside their child through every stage of growing up. The app currently focuses on the first year.',
          open: true,
        },
        {
          q: 'What age is Child Life for?',
          a: 'From the day your baby is born. In the first year the app helps the whole family with everyday care; the next stages will grow with your child into adulthood.',
          open: true,
        },
        {
          q: 'When my child grows up, will their photos and records still be there?',
          a: 'Yes. Their photos, videos and stories stay in your family until you delete them yourself, and you can download them at any time.',
          open: false,
        },
        {
          q: 'Does it cost anything?',
          a: "No. The whole family uses it for free, with room for thousands of your baby's photos. If you need more space, just message us.",
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
          q: 'Does the first aid guide replace a doctor?',
          a: "No. The first aid guide in the app is for reference while you wait for medical help and doesn't replace a doctor's diagnosis. If your child is in danger, call emergency services right away.",
          open: false,
        },
        {
          q: "Who can see the family's spending?",
          a: 'By default only the parents (Co-parent members) see spending. Parents can let others log what they paid, or see everything, from the Family section.',
          open: false,
        },
        {
          q: 'Can I use Child Life on Apple Watch?',
          a: "Yes, if you use an iPhone. Connect your watch once from the iPhone app, then log feeds, sleep and diapers and run timers right on your Apple Watch, even when your phone isn't nearby. There is no app for Android watches yet.",
          open: false,
        },
      ],
    },
    utilities: {
      title: 'Tools for parents',
      lead: 'Small things that make parenting lighter — ready in the Tools tab.',
      cards: [
        {
          title: 'Child first aid',
          body: '25 common situations, illustrated step by step, with instructions read aloud. Works even without a connection.',
        },
        {
          title: 'A shared spending book',
          body: 'Everything you spend on your child in one place. Both parents log and see the same book — what your child needs and what the family has covered.',
        },
      ],
      spending: {
        header: 'Spent on Teddy · this month',
        total: '4,215,000 ₫',
        split: [
          { label: 'Mum logged', amount: '2,320,000 ₫' },
          { label: 'Dad logged', amount: '1,895,000 ₫' },
        ],
        initials: ['M', 'D'],
        together: 'Mum and Dad see the same book',
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
  everything: {
    eyebrow: 'Everything in one app',
    title: 'Everything about your baby, in one place.',
    lead: 'From the midnight feed to the first smile — log it in a moment, understand your baby a little more each week and keep their whole childhood.',
    leadShort:
      'Log it in a moment, understand your baby more each week and keep their whole childhood.',
    tiles: [
      {
        title: 'Log in one tap',
        body: 'Feeds, sleep, diapers — right on your home screen, even with your baby in your arms.',
        bodyShort: 'Feeds, sleep, diapers from the home screen',
      },
      {
        title: 'Timely reminders',
        body: 'Feed and sleep reminders at set times or after the last log.',
        bodyShort: 'Set times or after the last log',
      },
      {
        title: 'Care as a family',
        body: 'Parents, caregivers, grandparents — everyone knows how your baby is doing.',
        bodyShort: 'Everyone knows how baby is doing',
      },
      {
        title: 'Week by week',
        body: 'Age cards and the expected Wonder Weeks calendar for every stage.',
        bodyShort: 'Age cards & Wonder Weeks',
      },
      {
        title: 'Milestones',
        body: 'Note the first smile, the first roll, sitting up — with photos and notes.',
        bodyShort: 'First smile, rolling, sitting…',
      },
      {
        title: 'Baby care library',
        body: 'Short reads on feeding, sleep, teething, fever — reviewed by our experts.',
        bodyShort: 'Reviewed by our experts',
      },
      {
        title: 'Gentle weaning',
        body: 'A meal diary, foods your baby has tried and recipes for every stage.',
        bodyShort: 'Meal diary & recipes',
      },
      {
        title: 'Keep their childhood',
        body: "Your baby's photos, videos and stories — private to your family.",
        bodyShort: 'Photos, videos, stories',
      },
    ],
    logChips: ['Bottle · 120 ml', 'Asleep 1:27'],
    notification: { title: 'Time for the feed you set', sub: 'Last feed 11:45' },
    familyChip: 'Dad Tuấn just logged a diaper',
    weekChips: ['3 weeks old', 'Wonder Week 1 · in 3 days'],
    milestone: { title: 'Smiles back', sub: 'Observed · 08/10' },
    topics: ['Sleep', 'Teething', 'Feeding & milk'],
    foods: ['Pumpkin', 'Carrot', 'Avocado'],
    moreFoods: '+11 foods',
  },
  reminders: {
    eyebrow: 'Reminders',
    title: 'Timely reminders the whole family sees.',
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
    title: 'Understand your baby a little more each week.',
    lead: "Tips for your baby's exact age, the expected Wonder Weeks calendar and the moments worth remembering — so you worry less and enjoy more.",
    leadShort:
      "Tips for your baby's age, the expected Wonder Weeks and the moments worth remembering.",
    columns: [
      {
        title: 'Age cards',
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
    title: 'Whatever you wonder, there is a short, clear read.',
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
    title: 'When something unexpected happens, the steps are ready.',
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
