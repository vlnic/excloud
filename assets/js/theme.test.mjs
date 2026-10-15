import test from "node:test"
import assert from "node:assert/strict"
import {initTheme} from "./theme.mjs"

function environment({stored = null, cookieTheme = null, storageBlocked = false} = {}) {
  const attributes = new Map(cookieTheme ? [["data-bs-theme", cookieTheme]] : [])
  const events = {}
  const storage = new Map(stored === null ? [] : [["phx:theme", stored]])
  const buttons = ["system", "light", "dark"].map(themeValue => ({
    dataset: {themeValue},
    attributes: {},
    setAttribute(name, value) { this.attributes[name] = value },
  }))
  const document = {
    cookie: "",
    documentElement: {
      getAttribute: name => attributes.get(name) ?? null,
      setAttribute: (name, value) => attributes.set(name, value),
      removeAttribute: name => attributes.delete(name),
    },
    querySelectorAll: () => buttons,
    addEventListener: (name, handler) => { events[name] = handler },
  }
  const window = {
    location: {protocol: "https:"},
    get localStorage() {
      if (storageBlocked) throw new Error("Storage blocked")
      return {
        getItem: key => storage.get(key) ?? null,
        setItem: (key, value) => storage.set(key, value),
        removeItem: key => storage.delete(key),
      }
    },
    addEventListener: (name, handler) => { events[name] = handler },
  }
  return {window, document, attributes, events, storage, buttons}
}

test("system mode uses native color-scheme and clears a previous override", () => {
  const env = environment({stored: "dark"})
  const controller = initTheme(env.window, env.document)
  controller.setTheme("system")
  assert.equal(env.attributes.has("data-bs-theme"), false)
  assert.equal(env.storage.has("phx:theme"), false)
  assert.match(env.document.cookie, /Max-Age=0/)
  assert.equal(env.buttons[0].attributes["aria-pressed"], "true")
})

test("a click persists the selected theme for reloads and server rendering", () => {
  const env = environment()
  initTheme(env.window, env.document)
  env.events.click({target: {closest: () => env.buttons[2]}})
  assert.equal(env.attributes.get("data-bs-theme"), "dark")
  assert.equal(env.storage.get("phx:theme"), "dark")
  assert.match(env.document.cookie, /^excloud_theme=dark; Path=\//)
  assert.match(env.document.cookie, /; Secure$/)
  assert.equal(env.buttons[2].attributes["aria-pressed"], "true")
})

test("existing Phoenix preferences are restored and mirrored to a cookie", () => {
  const env = environment({stored: "light"})
  initTheme(env.window, env.document)
  assert.equal(env.attributes.get("data-bs-theme"), "light")
  assert.match(env.document.cookie, /^excloud_theme=light;/)
})

test("storage events and LiveView navigation keep controls synchronized", () => {
  const env = environment()
  initTheme(env.window, env.document)
  env.events.storage({key: "phx:theme", newValue: "dark"})
  assert.equal(env.attributes.get("data-bs-theme"), "dark")
  env.buttons[2].attributes["aria-pressed"] = "false"
  env.events["phx:page-loading-stop"]()
  assert.equal(env.buttons[2].attributes["aria-pressed"], "true")
  env.events.storage({key: null, newValue: null})
  assert.equal(env.attributes.has("data-bs-theme"), false)
})

test("blocked storage preserves a valid server-rendered cookie preference", () => {
  const env = environment({cookieTheme: "dark", storageBlocked: true})
  const controller = initTheme(env.window, env.document)
  assert.equal(env.attributes.get("data-bs-theme"), "dark")
  controller.setTheme("light")
  assert.equal(env.attributes.get("data-bs-theme"), "light")
})

test("invalid preferences fall back to system mode", () => {
  const env = environment({stored: "invalid"})
  initTheme(env.window, env.document)
  assert.equal(env.attributes.has("data-bs-theme"), false)
  assert.equal(env.buttons[0].attributes["aria-pressed"], "true")
})
