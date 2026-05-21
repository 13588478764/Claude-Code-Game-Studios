/**
 * Vitest global setup — stubs uni-app modules that aren't compatible with
 * happy-dom (specifically the page lifecycle hooks that call vue.injectHook
 * with a runtime that doesn't exist outside the uni-app build pipeline).
 *
 * Page-level hooks like onUnload / onShow are no-ops in tests; pages that
 * rely on these for behavior should expose alternate test seams.
 */

import { vi } from 'vitest'

vi.mock('@dcloudio/uni-app', () => ({
  onLaunch: () => {},
  onShow: () => {},
  onHide: () => {},
  onLoad: () => {},
  onReady: () => {},
  onUnload: () => {},
  onPullDownRefresh: () => {},
  onReachBottom: () => {},
  onShareAppMessage: () => {},
  onPageScroll: () => {},
  onResize: () => {},
  onTabItemTap: () => {},
  onError: () => {}
}))
