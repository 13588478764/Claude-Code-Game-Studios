/**
 * Save store — bridges SaveService to Vue components.
 * See ADR-003.
 */

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { SaveService } from '@/services/save/save-service'
import { EMPTY_SAVE, type SaveData } from '@/types/save'

const saveService = new SaveService()

export const useSaveStore = defineStore('save', () => {
  const data = ref<SaveData>({ ...EMPTY_SAVE })
  const lastSavedAt = ref<number>(0)
  const loadFailed = ref<boolean>(false)

  saveService.onSaved.on((event) => {
    lastSavedAt.value = event.at
  })
  saveService.onLoadFailed.on(() => {
    loadFailed.value = true
  })

  function load(): void {
    const loaded = saveService.load()
    if (loaded) {
      data.value = loaded
    } else {
      data.value = { ...EMPTY_SAVE, updatedAt: Date.now() }
    }
  }

  function save(): void {
    saveService.save(data.value)
  }

  function saveImmediate(): void {
    saveService.saveImmediate(data.value)
  }

  function clear(): void {
    saveService.clear()
    data.value = { ...EMPTY_SAVE }
    lastSavedAt.value = 0
    loadFailed.value = false
  }

  function update(patch: Partial<SaveData>): void {
    data.value = { ...data.value, ...patch }
    save()
  }

  return { data, lastSavedAt, loadFailed, load, save, saveImmediate, clear, update }
})

export { saveService }
