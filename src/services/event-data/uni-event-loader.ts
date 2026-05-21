/**
 * UniEventLoader — concrete EventLoader using uni file APIs.
 * Falls back to fetch() in non-uni environments (web preview / tests).
 */

import type { EventLoader } from './event-data-engine'

const COMMON_PATH = '/subpackages/events/common-events.json'
const JOB_PATH_PREFIX = '/subpackages/events/'

async function loadJson(path: string): Promise<unknown> {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const u = (globalThis as any).uni
  if (u && typeof u.request === 'function') {
    return await new Promise((resolve, reject) => {
      u.request({
        url: path,
        method: 'GET',
        success: (res: { statusCode: number; data: unknown }) => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(res.data)
          } else {
            reject(new Error(`HTTP ${res.statusCode}`))
          }
        },
        fail: (err: { errMsg: string }) => reject(new Error(err.errMsg))
      })
    })
  }
  // Web/test fallback
  if (typeof fetch === 'function') {
    const res = await fetch(path)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    return await res.json()
  }
  throw new Error('no loader available')
}

export class UniEventLoader implements EventLoader {
  loadCommon(): Promise<unknown> {
    return loadJson(COMMON_PATH)
  }
  loadJob(jobId: string): Promise<unknown> {
    return loadJson(`${JOB_PATH_PREFIX}${jobId}-events.json`)
  }
}
