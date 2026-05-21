import { describe, test, expect, vi } from 'vitest'
import { DayCycleSystem } from '@/services/day-cycle/day-cycle-system'
import {
  EVENTS_PER_DAY,
  DAY_SALARIES,
  DEFAULT_WEEKS_PER_CAREER
} from '@/types/day-cycle'

describe('DayCycleSystem — single-week behavior (pre-S4-1 baseline)', () => {
  test('startDay() emits onDayStarted with day + weekIndex + total', () => {
    const dc = new DayCycleSystem()
    const fn = vi.fn()
    dc.onDayStarted.on(fn)
    dc.startDay(1)
    expect(fn).toHaveBeenCalledWith({
      day: 1,
      weekIndex: 1,
      total: EVENTS_PER_DAY[0]
    })
  })

  test('startDay() throws on out-of-range day', () => {
    const dc = new DayCycleSystem()
    expect(() => dc.startDay(0)).toThrow()
    expect(() => dc.startDay(6)).toThrow()
  })

  test('eventCompleted() emits onEventCompleted', () => {
    const dc = new DayCycleSystem()
    const fn = vi.fn()
    dc.onEventCompleted.on(fn)
    dc.startDay(1)
    dc.eventCompleted()
    expect(fn).toHaveBeenCalledWith({ done: 1, total: EVENTS_PER_DAY[0] })
  })

  test('day ends after total events completed', () => {
    const dc = new DayCycleSystem()
    const dayEnded = vi.fn()
    dc.onDayEnded.on(dayEnded)
    dc.startDay(1)
    for (let i = 0; i < EVENTS_PER_DAY[0]!; i++) {
      dc.eventCompleted()
    }
    expect(dayEnded).toHaveBeenCalledWith({
      day: 1,
      weekIndex: 1,
      salary: DAY_SALARIES[0]
    })
  })

  test('day 5 last event triggers onWeekCompleted with weekIndex + weekSalary', () => {
    const dc = new DayCycleSystem()
    const weekDone = vi.fn()
    dc.onWeekCompleted.on(weekDone)
    dc.startDay(5)
    for (let i = 0; i < EVENTS_PER_DAY[4]!; i++) {
      dc.eventCompleted()
    }
    expect(weekDone).toHaveBeenCalledWith({
      weekIndex: 1,
      weekSalary: DAY_SALARIES.reduce((a, b) => a + b, 0)
    })
  })

  test('getCurrentDay() returns current day', () => {
    const dc = new DayCycleSystem()
    expect(dc.getCurrentDay()).toBe(1)
    dc.startDay(3)
    expect(dc.getCurrentDay()).toBe(3)
  })

  test('getProgress() returns current progress including weekIndex', () => {
    const dc = new DayCycleSystem()
    dc.startDay(2)
    expect(dc.getProgress()).toEqual({
      day: 2,
      weekIndex: 1,
      done: 0,
      total: EVENTS_PER_DAY[1]
    })
    dc.eventCompleted()
    expect(dc.getProgress()).toEqual({
      day: 2,
      weekIndex: 1,
      done: 1,
      total: EVENTS_PER_DAY[1]
    })
  })

  test('isLastDay() returns true on day 5', () => {
    const dc = new DayCycleSystem()
    dc.startDay(4)
    expect(dc.isLastDay()).toBe(false)
    dc.startDay(5)
    expect(dc.isLastDay()).toBe(true)
  })

  test('reset() returns to day 1, week 1', () => {
    const dc = new DayCycleSystem()
    dc.startDay(4)
    dc.eventCompleted()
    dc.reset()
    expect(dc.getCurrentDay()).toBe(1)
    expect(dc.getWeekIndex()).toBe(1)
    expect(dc.getProgress().done).toBe(0)
  })
})

describe('DayCycleSystem — multi-week career (S4-1)', () => {
  test('default weeksPerCareer is DEFAULT_WEEKS_PER_CAREER (4)', () => {
    const dc = new DayCycleSystem()
    expect(dc.getWeeksPerCareer()).toBe(DEFAULT_WEEKS_PER_CAREER)
    expect(DEFAULT_WEEKS_PER_CAREER).toBe(4)
  })

  test('configure() sets weeksPerCareer + resets counters', () => {
    const dc = new DayCycleSystem()
    dc.startWeek(1)
    dc.startDay(3)
    dc.eventCompleted()
    dc.configure(6)
    expect(dc.getWeeksPerCareer()).toBe(6)
    expect(dc.getWeekIndex()).toBe(1)
    expect(dc.getCurrentDay()).toBe(1)
  })

  test('configure() throws when weeksPerCareer < 1', () => {
    const dc = new DayCycleSystem()
    expect(() => dc.configure(0)).toThrow()
    expect(() => dc.configure(-2)).toThrow()
  })

  test('startWeek() advances weekIndex + resets day to 1', () => {
    const dc = new DayCycleSystem()
    dc.startWeek(2)
    expect(dc.getWeekIndex()).toBe(2)
    expect(dc.getCurrentDay()).toBe(1)
  })

  test('startWeek() throws when weekIndex > weeksPerCareer', () => {
    const dc = new DayCycleSystem()
    dc.configure(3)
    expect(() => dc.startWeek(4)).toThrow()
    expect(() => dc.startWeek(0)).toThrow()
  })

  test('isLastWeek() reflects current week vs configured length', () => {
    const dc = new DayCycleSystem()
    dc.configure(3)
    dc.startWeek(2)
    expect(dc.isLastWeek()).toBe(false)
    dc.startWeek(3)
    expect(dc.isLastWeek()).toBe(true)
  })

  test('onDayStarted carries weekIndex correctly across weeks', () => {
    const dc = new DayCycleSystem()
    const fn = vi.fn()
    dc.onDayStarted.on(fn)
    dc.startWeek(3)
    dc.startDay(2)
    expect(fn).toHaveBeenCalledWith({
      day: 2,
      weekIndex: 3,
      total: EVENTS_PER_DAY[1]
    })
  })

  test('onWeekCompleted fires every week boundary, not just last', () => {
    const dc = new DayCycleSystem()
    dc.configure(3)
    const fn = vi.fn()
    dc.onWeekCompleted.on(fn)

    // Complete week 1
    dc.startWeek(1)
    dc.startDay(5)
    for (let i = 0; i < EVENTS_PER_DAY[4]!; i++) {
      dc.eventCompleted()
    }
    expect(fn).toHaveBeenCalledTimes(1)
    expect(fn).toHaveBeenLastCalledWith({
      weekIndex: 1,
      weekSalary: DAY_SALARIES.reduce((a, b) => a + b, 0)
    })

    // Complete week 2
    dc.startWeek(2)
    dc.startDay(5)
    for (let i = 0; i < EVENTS_PER_DAY[4]!; i++) {
      dc.eventCompleted()
    }
    expect(fn).toHaveBeenCalledTimes(2)
    expect(fn).toHaveBeenLastCalledWith({
      weekIndex: 2,
      weekSalary: DAY_SALARIES.reduce((a, b) => a + b, 0)
    })
  })

  test('onCareerCompleted fires only on last week boundary', () => {
    const dc = new DayCycleSystem()
    dc.configure(2)
    const careerFn = vi.fn()
    dc.onCareerCompleted.on(careerFn)

    // Week 1: should NOT fire onCareerCompleted
    dc.startWeek(1)
    dc.startDay(5)
    for (let i = 0; i < EVENTS_PER_DAY[4]!; i++) {
      dc.eventCompleted()
    }
    expect(careerFn).not.toHaveBeenCalled()

    // Week 2 (last): SHOULD fire onCareerCompleted
    dc.startWeek(2)
    dc.startDay(5)
    for (let i = 0; i < EVENTS_PER_DAY[4]!; i++) {
      dc.eventCompleted()
    }
    expect(careerFn).toHaveBeenCalledTimes(1)
    expect(careerFn).toHaveBeenCalledWith({
      weeksCompleted: 2,
      careerTotalSalary: DAY_SALARIES.reduce((a, b) => a + b, 0) * 2
    })
  })

  test('onCareerCompleted fires AFTER onWeekCompleted on last day of last week', () => {
    const dc = new DayCycleSystem()
    dc.configure(1)
    const order: string[] = []
    dc.onWeekCompleted.on(() => order.push('week'))
    dc.onCareerCompleted.on(() => order.push('career'))

    dc.startWeek(1)
    dc.startDay(5)
    for (let i = 0; i < EVENTS_PER_DAY[4]!; i++) {
      dc.eventCompleted()
    }
    expect(order).toEqual(['week', 'career'])
  })

  test('mid-week eventCompleted does NOT fire onWeekCompleted nor onCareerCompleted', () => {
    const dc = new DayCycleSystem()
    const weekFn = vi.fn()
    const careerFn = vi.fn()
    dc.onWeekCompleted.on(weekFn)
    dc.onCareerCompleted.on(careerFn)

    dc.startWeek(1)
    dc.startDay(2)  // mid-week
    for (let i = 0; i < EVENTS_PER_DAY[1]!; i++) {
      dc.eventCompleted()
    }
    expect(weekFn).not.toHaveBeenCalled()
    expect(careerFn).not.toHaveBeenCalled()
  })

  test('weeksPerCareer=1 — single-week career behaves like pre-S4-1', () => {
    const dc = new DayCycleSystem()
    dc.configure(1)
    const careerFn = vi.fn()
    dc.onCareerCompleted.on(careerFn)

    dc.startWeek(1)
    dc.startDay(5)
    for (let i = 0; i < EVENTS_PER_DAY[4]!; i++) {
      dc.eventCompleted()
    }
    expect(careerFn).toHaveBeenCalledTimes(1)
    expect(dc.isLastWeek()).toBe(true)
  })
})
