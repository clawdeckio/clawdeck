import { Controller } from "@hotwired/stimulus"

// Fetches /api/v1/live_feed and renders a compact timeline.
// Assumptions:
// - Same-origin session auth (no token needed for the web UI)
// - Api::V1::LiveFeedController returns { items: [...] }
export default class extends Controller {
  static targets = ["body"]

  connect() {
    this.loaded = false
    this.pollIntervalMs = 15 * 1000
    this.pollTimer = null

    this.menuEl = this.element.querySelector("[data-dropdown-target='menu']")
  }

  disconnect() {
    this.stopPolling()
  }

  async load() {
    if (this.loaded) {
      this.startPolling()
      return
    }

    this.loaded = true

    await this.reload({ showLoading: true })
    this.startPolling()
  }

  async reload({ showLoading } = {}) {
    if (showLoading) this.bodyTarget.innerHTML = this.loadingHtml()

    try {
      const response = await fetch("/api/v1/live_feed?limit=25", {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })

      if (!response.ok) {
        this.bodyTarget.innerHTML = this.errorHtml(`Failed to load feed (HTTP ${response.status})`)
        return
      }

      const payload = await response.json()
      const items = payload?.items

      if (!Array.isArray(items) || items.length === 0) {
        this.bodyTarget.innerHTML = this.emptyHtml()
        return
      }

      this.bodyTarget.innerHTML = this.listHtml(items)
    } catch (e) {
      this.bodyTarget.innerHTML = this.errorHtml("Failed to load feed")
    }
  }

  startPolling() {
    if (this.pollTimer) return

    this.pollTimer = setInterval(() => {
      if (!this.element.isConnected) {
        this.stopPolling()
        return
      }

      if (this.menuEl && this.menuEl.classList.contains("hidden")) {
        this.stopPolling()
        return
      }

      this.reload({ showLoading: false })
    }, this.pollIntervalMs)
  }

  stopPolling() {
    if (!this.pollTimer) return
    clearInterval(this.pollTimer)
    this.pollTimer = null
  }

  listHtml(items) {
    const rows = items
      .map((i) => {
        const type = (i.type || "").toString()
        const at = i.at ? this.timeAgo(i.at) : null

        if (type === "comment") {
          const c = i.comment || {}
          const who = this.escape(c.actor_name || c.actor_type || "Someone")
          const emoji = (c.actor_emoji || "").toString().trim()
          const body = c.body_html
            ? c.body_html.toString()
            : this.truncate(this.escape((c.body || "").toString()), 160)
          const taskHint = i.task_id ? ` #${this.escape(i.task_id)}` : ""
          const text = `${emoji ? `${this.escape(emoji)} ` : ""}${who}: ${body}${taskHint}`
          const href = this.taskHref(c.board_id, c.task_id)
          return this.rowHtml("💬", text, at, href, { textClass: "text-xs text-content break-words" })
        }

        if (type === "artifact") {
          const a = i.artifact || {}
          const name = this.escape(a.name || "Artifact")
          const kind = this.escape(a.artifact_type || "")
          const taskHint = i.task_id ? ` #${this.escape(i.task_id)}` : ""
          const label = `${name}${kind ? ` • ${kind}` : ""}${taskHint}`
          const href = this.taskHref(a.board_id, a.task_id)
          return this.rowHtml(this.artifactIcon(kind), label, at, href)
        }

        // task
        const t = i.task || {}
        const name = this.escape(t.name || "Task")
        const status = this.escape(t.status || "")
        const taskHint = i.task_id ? ` #${this.escape(i.task_id)}` : (t.id ? ` #${this.escape(t.id)}` : "")
        const href = this.taskHref(t.board_id, t.id)
        return this.rowHtml("✅", `${name}${status ? ` • ${status}` : ""}${taskHint}`, at, href)
      })
      .join("\n")

    return `<div class="space-y-1">${rows}</div>`
  }

  artifactIcon(kind) {
    const k = (kind || "").toString().toLowerCase().trim()
    if (!k) return "📎"
    if (k.includes("image") || k.includes("png") || k.includes("jpg") || k.includes("jpeg") || k.includes("gif") || k.includes("webp")) return "🖼️"
    if (k.includes("video") || k.includes("mp4") || k.includes("mov") || k.includes("webm")) return "🎥"
    if (k.includes("audio") || k.includes("mp3") || k.includes("wav") || k.includes("m4a")) return "🔊"
    if (k.includes("pdf")) return "📄"
    if (k.includes("csv") || k.includes("tsv") || k.includes("xls") || k.includes("xlsx")) return "📊"
    if (k.includes("json") || k.includes("yaml") || k.includes("yml")) return "🧾"
    if (k.includes("zip") || k.includes("tar") || k.includes("gz")) return "🗜️"
    return "📎"
  }

  rowHtml(icon, text, at, href, options = {}) {
    const textClass = options.textClass || "text-xs text-content truncate"

    const inner = `
      <div class="flex items-start justify-between gap-3 px-2 py-2 rounded-md hover:bg-bg-elevated">
        <div class="flex items-start gap-2 min-w-0">
          <div class="w-7 h-7 rounded-md bg-bg-elevated flex items-center justify-center text-base flex-shrink-0" aria-hidden="true">${icon}</div>
          <div class="min-w-0">
            <div class="${textClass}">${text}</div>
            <div class="text-[11px] text-content-muted">${at ? `${at} ago` : ""}</div>
          </div>
        </div>
      </div>
    `

    if (!href) return inner

    return `
      <a href="${href}" data-turbo-frame="task_panel" class="block rounded-md focus:outline-none focus:ring-2 focus:ring-accent/60">
        ${inner}
      </a>
    `
  }

  timeAgo(isoString) {
    const ts = Date.parse(isoString)
    if (Number.isNaN(ts)) return null

    const seconds = Math.max(0, Math.floor((Date.now() - ts) / 1000))
    if (seconds < 60) return `${seconds}s`
    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) return `${minutes}m`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}h`
    const days = Math.floor(hours / 24)
    return `${days}d`
  }

  loadingHtml() {
    return `<div class="py-4 text-center text-xs text-content-muted">Loading…</div>`
  }

  emptyHtml() {
    return `<div class="py-4 text-center text-xs text-content-muted">No recent activity yet.</div>`
  }

  errorHtml(message) {
    return `<div class="py-4 text-center text-xs text-status-error">${this.escape(message)}</div>`
  }

  taskHref(boardId, taskId) {
    if (!boardId || !taskId) return null
    return `/boards/${encodeURIComponent(boardId)}/tasks/${encodeURIComponent(taskId)}`
  }

  truncate(str, maxLen) {
    const s = (str || "").toString()
    if (s.length <= maxLen) return s
    return `${s.slice(0, Math.max(0, maxLen - 1))}…`
  }

  escape(str) {
    return (str || "")
      .toString()
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }
}
