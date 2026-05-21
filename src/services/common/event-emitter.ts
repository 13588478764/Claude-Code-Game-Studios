/**
 * TypedEventEmitter — type-safe pub/sub for the Service layer.
 * See ADR-001 for rationale.
 */

export type Handler<T> = (payload: T) => void

export class TypedEventEmitter<T> {
  private handlers: Set<Handler<T>> = new Set()

  on(handler: Handler<T>): void {
    this.handlers.add(handler)
  }

  off(handler: Handler<T>): void {
    this.handlers.delete(handler)
  }

  once(handler: Handler<T>): void {
    const wrapper: Handler<T> = (payload) => {
      this.handlers.delete(wrapper)
      handler(payload)
    }
    this.handlers.add(wrapper)
  }

  emit(payload: T): void {
    // Snapshot to avoid concurrent modification during emit
    const snapshot = Array.from(this.handlers)
    for (const handler of snapshot) {
      try {
        handler(payload)
      } catch (err) {
        // Don't let one bad handler block others
        console.error('[TypedEventEmitter] handler threw:', err)
      }
    }
  }

  clear(): void {
    this.handlers.clear()
  }

  get size(): number {
    return this.handlers.size
  }
}
