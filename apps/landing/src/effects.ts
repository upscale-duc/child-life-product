import { saveLocale, supportedLocales, type SupportedLocale } from '@child-life/web-config';

/** Client-only behaviour, started after hydration. Each returns a cleanup. */

/** Scales `.fit` compositions to their measured width (server HTML uses the Figma mobile scale). */
export function startFit(root: ParentNode = document): () => void {
  const targets = Array.from(root.querySelectorAll<HTMLElement>('.fit[data-fit-w]'));
  const apply = (el: HTMLElement) => {
    const width = el.clientWidth;
    if (width > 0) el.style.setProperty('--fit', String(width / Number(el.dataset.fitW)));
  };
  targets.forEach(apply);
  if (!('ResizeObserver' in window)) return () => undefined;
  const observer = new ResizeObserver((entries) =>
    entries.forEach((entry) => apply(entry.target as HTMLElement)),
  );
  targets.forEach((el) => observer.observe(el));
  return () => observer.disconnect();
}

/** Running timers in the mockups ("1:27:06") count up once per second, all in sync. */
export function startTicking(root: ParentNode = document): () => void {
  const pattern = /^(\d{1,2}):(\d{2}):(\d{2})$/;
  const targets = Array.from(root.querySelectorAll<HTMLElement>('[data-tick]')).filter((el) =>
    pattern.test(el.textContent ?? ''),
  );
  const timer = window.setInterval(() => {
    for (const el of targets) {
      const [, h, m, s] = pattern.exec(el.textContent ?? '') ?? [];
      if (h === undefined) continue;
      const total = Number(h) * 3600 + Number(m) * 60 + Number(s) + 1;
      const hours = String(Math.floor(total / 3600)).padStart(h.length, '0');
      el.textContent = `${hours}:${String(Math.floor((total % 3600) / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
    }
  }, 1000);
  return () => window.clearInterval(timer);
}

/** Frosted nav after scrolling; highlights the nav link of the section in view. */
export function startNav(): () => void {
  const nav = document.querySelector<HTMLElement>('[data-nav]');
  const onScroll = () => nav?.classList.toggle('is-scrolled', window.scrollY > 8);
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  const links = Array.from(document.querySelectorAll<HTMLAnchorElement>('[data-spy]'));
  const sections = links
    .map((a) => document.getElementById(a.dataset.spy!))
    .filter((s): s is HTMLElement => !!s);
  let observer: IntersectionObserver | undefined;
  if (sections.length && 'IntersectionObserver' in window) {
    observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          links.forEach((a) => {
            const active = a.dataset.spy === entry.target.id;
            a.classList.toggle('is-active', active);
            if (active) a.setAttribute('aria-current', 'location');
            else a.removeAttribute('aria-current');
          });
        }
      },
      // A section is "current" while it crosses a band just below the nav.
      { rootMargin: '-96px 0px -60% 0px' },
    );
    sections.forEach((s) => observer!.observe(s));
  }
  return () => {
    window.removeEventListener('scroll', onScroll);
    observer?.disconnect();
  };
}

/** Remembers the language a visitor picks with the switch (D-012). */
export function startLocaleLinks(): () => void {
  const onClick = (event: MouseEvent) => {
    const link = (event.target as Element | null)?.closest<HTMLAnchorElement>('a[data-locale]');
    const locale = link?.dataset.locale;
    if (locale && (supportedLocales as readonly string[]).includes(locale))
      saveLocale(locale as SupportedLocale);
  };
  document.addEventListener('click', onClick);
  return () => document.removeEventListener('click', onClick);
}

const storyFontFaces = (() => {
  const vietnamese =
    'U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB';
  const latin =
    'U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD';
  const faces: [string, string, string][] = [
    ['Lora', 'normal', 'lora'],
    ['Lora', 'italic', 'lora-italic'],
    ['Dancing Script', 'normal', 'dancing-script'],
  ];
  return faces
    .flatMap(([family, style, file]) =>
      [
        [vietnamese, 'vietnamese'],
        [latin, 'latin'],
      ].map(
        ([range, subset]) =>
          `@font-face{font-family:'${family}';font-style:${style};font-weight:400;font-display:swap;src:url('/fonts/${file}-${subset}.woff2') format('woff2');unicode-range:${range}}`,
      ),
    )
    .join('');
})();

/** The StoryCard art fonts (Tuổi thơ tile 2, ~55 KB, decorative) are only fetched when that tile
 *  gets near the viewport, so they never compete with the first paint. */
export function startStoryFonts(): () => void {
  const target = document.querySelector('.tile__group--story');
  if (!target) return () => undefined;
  const load = () => {
    const style = document.createElement('style');
    style.textContent = storyFontFaces;
    document.head.append(style);
  };
  if (!('IntersectionObserver' in window)) {
    load();
    return () => undefined;
  }
  const observer = new IntersectionObserver(
    (entries) => {
      if (!entries.some((e) => e.isIntersecting)) return;
      observer.disconnect();
      load();
    },
    { rootMargin: '1200px 0px' },
  );
  observer.observe(target);
  return () => observer.disconnect();
}

/** On narrow screens the stage switcher scrolls sideways: bring the current stage into view. */
export function startSwitcher(): () => void {
  const row = document.querySelector<HTMLElement>('.switcher');
  const active = row?.querySelector<HTMLElement>('.is-active');
  if (row && active && row.scrollWidth > row.clientWidth)
    row.scrollLeft = active.offsetLeft - (row.clientWidth - active.offsetWidth) / 2;
  return () => undefined;
}
