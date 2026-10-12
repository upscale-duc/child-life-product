import type { Route } from './context';

/**
 * Sidebar icons (portal review 2026-10-12): 24-grid line icons in the app's style (1.8 stroke,
 * round caps), so the collapsed menu reads by icon alone.
 */
const paths: Record<Exclude<Route, 'systemAi'> | 'collapse' | 'expand', string> = {
  overview:
    '<rect x="3.5" y="3.5" width="7" height="9" rx="2"/><rect x="13.5" y="3.5" width="7" height="5" rx="2"/><rect x="13.5" y="11.5" width="7" height="9" rx="2"/><rect x="3.5" y="15.5" width="7" height="5" rx="2"/>',
  analytics: '<path d="M4 20h16M7 16v-5M12 16V6M17 16v-8"/>',
  families:
    '<circle cx="9" cy="8" r="3.2"/><path d="M3 19.5c.6-3.2 3-5 6-5s5.4 1.8 6 5"/><circle cx="17" cy="9" r="2.6"/><path d="M16.5 14.6c2.4.1 4 1.6 4.5 4.4"/>',
  support: '<path d="M4.5 5.5h15v10.5H10l-5.5 4v-4h0z"/><path d="M8.5 9.5h7M8.5 12.5h4"/>',
  storage:
    '<ellipse cx="12" cy="6" rx="7" ry="2.8"/><path d="M5 6v12c0 1.5 3.1 2.8 7 2.8s7-1.3 7-2.8V6"/><path d="M5 12c0 1.5 3.1 2.8 7 2.8s7-1.3 7-2.8"/>',
  jobs: '<path d="M12 4v10M7.5 9.5 12 14l4.5-4.5M5 19.5h14"/>',
  reference:
    '<path d="M5.5 5.5A2 2 0 0 1 7.5 3.5h11v14h-11a2 2 0 0 0-2 2z"/><path d="M5.5 19.5a2 2 0 0 0 2 1h11v-3"/><path d="M9.5 8h5"/>',
  firstAid: '<rect x="3.5" y="3.5" width="17" height="17" rx="4.5"/><path d="M12 8v8M8 12h8"/>',
  system:
    '<rect x="4" y="4" width="16" height="7" rx="2"/><rect x="4" y="13" width="16" height="7" rx="2"/><path d="M8 7.5h.01M8 16.5h.01"/>',
  features: '<rect x="3" y="7" width="18" height="10" rx="5"/><circle cx="16" cy="12" r="2.8"/>',
  appUpdate:
    '<rect x="6" y="2.5" width="12" height="19" rx="3"/><path d="M12 15V8.5M9.2 11.3 12 8.5l2.8 2.8M10.5 18.5h3"/>',
  staff:
    '<path d="M12 3.5 19 6.5v5c0 4.3-2.9 7.6-7 9-4.1-1.4-7-4.7-7-9v-5z"/><path d="m9.3 12 2 2 3.5-4"/>',
  audit: '<path d="M9 6h11M9 12h11M9 18h11M4.5 6h.01M4.5 12h.01M4.5 18h.01"/>',
  qa: '<rect x="3.5" y="3.5" width="17" height="17" rx="4.5"/><path d="m8.2 12.2 2.6 2.6 5-5.6"/>',
  collapse: '<path d="M14.5 6.5 9 12l5.5 5.5"/><path d="M19.5 5v14"/>',
  expand: '<path d="M9.5 6.5 15 12l-5.5 5.5"/><path d="M4.5 5v14"/>',
};

export function NavIcon({ name }: { name: keyof typeof paths }) {
  return (
    <svg
      className="sidebar__icon"
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      // Static markup from the table above.
      dangerouslySetInnerHTML={{ __html: paths[name] }}
    />
  );
}
