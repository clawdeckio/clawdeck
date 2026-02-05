import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]
  static values = { 
    taskId: Number,
    boardId: Number
  }

  connect() {
    this.polling = false
  }

  disconnect() {
    this.stopPolling()
  }

  show() {
    if (!this.hasPreviewTarget) return
    this.previewTarget.classList.remove("hidden")
    this.startPolling()
  }

  hide() {
    if (!this.hasPreviewTarget) return
    this.previewTarget.classList.add("hidden")
    this.stopPolling()
  }

  startPolling() {
    this.polling = true
    this.poll()
  }

  stopPolling() {
    this.polling = false
  }

  async poll() {
    if (!this.polling) return
    
    try {
      const response = await fetch(`/api/v1/tasks/${this.taskIdValue}/agent_log?limit=3`)
      if (response.ok) {
        const data = await response.json()
        this.renderPreview(data.messages || [])
      }
    } catch (e) {
      console.error("Preview poll failed:", e)
    }

    if (this.polling) {
      setTimeout(() => this.poll(), 2000)
    }
  }

  renderPreview(messages) {
    if (!this.hasPreviewTarget) return
    
    if (messages.length === 0) {
      this.previewTarget.innerHTML = '<span class="text-content-muted text-xs">Waiting for agent...</span>'
      return
    }

    const html = messages.slice(-3).map(m => {
      const icon = m.role === 'user' ? '👤' : '🤖'
      const text = this.escapeHtml((m.content || '').substring(0, 100))
      const ellipsis = (m.content || '').length > 100 ? '...' : ''
      return `<div class="text-xs truncate text-content-secondary">${icon} ${text}${ellipsis}</div>`
    }).join('')
    
    this.previewTarget.innerHTML = html
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
