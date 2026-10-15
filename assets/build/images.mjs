import {copyFileSync, mkdirSync, readdirSync, rmSync, watch} from "node:fs"
import {dirname, join, resolve} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

function contents(directory, relative = "", files = [], directories = []) {
  directories.push(join(directory, relative))
  for (const entry of readdirSync(join(directory, relative), {withFileTypes: true})) {
    const path = join(relative, entry.name)
    if (entry.isDirectory()) contents(directory, path, files, directories)
    else if (entry.isFile()) files.push(path)
  }
  return {files, directories}
}

// Remove deleted source paths, leaving fingerprinted and compressed versions
// under phx.digest's control so cached URLs keep working across builds.
export function buildImages(source, output) {
  const {files, directories} = contents(source)
  const sources = new Set(files)
  mkdirSync(output, {recursive: true})
  for (const file of contents(output).files) {
    const digested = /-[a-f0-9]{32}\.[^/]+$/.test(file) || file.endsWith(".gz")
    if (!sources.has(file) && !digested) rmSync(join(output, file))
  }
  for (const file of files) {
    mkdirSync(dirname(join(output, file)), {recursive: true})
    copyFileSync(join(source, file), join(output, file))
  }
  return {count: files.length, directories}
}

export function watchImages(source, output, onBuild = () => {}) {
  const watchers = new Map()
  let pending

  const rebuild = () => {
    const {count, directories} = buildImages(source, output)
    for (const [directory, watcher] of watchers) {
      if (!directories.includes(directory)) {
        watcher.close()
        watchers.delete(directory)
      }
    }
    for (const directory of directories) {
      if (!watchers.has(directory)) {
        watchers.set(directory, watch(directory, () => {
          clearTimeout(pending)
          pending = setTimeout(rebuild, 50)
        }))
      }
    }
    onBuild(count)
  }

  rebuild()
  return () => {
    clearTimeout(pending)
    for (const watcher of watchers.values()) watcher.close()
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const source = fileURLToPath(new URL("../images", import.meta.url))
  const output = fileURLToPath(new URL("../../priv/static/images", import.meta.url))
  const report = count => console.log(`[images] Built ${count} files`)

  if (process.argv.includes("--watch")) {
    const close = watchImages(source, output, report)
    // Phoenix closes the port's stdin on shutdown; do not leave an orphan watcher.
    process.stdin.resume()
    const stop = () => { close(); process.exit(0) }
    process.stdin.on("end", stop)
    process.on("SIGTERM", stop)
    process.on("SIGINT", stop)
  } else {
    report(buildImages(source, output).count)
  }
}
