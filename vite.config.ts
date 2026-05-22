import { defineConfig, type Plugin } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'
import { fileURLToPath, URL } from 'node:url'
import { readdirSync, statSync, mkdirSync, copyFileSync, existsSync, readFileSync } from 'node:fs'
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
// referenced by runtime paths like /subpackages/events/*.json must be:
//   - production build: copied to dist (closeBundle hook)
//   - dev:h5: served from src by middleware (otherwise 404 → fallback events only,
//     manifests as "every day shows same 5 events" in the browser)
function copySubpackageDataPlugin(): Plugin {
  return {
    name: 'copy-subpackage-data',
    // Note: NO `apply` filter — must run in both 'build' and 'serve' modes.

    configureServer(server) {
      // Dev mode (npm run dev:h5) — serve /subpackages/**/*.json from src/.
      // Without this middleware, the runtime uni-event-loader's fetch
      // requests to /subpackages/events/*.json 404 and the game falls back
      // to 5 hardcoded events that look identical every day.
      server.middlewares.use((req, res, next) => {
        const url = req.url ?? ''
        if (!url.startsWith('/subpackages/') || !url.includes('.json')) {
          return next()
        }
        const clean = url.split('?')[0]!.split('#')[0]!
        const filePath = join(SRC_DIR, clean.replace(/^\//, ''))
        if (!existsSync(filePath)) return next()
        res.setHeader('Content-Type', 'application/json; charset=utf-8')
        res.end(readFileSync(filePath))
      })
    },

    closeBundle() {
      // Production build (npm run build:*) — copy src/subpackages/**/*.json
      // into dist so mini-program runtime can resolve the same paths.
      const subRoot = join(SRC_DIR, 'subpackages')
      if (!existsSync(subRoot)) return
      const outRoot = (this as unknown as { environment?: { config?: { build?: { outDir?: string } } } })
        .environment?.config?.build?.outDir
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
