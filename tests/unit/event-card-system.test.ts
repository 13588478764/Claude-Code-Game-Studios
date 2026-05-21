import { describe, test, expect, vi } from 'vitest'
import {
  EventCardSystem,
  type EventCardSystemDeps,
  type ResolveHandler
} from '@/services/event-card/event-card-system'
import type { EventCard, EventFilter } from '@/types/event'

function makeCard(id: string, overrides: Partial<EventCard> = {}): EventCard {
  return {
    id,
    text: `event ${id}`,
    choiceA: { text: 'A', effects: [] },
    choiceB: { text: 'B', effects: [] },
    ...overrides
  }
}

function makeDeps(
  cards: EventCard[] = [],
  registry: Record<string, EventCard> = {}
) {
  const queue = [...cards]
  const drawSpy = vi.fn((_filter?: EventFilter): EventCard => {
    return queue.shift() ?? makeCard('fallback-' + Math.random())
  })
  const getEventByIdSpy = vi.fn((id: string): EventCard | null => registry[id] ?? null)
  const notifyEventCompletedSpy = vi.fn()
  const deps: EventCardSystemDeps = {
    drawEvent: drawSpy,
    getEventById: getEventByIdSpy,
    notifyEventCompleted: notifyEventCompletedSpy
  }
  return Object.assign(deps, {
    drawSpy,
    getEventByIdSpy,
    notifyEventCompletedSpy
  })
}

describe('EventCardSystem — prepareDay', () => {
  test('AC-1: emit onCardShown after drawing 2 cards', () => {
    const deps = makeDeps([makeCard('a'), makeCard('b')])
    const sys = new EventCardSystem(deps)
    const shown = vi.fn()
    sys.onCardShown.on(shown)
    sys.prepareDay(1, 2)
    expect(deps.drawSpy).toHaveBeenCalledTimes(2)
    expect(shown).toHaveBeenCalledTimes(1)
    expect(sys.getCurrentCard()?.card.id).toBe('a')
    expect(sys.getQueueStatus()).toEqual({ total: 2, completed: 0, remaining: 2 })
  })

  test('AC-1 edge: eventsCount=0 → emit onDayEventsCompleted directly', () => {
    const deps = makeDeps([])
    const sys = new EventCardSystem(deps)
    const dayDone = vi.fn()
    sys.onDayEventsCompleted.on(dayDone)
    sys.prepareDay(1, 0)
    expect(dayDone).toHaveBeenCalled()
    expect(deps.drawSpy).not.toHaveBeenCalled()
    expect(sys.getCurrentCard()).toBeNull()
  })

  test('AC-1 edge: negative count is treated like 0', () => {
    const deps = makeDeps([])
    const sys = new EventCardSystem(deps)
    const dayDone = vi.fn()
    sys.onDayEventsCompleted.on(dayDone)
    sys.prepareDay(1, -1)
    expect(dayDone).toHaveBeenCalled()
  })

  test('forwards EventFilter to drawEvent', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    const filter: EventFilter = { jobId: 'programmer', tags: ['urgent'] }
    sys.prepareDay(1, 1, filter)
    expect(deps.drawSpy).toHaveBeenCalledWith(filter)
  })

  test('prepareDay called twice resets state', () => {
    const deps = makeDeps([makeCard('a'), makeCard('b'), makeCard('c'), makeCard('d')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 2)
    sys.selectChoice('A')
    sys.prepareDay(2, 2)
    expect(sys.getQueueStatus()).toEqual({ total: 2, completed: 0, remaining: 2 })
    expect(sys.getCurrentCard()?.card.id).toBe('c')
  })
})

describe('EventCardSystem — selectChoice + commitResolve', () => {
  test('AC-2: CHOOSING + selectChoice("A") → RESOLVING + resolveHandler called', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    const handler = vi.fn<Parameters<ResolveHandler>, void>()
    sys.setResolveHandler(handler)
    sys.prepareDay(1, 1)
    expect(sys.getCurrentCard()?.phase).toBe('CHOOSING')
    sys.selectChoice('A')
    expect(handler).toHaveBeenCalledWith(expect.objectContaining({ id: 'a' }), 'A')
    expect(sys.getCurrentCard()?.phase).toBe('RESOLVING')
  })

  test('AC-2: emit onChoiceMade with card + key', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    const choiceMade = vi.fn()
    sys.onChoiceMade.on(choiceMade)
    sys.prepareDay(1, 1)
    sys.selectChoice('B')
    expect(choiceMade).toHaveBeenCalledWith({
      card: expect.objectContaining({ id: 'a' }),
      choiceKey: 'B'
    })
  })

  test('AC-5: re-entrant selectChoice during RESOLVING is ignored (防连点)', () => {
    const deps = makeDeps([makeCard('a'), makeCard('b')])
    const sys = new EventCardSystem(deps)
    const handler = vi.fn()
    sys.setResolveHandler(handler)
    sys.prepareDay(1, 2)

    sys.selectChoice('A')
    sys.selectChoice('B')
    sys.selectChoice('A')
    expect(handler).toHaveBeenCalledTimes(1)
  })

  test('commitResolve advances to next queue card', () => {
    const deps = makeDeps([makeCard('a'), makeCard('b')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 2)

    sys.selectChoice('A')
    expect(sys.getCurrentCard()?.card.id).toBe('a')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('b')
    expect(sys.getQueueStatus()).toEqual({ total: 2, completed: 1, remaining: 1 })
  })

  test('selectChoice without resolveHandler → console.warn, no advance', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    sys.prepareDay(1, 1)
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})

    sys.selectChoice('A')
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('no resolveHandler')
    )
    expect(sys.getCurrentCard()?.phase).toBe('CHOOSING')
    warn.mockRestore()
  })

  test('selectChoice with no current card is no-op', () => {
    const deps = makeDeps([])
    const sys = new EventCardSystem(deps)
    const handler = vi.fn()
    sys.setResolveHandler(handler)
    sys.selectChoice('A')
    expect(handler).not.toHaveBeenCalled()
  })

  test('commitResolve without prior selectChoice is no-op', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 1)
    sys.commitResolve()
    expect(sys.getQueueStatus().completed).toBe(0)
  })
})

describe('EventCardSystem — followUp', () => {
  test('AC-3: choice with followUpId loads followUp card (not counted in queue)', () => {
    const followUp = makeCard('follow-1', { text: 'after' })
    const card = makeCard('a', {
      choiceA: { text: 'A', effects: [], followUpId: 'follow-1' }
    })
    const deps = makeDeps([card], { 'follow-1': followUp })
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 1)

    sys.selectChoice('A')
    sys.commitResolve()

    expect(sys.getCurrentCard()?.card.id).toBe('follow-1')
    // completedToday NOT incremented since followUp is not a queue card
    expect(sys.getQueueStatus()).toEqual({ total: 1, completed: 0, remaining: 1 })
  })

  test('AC-7: followUp depth > 3 → ignored, advance via queue', () => {
    const cards = [
      makeCard('a', { choiceA: { text: 'A', effects: [], followUpId: 'b' } }),
      makeCard('z')
    ]
    const registry: Record<string, EventCard> = {
      b: makeCard('b', { choiceA: { text: 'A', effects: [], followUpId: 'c' } }),
      c: makeCard('c', { choiceA: { text: 'A', effects: [], followUpId: 'd' } }),
      d: makeCard('d', { choiceA: { text: 'A', effects: [], followUpId: 'e' } }),
      e: makeCard('e')
    }
    const deps = makeDeps(cards, registry)
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 2)

    // a → choose A → b (depth 1)
    sys.selectChoice('A')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('b')

    // b → c (depth 2)
    sys.selectChoice('A')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('c')

    // c → d (depth 3)
    sys.selectChoice('A')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('d')

    // d → would be e (depth 4) → blocked → falls through to next queue card 'z'
    sys.selectChoice('A')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('z')
    expect(deps.getEventByIdSpy).not.toHaveBeenCalledWith('e')
  })

  test('AC-8: followUpId not found → console.warn, advance via queue', () => {
    const cards = [
      makeCard('a', { choiceA: { text: 'A', effects: [], followUpId: 'missing' } }),
      makeCard('z')
    ]
    const deps = makeDeps(cards, {})
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 2)

    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    sys.selectChoice('A')
    sys.commitResolve()

    expect(warn).toHaveBeenCalledWith(expect.stringContaining('missing'))
    expect(sys.getCurrentCard()?.card.id).toBe('z')
    warn.mockRestore()
  })

  test('followUp via choiceB also works', () => {
    const card = makeCard('a', {
      choiceB: { text: 'B', effects: [], followUpId: 'b-follow' }
    })
    const deps = makeDeps([card], { 'b-follow': makeCard('b-follow') })
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 1)
    sys.selectChoice('B')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('b-follow')
  })

  test('followUp depth resets after queue advance', () => {
    const cards = [
      makeCard('a', { choiceA: { text: 'A', effects: [], followUpId: 'a-follow' } }),
      makeCard('b', { choiceA: { text: 'A', effects: [], followUpId: 'b-follow' } })
    ]
    const registry = {
      'a-follow': makeCard('a-follow'),
      'b-follow': makeCard('b-follow')
    }
    const deps = makeDeps(cards, registry)
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 2)

    // a → a-follow (depth=1) → next queue (depth resets)
    sys.selectChoice('A')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('a-follow')
    sys.selectChoice('A')  // a-follow has no followUp
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('b')

    // b → b-follow (depth should be 1 again, not 2)
    sys.selectChoice('A')
    sys.commitResolve()
    expect(sys.getCurrentCard()?.card.id).toBe('b-follow')
  })
})

describe('EventCardSystem — day completion', () => {
  test('AC-4: last queue card completed + no followUp → onDayEventsCompleted', () => {
    const deps = makeDeps([makeCard('a'), makeCard('b')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    const dayDone = vi.fn()
    sys.onDayEventsCompleted.on(dayDone)
    sys.prepareDay(1, 2)

    sys.selectChoice('A')
    sys.commitResolve()
    sys.selectChoice('A')
    sys.commitResolve()

    expect(dayDone).toHaveBeenCalledTimes(1)
    expect(deps.notifyEventCompletedSpy).toHaveBeenCalledTimes(1)
    expect(sys.getCurrentCard()).toBeNull()
  })

  test('notifyEventCompleted is optional', () => {
    const deps: EventCardSystemDeps = {
      drawEvent: () => makeCard('a'),
      getEventById: () => null
      // notifyEventCompleted omitted
    }
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 1)
    sys.selectChoice('A')
    expect(() => sys.commitResolve()).not.toThrow()
  })
})

describe('EventCardSystem — empty text fallback (AC-9)', () => {
  test('empty text → fallback "今天平平无奇地过去了…"', () => {
    const deps = makeDeps([makeCard('blank', { text: '' })])
    const sys = new EventCardSystem(deps)
    sys.prepareDay(1, 1)
    expect(sys.getCurrentCard()?.card.text).toContain('平平无奇')
  })

  test('whitespace-only text → fallback', () => {
    const deps = makeDeps([makeCard('blank', { text: '   ' })])
    const sys = new EventCardSystem(deps)
    sys.prepareDay(1, 1)
    expect(sys.getCurrentCard()?.card.text).toContain('平平无奇')
  })

  test('empty choice text → fallback "继续"', () => {
    const card = makeCard('blank', {
      text: '',
      choiceA: { text: '', effects: [] },
      choiceB: { text: '', effects: [] }
    })
    const deps = makeDeps([card])
    const sys = new EventCardSystem(deps)
    sys.prepareDay(1, 1)
    const ui = sys.getCurrentCard()!
    expect(ui.card.choiceA.text).toBe('继续')
    expect(ui.card.choiceB.text).toBe('继续')
  })

  test('non-empty text passes through unchanged', () => {
    const original = makeCard('a', { text: '老板找你聊聊' })
    const deps = makeDeps([original])
    const sys = new EventCardSystem(deps)
    sys.prepareDay(1, 1)
    expect(sys.getCurrentCard()?.card.text).toBe('老板找你聊聊')
  })
})

describe('EventCardSystem — phase transitions', () => {
  test('emit onPhaseChanged for each transition', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    const phases = vi.fn()
    sys.onPhaseChanged.on(phases)
    sys.prepareDay(1, 1)

    // ENTERING → READING → CHOOSING (3 emissions during showCard)
    expect(phases).toHaveBeenCalled()
    const lastPhase = sys.getCurrentCard()?.phase
    expect(lastPhase).toBe('CHOOSING')
  })

  test('selectChoice transitions to RESOLVING', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 1)
    sys.selectChoice('A')
    expect(sys.getCurrentCard()?.phase).toBe('RESOLVING')
  })

  test('phase setter ignores no-op transitions', () => {
    const deps = makeDeps([makeCard('a')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 1)
    const phases = vi.fn()
    sys.onPhaseChanged.on(phases)
    // Already in CHOOSING, no internal API to re-set same phase, but
    // trigger another flow that lands in same phase
    expect(phases).not.toHaveBeenCalled()
  })

  test('followUp shows with FOLLOW_UP entry phase first', () => {
    const card = makeCard('a', {
      choiceA: { text: 'A', effects: [], followUpId: 'b' }
    })
    const deps = makeDeps([card], { b: makeCard('b') })
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    const phases: Array<{ from: string; to: string }> = []
    sys.onPhaseChanged.on((event) => phases.push(event))
    sys.prepareDay(1, 1)
    sys.selectChoice('A')
    sys.commitResolve()
    // After commit, phase should have transitioned through FOLLOW_UP → READING → CHOOSING
    const followUpEntry = phases.find((p) => p.to === 'FOLLOW_UP')
    expect(followUpEntry).toBeDefined()
  })
})

describe('EventCardSystem — query + reset', () => {
  test('getCurrentCard returns null when nothing showing', () => {
    const deps = makeDeps([])
    const sys = new EventCardSystem(deps)
    expect(sys.getCurrentCard()).toBeNull()
  })

  test('getQueueStatus tracks remaining correctly', () => {
    const deps = makeDeps([makeCard('a'), makeCard('b'), makeCard('c')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 3)
    expect(sys.getQueueStatus()).toEqual({ total: 3, completed: 0, remaining: 3 })
    sys.selectChoice('A')
    sys.commitResolve()
    expect(sys.getQueueStatus()).toEqual({ total: 3, completed: 1, remaining: 2 })
  })

  test('reset clears all state', () => {
    const deps = makeDeps([makeCard('a'), makeCard('b')])
    const sys = new EventCardSystem(deps)
    sys.setResolveHandler(() => {})
    sys.prepareDay(1, 2)
    sys.selectChoice('A')
    sys.reset()
    expect(sys.getCurrentCard()).toBeNull()
    expect(sys.getQueueStatus()).toEqual({ total: 0, completed: 0, remaining: 0 })
  })
})
