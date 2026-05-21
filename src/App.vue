<script setup lang="ts">
import { onLaunch, onShow, onHide } from '@dcloudio/uni-app'

onLaunch(() => {
  console.log('[App] launched')
})

onShow(() => {
  console.log('[App] show')
})

onHide(() => {
  console.log('[App] hide')
})
</script>

<style>
/* Global reset */
page {
  background: #0f0a26;
  color: #eee;
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Microsoft YaHei', sans-serif;
}
</style>
