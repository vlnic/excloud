import test from "node:test"
import assert from "node:assert/strict"
import {existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync} from "node:fs"
import {tmpdir} from "node:os"
import {join} from "node:path"
import {buildImages, watchImages} from "./images.mjs"

function directories() {
  const root = mkdtempSync(join(tmpdir(), "excloud-images-"))
  const source = join(root, "source")
  const output = join(root, "output")
  mkdirSync(source)
  return {root, source, output}
}

test("the build preserves SVG, binary images and nested paths, and removes stale output", () => {
  const {root, source, output} = directories()
  try {
    mkdirSync(join(source, "nested"))
    writeFileSync(join(source, "logo.svg"), '<svg id="logo"></svg>')
    const binary = Buffer.from([0, 0, 1, 0, 255, 128])
    writeFileSync(join(source, "nested", "favicon.ico"), binary)
    buildImages(source, output)
    assert.equal(readFileSync(join(output, "logo.svg"), "utf8"), '<svg id="logo"></svg>')
    assert.deepEqual(readFileSync(join(output, "nested", "favicon.ico")), binary)

    const fingerprint = `logo-${"a".repeat(32)}.svg`
    writeFileSync(join(output, fingerprint), "previous version")
    writeFileSync(join(output, "logo.svg.gz"), "compressed version")
    rmSync(join(source, "logo.svg"))
    writeFileSync(join(source, "nested", "favicon.ico"), Buffer.from([42]))
    buildImages(source, output)
    assert.equal(existsSync(join(output, "logo.svg")), false)
    assert.equal(readFileSync(join(output, fingerprint), "utf8"), "previous version")
    assert.equal(existsSync(join(output, "logo.svg.gz")), true)
    assert.deepEqual(readFileSync(join(output, "nested", "favicon.ico")), Buffer.from([42]))
  } finally {
    rmSync(root, {recursive: true, force: true})
  }
})

test("development watches new directories, image changes and deletions", {timeout: 5000}, async () => {
  const {root, source, output} = directories()
  let rebuilt = () => {}
  const close = watchImages(source, output, () => rebuilt())
  const nextBuild = () => new Promise(resolve => { rebuilt = resolve })

  try {
    let completed = nextBuild()
    mkdirSync(join(source, "nested"))
    writeFileSync(join(source, "nested", "logo.svg"), "<svg />")
    await completed
    assert.equal(readFileSync(join(output, "nested", "logo.svg"), "utf8"), "<svg />")

    completed = nextBuild()
    writeFileSync(join(source, "nested", "logo.svg"), '<svg id="updated" />')
    await completed
    assert.equal(readFileSync(join(output, "nested", "logo.svg"), "utf8"), '<svg id="updated" />')

    completed = nextBuild()
    rmSync(join(source, "nested", "logo.svg"))
    await completed
    assert.equal(existsSync(join(output, "nested", "logo.svg")), false)
  } finally {
    close()
    rmSync(root, {recursive: true, force: true})
  }
})
