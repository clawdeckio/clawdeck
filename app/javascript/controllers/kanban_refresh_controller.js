import { Controller } from "@hotwired/stimulus"

/**
 * Auto-refresh controller for kanban board
 * Polls for changes and refreshes the view when tasks are modified
 */
export default class extends Controller {
  static values = {
    boardId: Number,
    interval: { type: Number, default: 15000 }, // 15 seconds default
    apiPath: String
  }

  static targets = ["indicator"]

  connect() {
    this.lastFingerprint = null
    this.isRefreshing = false
    this.isPaused = false
    
    // Get initial fingerprint
    this.fetchFingerprint().then(fp => {
      this.lastFingerprint = fp
    })
    
    // Start polling
    this.startPolling()
    
    // Pause when tab is not visible
    this.handleVisibilityChange = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
    
    // Listen for Turbo events to reset fingerprint after navigation
    this.handleTurboLoad = this.handleTurboLoad.bind(this)
    document.addEventListener("turbo:load", this.handleTurboLoad)
  }

  disconnect() {
    this.stopPolling()
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
    document.removeEventListener("turbo:load", this.handleTurboLoad)
  }

  startPolling() {
    this.pollInterval = setInterval(() => {
      this.checkForChanges()
    }, this.intervalValue)
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  handleVisibilityChange() {
    if (document.hidden) {
      this.isPaused = true
    } else {
      this.isPaused = false
      // Check immediately when tab becomes visible again
      this.checkForChanges()
    }
  }

  handleTurboLoad() {
    // Update fingerprint after a Turbo navigation
    this.fetchFingerprint().then(fp => {
      this.lastFingerprint = fp
    })
  }

  async checkForChanges() {
    if (this.isPaused || this.isRefreshing) return
    
    try {
      const fingerprint = await this.fetchFingerprint()
      
      if (this.lastFingerprint && fingerprint !== this.lastFingerprint) {
        this.refresh()
      }
      
      this.lastFingerprint = fingerprint
    } catch (error) {
      console.warn("Kanban refresh check failed:", error)
    }
  }

  async fetchFingerprint() {
    const apiPath = this.apiPathValue || `/api/v1/boards/${this.boardIdValue}/status`
    const response = await fetch(apiPath, {
      headers: {
        "Accept": "application/json"
      },
      credentials: "same-origin"
    })
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }
    
    const data = await response.json()
    return data.fingerprint
  }

  refresh() {
    if (this.isRefreshing) return
    
    this.isRefreshing = true
    this.showIndicator()
    
    // Use Turbo to refresh the page content
    Turbo.visit(window.location.href, { action: "replace" })
    
    // Reset state after a short delay
    setTimeout(() => {
      this.isRefreshing = false
      this.hideIndicator()
      // Update fingerprint after refresh
      this.fetchFingerprint().then(fp => {
        this.lastFingerprint = fp
      })
    }, 1000)
  }

  showIndicator() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.remove("opacity-0")
      this.indicatorTarget.classList.add("opacity-100")
    }
  }

  hideIndicator() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.remove("opacity-100")
      this.indicatorTarget.classList.add("opacity-0")
    }
  }

  // Manual refresh action (can be triggered by button)
  manualRefresh() {
    this.refresh()
  }
}
