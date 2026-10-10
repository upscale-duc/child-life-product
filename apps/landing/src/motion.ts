/** Scroll reveal (Motion spec: motion.gentle, stagger 30 ms, max 6). Elements reveal once. */
export function startReveal(root: ParentNode = document): () => void {
  const targets = Array.from(root.querySelectorAll<HTMLElement>('.reveal'));
  if (
    !('IntersectionObserver' in window) ||
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  ) {
    targets.forEach((el) => el.classList.add('is-visible'));
    return () => undefined;
  }
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    },
    { rootMargin: '0px 0px -10% 0px', threshold: 0.12 },
  );
  targets.forEach((el) => observer.observe(el));
  return () => observer.disconnect();
}

/** Applies --stagger indices (0–5) to an element's direct children marked `.reveal`. */
export function staggerStyle(index: number): React.CSSProperties {
  return { ['--stagger' as string]: Math.min(index, 5) } as React.CSSProperties;
}
