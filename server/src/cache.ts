/**
 * Tiny in-memory TTL cache for extraction results.
 * Stateless by design — survives only for the process lifetime.
 */

interface Entry<T> {
  value: T;
  expiresAt: number;
}

export class TtlCache<T> {
  private store = new Map<string, Entry<T>>();
  private readonly ttlMs: number;

  constructor(ttlSeconds: number) {
    this.ttlMs = ttlSeconds * 1000;
  }

  get(key: string): T | undefined {
    const entry = this.store.get(key);
    if (!entry) return undefined;
    if (Date.now() >= entry.expiresAt) {
      this.store.delete(key);
      return undefined;
    }
    return entry.value;
  }

  set(key: string, value: T): void {
    this.store.set(key, { value, expiresAt: Date.now() + this.ttlMs });
  }

  clear(): void {
    this.store.clear();
  }

  /** Periodic sweep — call on an interval to evict expired entries. */
  sweep(): void {
    const now = Date.now();
    for (const [k, v] of this.store.entries()) {
      if (now >= v.expiresAt) this.store.delete(k);
    }
  }
}
