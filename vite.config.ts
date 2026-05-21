import { defineConfig, type Plugin } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'
import { fileURLToPath, URL } from 'node:url'
import { readdirSync, statSync, mkdirSync, copyFileSync, existsSync } from 'node:fs'
import { join, relative } from 'node:path'

const SRC_DIR = fileURLToPath(new URL('./src', import.meta.url))

function walk(dir: string, files: string[] = []): string[] {
  for (const name of readdirSync(dir)) {
    const full = join(dir, name)
    if (statSync(full).isDirectory()) walk(full, files)
    else files.push(full)
  }
  return files
}

// uni-app only auto-copies src/static/**. Subpackage data files (JSON event packs)
// referenced by runtime paths like /subpackages/events/*.json must be copied
// manually or builds will ship without them — runtime falls back to empty pools.
function copySubpackageDataPlugin(): Plugin {
  return {
    name: 'copy-subpackage-data',
    apply: 'build',
    closeBundle() {
      const subRoot = join(SRC_DIR, 'subpackages')
      if (!existsSync(subRoot)) return
      const outRoot = (this as unknown as { environment?: { config?: { build?: { outDir?: string } } } })
        .environment?.config?.build?.outDir
      // Fallback: derive output from process.env (uni-app sets it per platform build)
      const distRoot = outRoot ?? process.env.UNI_OUTPUT_DIR
      if (!distRoot) return
      for (const src of walk(subRoot)) {
        if (!src.endsWith('.json')) continue
        const rel = relative(SRC_DIR, src)
        const dest = join(distRoot, rel)
        mkdirSync(join(dest, '..'), { recursive: true })
        copyFileSync(src, dest)
      }
    }
  }
}

export default defineConfig({
  plugins: [uni(), copySubpackageDataPlugin()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  }
})
