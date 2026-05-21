/**
 * Job catalog — production data should be JSON, but Sprint 1 keeps it inline
 * to avoid build coupling. Migrate to jobs.json when localization needs it.
 */

import type { JobConfig } from '@/types/job'

export const JOBS: JobConfig[] = [
  {
    id: 'intern',
    name: '实习生',
    icon: '👶',
    description: '什么都不会，什么都得做。日薪低，但人人欺负但心情阈值更高。',
    salaryMul: 0.5,
    baseWeight: 1.0,
    eventPack: '/subpackages/events/intern-events.json',
    initialEnergy: 90,
    initialMood: 70,
    weeksPerCareer: 4,
    careerTitles: ['打杂实习生', '试用员工', '正式员工', '部门骨干']
  },
  {
    id: 'programmer',
    name: '程序员',
    icon: '💻',
    description: '代码改世界，但下班遥遥无期。',
    salaryMul: 2.0,
    baseWeight: 1.0,
    eventPack: '/subpackages/events/programmer-events.json',
    initialEnergy: 80,
    initialMood: 60,
    weeksPerCareer: 4,
    careerTitles: ['初级码农', '高级工程师', '架构师', '技术总监']
  },
  {
    id: 'sales',
    name: '销售',
    icon: '🤝',
    description: 'KPI 是生命，客户是上帝，提成是信仰。',
    salaryMul: 3.0,
    baseWeight: 1.0,
    unlockCondition: { type: 'wins', value: 1 },
    eventPack: '/subpackages/events/sales-events.json',
    initialEnergy: 75,
    initialMood: 55,
    weeksPerCareer: 4,
    careerTitles: ['销售助理', '客户经理', '大客户总监', '销售 VP']
  },
  {
    id: 'designer',
    name: '设计师',
    icon: '🎨',
    description: '能不能再大点？再红点？再 polish 一下？',
    salaryMul: 1.8,
    baseWeight: 1.0,
    unlockCondition: { type: 'totalMoney', value: 200 },
    eventPack: '/subpackages/events/designer-events.json',
    initialEnergy: 75,
    initialMood: 65,
    weeksPerCareer: 4,
    careerTitles: ['助理设计师', '资深设计师', '主创设计师', '创意总监']
  },
  {
    id: 'runner',
    name: '外卖员',
    icon: '🛵',
    description: '风里来雨里去，差评一刀致命。',
    salaryMul: 1.0,
    baseWeight: 1.0,
    unlockCondition: { type: 'deaths', value: 3 },
    eventPack: '/subpackages/events/runner-events.json',
    initialEnergy: 100,
    initialMood: 50,
    weeksPerCareer: 4,
    careerTitles: ['新手骑手', '黄金骑手', '单王', '站点站长']
  },
  {
    id: 'researcher',
    name: '科研狗',
    icon: '🔬',
    description: '论文 reject、实验失败、导师 push。一年里有 360 天在怀疑人生。',
    salaryMul: 0.7,
    baseWeight: 1.0,
    unlockCondition: { type: 'wins', value: 3 },
    eventPack: '/subpackages/events/researcher-events.json',
    initialEnergy: 70,
    initialMood: 55,
    weeksPerCareer: 4,
    careerTitles: ['助研小弟', '博士生', '博士后', '副教授']
  },
  {
    id: 'slacker',
    name: '摸鱼大师',
    icon: '🐟',
    description: '国企边缘部门。工作不重要，重要的是看起来很忙。',
    salaryMul: 1.5,
    baseWeight: 1.0,
    unlockCondition: { type: 'totalMoney', value: 500 },
    eventPack: '/subpackages/events/slacker-events.json',
    initialEnergy: 95,
    initialMood: 80,
    weeksPerCareer: 4,
    careerTitles: ['摸鱼新人', '摸鱼老司机', '摸鱼宗师', '隐形冠军']
  },
  {
    id: 'fortune',
    name: '赛博算命师',
    icon: '🔮',
    description: '白天上班被画饼，晚上直播给别人画饼。',
    salaryMul: 2.5,
    baseWeight: 0.8,
    unlockCondition: { type: 'deaths', value: 5 },
    eventPack: '/subpackages/events/fortune-events.json',
    initialEnergy: 80,
    initialMood: 65,
    weeksPerCareer: 4,
    careerTitles: ['街头神棍', '网红半仙', '命理大师', '玄学网红']
  }
]

export function getJobById(id: string): JobConfig | undefined {
  return JOBS.find((j) => j.id === id)
}
