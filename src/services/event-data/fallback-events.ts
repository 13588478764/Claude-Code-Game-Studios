/**
 * Hardcoded fallback events — used when JSON load fails after retries.
 * Keeps the game playable even with broken network/asset.
 */

import type { EventCard } from '@/types/event'

export const FALLBACK_EVENTS: EventCard[] = [
  {
    id: 'fallback-001',
    text: '今天网络不太好，所以你只能凭意志撑过去。',
    weight: 1,
    choiceA: {
      text: '硬撑',
      icon: '💪',
      effects: [{ target: 'energy', value: -10 }]
    },
    choiceB: {
      text: '摆烂',
      icon: '🐟',
      effects: [{ target: 'mood', value: -5 }]
    }
  },
  {
    id: 'fallback-002',
    text: '老板今天心情不错（疑似），路过你工位时点了点头。',
    weight: 1,
    choiceA: {
      text: '回笑一下',
      icon: '😊',
      effects: [{ target: 'mood', value: 5 }]
    },
    choiceB: {
      text: '装作没看见',
      icon: '🙃',
      effects: [{ target: 'mood', value: -3 }]
    }
  },
  {
    id: 'fallback-003',
    text: '同事请你帮忙调一个 bug。说"很简单的"。',
    weight: 1,
    choiceA: {
      text: '帮忙',
      icon: '🤝',
      effects: [{ target: 'energy', value: -10 }, { target: 'mood', value: 3 }]
    },
    choiceB: {
      text: '推掉',
      icon: '🙅',
      effects: [{ target: 'mood', value: -5 }]
    }
  },
  {
    id: 'fallback-004',
    text: '午休时间快到了。但你的 PR 还没合。',
    weight: 1,
    choiceA: {
      text: '合完再吃',
      icon: '⏱️',
      effects: [{ target: 'energy', value: -8 }, { target: 'money', value: 5 }]
    },
    choiceB: {
      text: '先去吃饭',
      icon: '🍱',
      effects: [{ target: 'energy', value: 8 }, { target: 'mood', value: 5 }]
    }
  },
  {
    id: 'fallback-005',
    text: '快下班了，老板突然路过说"今晚加个班吧"。',
    weight: 1,
    choiceA: {
      text: '加班',
      icon: '🌙',
      effects: [{ target: 'energy', value: -20 }, { target: 'money', value: 15 }]
    },
    choiceB: {
      text: '婉拒',
      icon: '🚪',
      effects: [{ target: 'mood', value: 5 }, { target: 'money', value: -5 }]
    }
  }
]
