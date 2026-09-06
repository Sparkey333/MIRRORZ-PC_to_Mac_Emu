/** Tiny in-memory token bucket keyed by client IP. Enough for a single-node deployment; swap for Redis behind a load balancer. */
export class RateLimiter {
  private readonly buckets = new Map<string, { tokens: number; updated: number }>();
  constructor(
    private readonly capacity: number,
    private readonly refillPerSec: number,
    private readonly clock: () => number = () => Date.now() / 1000,
  ) {}

  allow(key: string): boolean {
    const now = this.clock();
    const b = this.buckets.get(key) ?? { tokens: this.capacity, updated: now };
    b.tokens = Math.min(this.capacity, b.tokens + (now - b.updated) * this.refillPerSec);
    b.updated = now;
    if (b.tokens < 1) {
      this.buckets.set(key, b);
      return false;
    }
    b.tokens -= 1;
    this.buckets.set(key, b);
    if (this.buckets.size > 50_000) this.buckets.clear(); // crude memory bound
    return true;
  }
}
