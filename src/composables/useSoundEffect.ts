/**
 * useSoundEffect — thin wrapper over uni.createInnerAudioContext.
 *
 * Provides a play(name) API that resolves a name → audio file path under
 * /static/audio/, plays once, and gracefully no-ops if uni audio is
 * unavailable (web preview without static assets, missing MP3 file, system
 * silent mode, reduced-motion preference, etc.).
 *
 * Audio assets are NOT bundled in this repository — drop CC0 short-form
 * MP3s into `src/static/audio/` named per the SoundName enum below.
 * Until the files exist, calls log "[useSoundEffect] missing: <name>"
 * once per name and continue silently.
 *
 * AC-6 (silent mode) is honored implicitly: uni.createInnerAudioContext
 * obeys system silent mode. AC-7 (reduced motion / no audio preference)
 * is best-effort — if uni.getSystemInfoSync exposes prefers-reduced-motion
 * we skip playback.
 */

export type SoundName = 'click' | 'day-end' | 'death' | 'win' | 'unlock'

const AUDIO_PATH: Record<SoundName, string> = {
  click: '/static/audio/click.mp3',
  'day-end': '/static/audio/day-end.mp3',
  death: '/static/audio/death.mp3',
  win: '/static/audio/win.mp3',
  unlock: '/static/audio/unlock.mp3'
}

const warned = new Set<SoundName>()
let reducedMotionCached: boolean | null = null

function prefersReducedMotion(): boolean {
  if (reducedMotionCached !== null) return reducedMotionCached
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const u = (globalThis as any).uni
  try {
    if (u && typeof u.getSystemInfoSync === 'function') {
      const info = u.getSystemInfoSync()
      // uni-app cross-platform field. mp-weixin uses theme; web uses prefers-reduced-motion.
      if (info && info.theme === 'reducedMotion') {
        reducedMotionCached = true
        return true
      }
      if (info && info.enableAccessibility === true) {
        // Heuristic: if accessibility is on, prefer to also reduce sfx.
        reducedMotionCached = true
        return true
      }
    }
  } catch {
    /* ignore — best-effort */
  }
  reducedMotionCached = false
  return false
}

export function useSoundEffect() {
  function play(name: SoundName): void {
    if (prefersReducedMotion()) return
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const u = (globalThis as any).uni
    if (!u || typeof u.createInnerAudioContext !== 'function') return

    try {
      const audio = u.createInnerAudioContext()
      audio.src = AUDIO_PATH[name]
      audio.autoplay = true
      audio.onError(() => {
        if (!warned.has(name)) {
          warned.add(name)
          console.info(`[useSoundEffect] missing or unplayable: ${name}`)
        }
        try { audio.destroy() } catch { /* ignore */ }
      })
      audio.onEnded(() => {
        try { audio.destroy() } catch { /* ignore */ }
      })
    } catch (err) {
      if (!warned.has(name)) {
        warned.add(name)
        console.info(`[useSoundEffect] uni audio failed: ${name}`, err)
      }
    }
  }

  return { play }
}

/** Test seam — clears the "warned once" cache so unit tests can assert behavior cleanly. */
export function _resetSoundEffectState(): void {
  warned.clear()
  reducedMotionCached = null
}
