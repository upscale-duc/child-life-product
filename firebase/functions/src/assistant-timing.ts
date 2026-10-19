/**
 * Lumi L2 (D-088 §4.4, §8 "time to card p50 / p95"): per-hop timings of one task, in milliseconds.
 * The log line carries hop names, durations, the path taken and the task id only — never the
 * message, a draft, a record or anything about the child (CLAUDE.md security).
 */
export class HopTimer {
  private readonly started: number;
  private last: number;
  readonly hops: Record<string, number> = {};

  constructor(private readonly clock: () => number = () => performance.now()) {
    this.started = clock();
    this.last = this.started;
  }

  /** Closes the hop that ran since the previous mark (repeated names add up). */
  mark(hop: string): void {
    const now = this.clock();
    this.hops[hop] = Math.round((this.hops[hop] ?? 0) + (now - this.last));
    this.last = now;
  }

  /** Runs [work] as one hop. */
  async time<T>(hop: string, work: () => Promise<T>): Promise<T> {
    this.mark('_gap');
    try {
      return await work();
    } finally {
      this.mark(hop);
    }
  }

  total(): number {
    return Math.round(this.clock() - this.started);
  }

  /** The log payload: hops (gaps dropped when tiny), the total, and labels the caller adds. */
  payload(labels: Record<string, string | number | boolean | null>): Record<string, unknown> {
    const hops = Object.fromEntries(
      Object.entries(this.hops).filter(([k, v]) => k !== '_gap' || v >= 5),
    );
    return { ...labels, hops, totalMs: this.total() };
  }
}
