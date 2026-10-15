const validTheme = value => ["light", "dark"].includes(value) ? value : "system"

// A cookie gives the server the same preference before the first paint.
// localStorage retains compatibility with the original Phoenix switcher.
export function initTheme(window, document) {
  const root = document.documentElement
  let preference = validTheme(root.getAttribute("data-bs-theme"))

  try {
    const stored = window.localStorage.getItem("phx:theme")
    if (stored !== null) preference = validTheme(stored)
  } catch (_) {
    // Cookies and the rendered attribute still work when storage is unavailable.
  }

  const refreshButtons = () => {
    document.querySelectorAll("[data-theme-value]").forEach(button => {
      button.setAttribute("aria-pressed", String(button.dataset.themeValue === preference))
    })
  }

  const setTheme = (value, persist = true) => {
    preference = validTheme(value)
    if (preference === "system") root.removeAttribute("data-bs-theme")
    else root.setAttribute("data-bs-theme", preference)
    root.setAttribute("data-theme-source", preference === "system" ? "system" : "user")

    if (persist) {
      try {
        if (preference === "system") window.localStorage.removeItem("phx:theme")
        else window.localStorage.setItem("phx:theme", preference)
      } catch (_) {}
    }

    const secure = window.location.protocol === "https:" ? "; Secure" : ""
    document.cookie = `excloud_theme=${preference === "system" ? "" : preference}; Path=/; Max-Age=${preference === "system" ? 0 : 31536000}; SameSite=Lax${secure}`
    refreshButtons()
  }

  document.addEventListener("click", event => {
    const button = event.target.closest?.("[data-theme-value]")
    if (button) setTheme(button.dataset.themeValue)
  })
  window.addEventListener("phx:set-theme", event => setTheme(event.target.dataset.phxTheme))
  window.addEventListener("storage", event => {
    if (event.key === "phx:theme" || event.key === null) setTheme(event.newValue, false)
  })
  window.addEventListener("phx:page-loading-stop", refreshButtons)

  setTheme(preference, false)
  return {setTheme}
}
