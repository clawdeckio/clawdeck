import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["body", "filterButton"]

  connect() {
    this.loaded = false
    this.pollIntervalMs = 20000
    this.pollTimer = null
    this.menuObserver = null
    this.filter = "all"
    this.agents = []
    this.menuEl = this.element.querySelector('[data-dropdown-target="menu"]')
    this.observeMenu()
  }

  disconnect() {
    this.stopPolling()
    this.stopObservingMenu()
  }

  async load() {
    if (!this.isMenuOpen()) {
      this.stopPolling()
      return
    }

    if (this.loaded) {
      this.startPolling()
      return
    }

    this.loaded = true
    await this.reload({ showLoading: true })
    this.startPolling()
  }

  async reload({ showLoading = false } = {}) {
    if (!this.isMenuOpen()) {
      this.stopPolling()
      return
    }

    if (showLoading) {
      this.renderLoading()
    }

    try {
      const response = await fetch("/api/v1/agents", {
        credentials: "same-origin",
        headers: {
          Accept: "application/json"
        }
      })

      if (!response.ok) {
        this.renderError(`Failed to load agents (HTTP ${response.status})`)
        return
      }

      const payload = await response.json()
      this.agents = Array.isArray(payload) ? payload : payload.agents || []
      this.renderList()
    } catch (_error) {
      this.agents = []
      this.renderError("Unable to load agents.")
    }
  }

  startPolling() {
    if (!this.isMenuOpen()) {
      this.stopPolling()
      return
    }

    if (this.pollTimer) {
      return
    }

    this.pollTimer = window.setInterval(() => {
      if (!this.element.isConnected) {
        this.stopPolling()
        return
      }

      if (!this.isMenuOpen()) {
        this.stopPolling()
        return
      }

      this.reload()
    }, this.pollIntervalMs)
  }

  stopPolling() {
    if (!this.pollTimer) {
      return
    }

    window.clearInterval(this.pollTimer)
    this.pollTimer = null
  }

  isMenuOpen() {
    return !this.menuEl || !this.menuEl.classList.contains("hidden")
  }

  observeMenu() {
    if (!this.menuEl || typeof MutationObserver === "undefined") {
      return
    }

    this.menuObserver = new MutationObserver(() => {
      if (this.isMenuOpen()) {
        if (this.loaded) {
          this.startPolling()
        }
      } else {
        this.stopPolling()
      }
    })

    this.menuObserver.observe(this.menuEl, { attributes: true, attributeFilter: [ "class" ] })
  }

  stopObservingMenu() {
    if (!this.menuObserver) {
      return
    }

    this.menuObserver.disconnect()
    this.menuObserver = null
  }

  selectFilter(event) {
    this.filter = event.params.filter
    this.renderList()

    if (this.hasFilterButtonTarget) {
      this.filterButtonTargets.forEach((button) => {
        const value = button.dataset.agentRosterFilterParam
        button.setAttribute("aria-pressed", value === this.filter ? "true" : "false")
      })
      return
    }

    this.element
      .querySelectorAll('[data-action*="agent-roster#selectFilter"]')
      .forEach((button) => {
        const value = button.dataset.agentRosterFilterParam
        if (value) {
          button.setAttribute("aria-pressed", value === this.filter ? "true" : "false")
        }
      })
  }

  inferredState(agent) {
    const status = String(agent.status || "").trim().toLowerCase()
    if (status === "working" || status === "idle" || status === "offline") {
      return status
    }

    const lastSeen = agent.last_seen_at || agent.lastSeenAt
    if (!lastSeen) {
      return "offline"
    }

    const deltaMs = Date.now() - new Date(lastSeen).getTime()
    if (Number.isNaN(deltaMs)) {
      return "offline"
    }

    if (deltaMs < 2 * 60 * 1000) {
      return "working"
    }

    if (deltaMs < 10 * 60 * 1000) {
      return "idle"
    }

    return "offline"
  }

  filteredAgents() {
    if (this.filter === "all") {
      return this.agents
    }

    return this.agents.filter((agent) => this.inferredState(agent) === this.filter)
  }

  statusDotClass(state) {
    switch (state) {
      case "working":
        return "bg-status-success"
      case "idle":
        return "bg-status-warning"
      case "offline":
        return "bg-content-muted"
      default:
        return "bg-content-muted"
    }
  }

  renderLoading() {
    if (!this.hasBodyTarget) {
      return
    }

    this.bodyTarget.innerHTML = this.loadingHtml()
  }

  renderList() {
    if (!this.hasBodyTarget) {
      return
    }

    const rows = this.filteredAgents()
    if (rows.length === 0) {
      this.bodyTarget.innerHTML = this.emptyHtml()
      return
    }

    this.bodyTarget.innerHTML = rows
      .map((agent) => {
        const state = this.inferredState(agent)
        const emoji = this.escape(agent.emoji || "🤖")
        const name = this.escape(agent.name || agent.email || agent.id || "Unnamed agent")
        const role = this.escape(agent.role || agent.metadata?.role || agent.capabilities?.role || "")
        const status = this.escape(agent.status || "")
        const detail = [role, status].filter((value) => value.length > 0).join(" • ")
        const lastSeen = agent.last_seen_at || agent.lastSeenAt
        const seenText = this.escape(this.timeAgo(lastSeen))

        return `
          <div class="flex items-center justify-between gap-3 px-3 py-2">
            <div class="min-w-0">
              <div class="truncate text-sm font-medium text-content">${emoji} ${name}</div>
              ${detail ? `<div class="truncate text-xs text-content-muted">${detail}</div>` : ""}
            </div>
            <div class="flex items-center gap-2 text-xs text-content-muted">
              <span class="inline-block h-2 w-2 rounded-full ${this.statusDotClass(state)}"></span>
              <span>${seenText}</span>
            </div>
          </div>
        `
      })
      .join("")
  }

  renderError(message) {
    if (!this.hasBodyTarget) {
      return
    }

    this.bodyTarget.innerHTML = this.errorHtml(message)
  }

  loadingHtml() {
    return '<div class="py-4 text-center text-xs text-content-muted">Loading…</div>'
  }

  emptyHtml() {
    return '<div class="py-4 text-center text-xs text-content-muted">No agents found.</div>'
  }

  errorHtml(message) {
    return `<div class="py-4 text-center text-xs text-status-error">${this.escape(message)}</div>`
  }

  escape(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }

  timeAgo(input) {
    if (!input) {
      return "never"
    }

    const time = new Date(input)
    if (Number.isNaN(time.getTime())) {
      return "unknown"
    }

    const diffSeconds = Math.max(0, Math.floor((Date.now() - time.getTime()) / 1000))

    if (diffSeconds < 5) {
      return "just now"
    }

    if (diffSeconds < 60) {
      return `${diffSeconds}s ago`
    }

    const diffMinutes = Math.floor(diffSeconds / 60)
    if (diffMinutes < 60) {
      return `${diffMinutes}m ago`
    }

    const diffHours = Math.floor(diffMinutes / 60)
    if (diffHours < 24) {
      return `${diffHours}h ago`
    }

    const diffDays = Math.floor(diffHours / 24)
    return `${diffDays}d ago`
  }
}
