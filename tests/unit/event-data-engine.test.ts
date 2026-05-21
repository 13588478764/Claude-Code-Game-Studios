import { describe, test, expect, vi } from 'vitest'
import { EventDataEngine, type EventLoader } from '@/services/event-data/event-data-engine'
import { FALLBACK_EVENTS } from '@/services/event-data/fallback-events'
import type { EventCard } from '@/types/event'

function mkEvent(id: string, weight = 1, tags?: string[]): EventCard {
  return {
    id,
    text: 'event ' + id,
    weight,
    tags,
    choiceA: { text: 'A', effects: [{ target: 'energy', value: -5 }] },
    choiceB: { text: 'B', effects: [{ target: 'mood', value: 5 }] }
  }
}

class StubLoader implements EventLoader {
  constructor(
    private commonData: unknown,
    private jobData: Record<string, unknown> = {},
    private commonFails = 0,
    private jobFails = 0
  ) {}
  async loadCommon() {
    if (this.commonFails-- > 0) throw new Error('network')
    return this.commonData
  }
  async loadJob(jobId: string) {
    if (this.jobFails-- > 0) throw new Error('network')
    return this.jobData[jobId] ?? null
  }
}

describe('EventDataEngine', () => {
  test('loadCommon() loads and validates events', async () => {
    const engine = new EventDataEngine(new StubLoader([mkEvent('c1'), mkEvent('c2')]))
    await engine.loadCommon()
    expect(engine.getCommonCount()).toBe(2)
  })

  test('loadJobEvents() loads from given path', async () => {
    const engine = new EventDataEngine(new StubLoader([], {
      programmer: [mkEvent('p1'), mkEvent('p2'), mkEvent('p3')]
    }))
    await engine.loadCommon()
    await engine.loadJobEvents('programmer')
    expect(engine.getJobCount('programmer')).toBe(3)
  })

  test('schema validation drops malformed events', async () => {
    const engine = new EventDataEngine(new StubLoader([
      mkEvent('good-1'),
      { id: '', text: 'no id' },  // invalid
      { id: 'bad', text: 'no choices' },  // invalid
      mkEvent('good-2')
    ]))
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    await engine.loadCommon()
    expect(engine.getCommonCount()).toBe(2)
    warn.mockRestore()
  })

  test('retries up to 3 times on network failure', async () => {
    const loader = new StubLoader([mkEvent('c1')], {}, 2)  // fail 2x then succeed
    const engine = new EventDataEngine(loader)
    await engine.loadCommon()
    expect(engine.getCommonCount()).toBe(1)
  })

  test('falls back to hardcoded events after retries exhausted', async () => {
    const engine = new EventDataEngine(new StubLoader([], {}, MAX_RETRIES_PLUS_ONE))
    const fn = vi.fn()
    engine.onLoadFailed.on(fn)
    await engine.loadCommon()
    expect(engine.getCommonCount()).toBe(FALLBACK_EVENTS.length)
    expect(fn).toHaveBeenCalled()
  })

  test('drawEvent() returns events from pool', async () => {
    const engine = new EventDataEngine(new StubLoader([mkEvent('c1')]))
    await engine.loadCommon()
    const ev = engine.drawEvent()
    expect(ev.id).toBe('c1')
  })

  test('drawEvent() avoids recently used events', async () => {
    const engine = new EventDataEngine(new StubLoader([
      mkEvent('a'), mkEvent('b'), mkEvent('c')
    ]))
    await engine.loadCommon()
    const drawn = new Set<string>()
    drawn.add(engine.drawEvent().id)
    drawn.add(engine.drawEvent().id)
    drawn.add(engine.drawEvent().id)
    expect(drawn.size).toBe(3)
  })

  test('drawEvent() respects weight distribution roughly', async () => {
    const engine = new EventDataEngine(new StubLoader([
      mkEvent('heavy', 10),
      mkEvent('light', 1)
    ]))
    await engine.loadCommon()
    const counts: Record<string, number> = { heavy: 0, light: 0 }
    for (let i = 0; i < 1000; i++) {
      const ev = engine.drawEvent()
      counts[ev.id] = (counts[ev.id] ?? 0) + 1
    }
    expect(counts.heavy! / counts.light!).toBeGreaterThan(3)
  })

  test('unload() clears job-specific events', async () => {
    const engine = new EventDataEngine(new StubLoader([], {
      programmer: [mkEvent('p1')]
    }))
    await engine.loadCommon()
    await engine.loadJobEvents('programmer')
    engine.unload()
    expect(engine.getJobCount('programmer')).toBe(0)
  })

  test('emit onLoadComplete with event count', async () => {
    const engine = new EventDataEngine(new StubLoader([mkEvent('c1'), mkEvent('c2')]))
    const fn = vi.fn()
    engine.onLoadComplete.on(fn)
    await engine.loadCommon()
    expect(fn).toHaveBeenCalledWith({ jobId: 'common', count: 2 })
  })

  test('emit onLoadFailed with reason on permanent failure', async () => {
    const engine = new EventDataEngine(new StubLoader([], {}, MAX_RETRIES_PLUS_ONE))
    const fn = vi.fn()
    engine.onLoadFailed.on(fn)
    await engine.loadCommon()
    expect(fn).toHaveBeenCalledWith(expect.objectContaining({
      jobId: 'common',
      reason: expect.any(String)
    }))
  })

  test('getEventById() finds events in either pool', async () => {
    const engine = new EventDataEngine(new StubLoader([mkEvent('c1')], {
      programmer: [mkEvent('p1')]
    }))
    await engine.loadCommon()
    await engine.loadJobEvents('programmer')
    expect(engine.getEventById('c1')?.id).toBe('c1')
    expect(engine.getEventById('p1')?.id).toBe('p1')
    expect(engine.getEventById('nope')).toBeNull()
  })

  test('drawEvent() filters by tag', async () => {
    const engine = new EventDataEngine(new StubLoader([
      mkEvent('a', 1, ['urgent']),
      mkEvent('b', 1, ['casual']),
      mkEvent('c', 1, ['urgent'])
    ]))
    await engine.loadCommon()
    const drawn: string[] = []
    for (let i = 0; i < 50; i++) {
      drawn.push(engine.drawEvent({ tags: ['urgent'] }).id)
    }
    expect(drawn.every(id => id === 'a' || id === 'c')).toBe(true)
  })

  // M-1: pool-level integration of conditions. drawEvent excludes cards
  // whose conditions fail against the supplied context.
  test('drawEvent() excludes cards whose conditions fail against context', async () => {
    const lateGameCard: EventCard = {
      ...mkEvent('crisis'),
      conditions: [{ type: 'minWeek', value: 3 }]
    }
    const alwaysCard = mkEvent('always')
    const engine = new EventDataEngine(new StubLoader([lateGameCard, alwaysCard]))
    await engine.loadCommon()

    // Week 1 — only 'always' should be available
    const drawnEarly: string[] = []
    for (let i = 0; i < 30; i++) {
      drawnEarly.push(engine.drawEvent({ context: { weekIndex: 1 } }).id)
    }
    expect(drawnEarly.every(id => id === 'always')).toBe(true)

    // Week 3 — both eligible
    const drawnLate = new Set<string>()
    for (let i = 0; i < 60; i++) {
      drawnLate.add(engine.drawEvent({ context: { weekIndex: 3 } }).id)
    }
    expect(drawnLate.has('crisis')).toBe(true)
    expect(drawnLate.has('always')).toBe(true)
  })

  test('drawEvent() with no context falls back to ignoring conditions (back-compat)', async () => {
    const conditionalCard: EventCard = {
      ...mkEvent('rare'),
      conditions: [{ type: 'minMoney', value: 1000 }]
    }
    const engine = new EventDataEngine(new StubLoader([conditionalCard]))
    await engine.loadCommon()

    // No context → conditions ignored → 'rare' returnable
    const drawn = engine.drawEvent()
    expect(drawn.id).toBe('rare')
  })

  test('drawEvent() multi-condition card requires ALL conditions pass', async () => {
    const card: EventCard = {
      ...mkEvent('multi'),
      conditions: [
        { type: 'minWeek', value: 2 },
        { type: 'maxHealth', value: 30 }
      ]
    }
    const fallback = mkEvent('fallback')
    const engine = new EventDataEngine(new StubLoader([card, fallback]))
    await engine.loadCommon()

    // Week 2 but health=80 → fails health condition
    const result1 = engine.drawEvent({ context: { weekIndex: 2, health: 80 } })
    expect(result1.id).toBe('fallback')

    // Week 1 but health=20 → fails week condition
    const result2 = engine.drawEvent({ context: { weekIndex: 1, health: 20 } })
    expect(result2.id).toBe('fallback')

    // Both pass → either possible
    const drawn = new Set<string>()
    for (let i = 0; i < 40; i++) {
      drawn.add(engine.drawEvent({ context: { weekIndex: 2, health: 20 } }).id)
    }
    expect(drawn.has('multi')).toBe(true)
  })
})

const MAX_RETRIES_PLUS_ONE = 4  // enough to ensure all retries fail
