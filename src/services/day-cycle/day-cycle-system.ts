/**
 * DayCycleSystem — manages the multi-week career rhythm.
 *
 * Structure (post S4-1):
 *   1 career = N weeks (per JobConfig.weeksPerCareer, default 4)
 *   1 week   = 5 days (DAYS_PER_WEEK, fixed)
 *   1 day    = M events (EVENTS_PER_DAY[day-1])
 *
 * Events emitted:
 *   onDayStarted        — every day start (carries weekIndex)
 *   onEventCompleted    — every event resolve
 *   onDayEnded          — day's last event resolved (carries salary + weekIndex)
 *   onWeekCompleted     — week's last day ended; used for weekly review hooks
 *                          (status tick still fires from onDayEnded as before)
 *   onCareerCompleted   — last week's last day ended; RunManager subscribes
 *                          here to trigger SETTLING (was onWeekCompleted pre-S4-1)
 */

import { TypedEventEmitter } from '../common/event-emitter'
import {
  DAYS_PER_WEEK,
  EVENTS_PER_DAY,
  DAY_SALARIES,
  DEFAULT_WEEKS_PER_CAREER,
  type DayProgress
} from '@/types/day-cycle'

export class DayCycleSystem {
  private day = 1                // 1..DAYS_PER_WEEK
  private weekIndex = 1          // 1..weeksPerCareer
  private weeksPerCareer = DEFAULT_WEEKS_PER_CAREER
  private done = 0

  readonly onDayStarted = new TypedEventEmitter<{
    day: number
    weekIndex: number
    total: number
  }>()
  readonly onEventCompleted = new TypedEventEmitter<{
    done: number
    total: number
  }>()
  readonly onDayEnded = new TypedEventEmitter<{
    day: number
    weekIndex: number
    salary: number
  }>()
  readonly onWeekCompleted = new TypedEventEmitter<{
    weekIndex: number
    weekSalary: number
  }>()
  readonly onCareerCompleted = new TypedEventEmitter<{
    weeksCompleted: number
    careerTotalSalary: number
  }>()

  /**
   * Configure the career length for this run. Call BEFORE startWeek/startDay
   * on a fresh run. Resets internal counters (defensive — call site usually
   * follows with startWeek(1)/startDay(1)).
   */
  configure(weeksPerCareer: number): void {
    if (weeksPerCareer < 1) {
      throw new Error(`weeksPerCareer must be ≥ 1, got ${weeksPerCareer}`)
    }
    this.weeksPerCareer = weeksPerCareer
    this.weekIndex = 1
    this.day = 1
    this.done = 0
  }

  /**
   * Advance to a specific week. Resets day counter to 1.
   * Throws if weekIndex is outside [1, weeksPerCareer].
   */
  startWeek(weekIndex: number): void {
    if (weekIndex < 1 || weekIndex > this.weeksPerCareer) {
      throw new Error(
        `week out of range: ${weekIndex} (career length ${this.weeksPerCareer})`
      )
    }
    this.weekIndex = weekIndex
    this.day = 1
    this.done = 0
  }

  startDay(day: number): void {
    if (day < 1 || day > DAYS_PER_WEEK) {
      throw new Error(`day out of range: ${day}`)
    }
    this.day = day
    this.done = 0
    this.onDayStarted.emit({
      day,
      weekIndex: this.weekIndex,
      total: this.getTotalToday()
    })
  }

  eventCompleted(): void {
    this.done++
    this.onEventCompleted.emit({
      done: this.done,
      total: this.getTotalToday()
    })

    if (this.done >= this.getTotalToday()) {
      const salary = DAY_SALARIES[this.day - 1] ?? 0
      this.onDayEnded.emit({
        day: this.day,
        weekIndex: this.weekIndex,
        salary
      })
      if (this.day >= DAYS_PER_WEEK) {
        const weekSalary = DAY_SALARIES.reduce((a, b) => a + b, 0)
        this.onWeekCompleted.emit({
          weekIndex: this.weekIndex,
          weekSalary
        })
        if (this.weekIndex >= this.weeksPerCareer) {
          this.onCareerCompleted.emit({
            weeksCompleted: this.weekIndex,
            careerTotalSalary: weekSalary * this.weekIndex
          })
        }
      }
    }
  }

  // ============== Query ==============

  getCurrentDay(): number {
    return this.day
  }

  getWeekIndex(): number {
    return this.weekIndex
  }

  getWeeksPerCareer(): number {
    return this.weeksPerCareer
  }

  getProgress(): DayProgress {
    return {
      day: this.day,
      weekIndex: this.weekIndex,
      done: this.done,
      total: this.getTotalToday()
    }
  }

  isLastDay(): boolean {
    return this.day === DAYS_PER_WEEK
  }

  isLastWeek(): boolean {
    return this.weekIndex === this.weeksPerCareer
  }

  reset(): void {
    this.day = 1
    this.weekIndex = 1
    this.done = 0
  }

  private getTotalToday(): number {
    return EVENTS_PER_DAY[this.day - 1] ?? 0
  }
}
