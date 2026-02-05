import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "pinButton"]
  static values = { 
    taskId: Number,
    boardId: Number,
    taskName: String,
    boardIcon: { type: String, default: '📋' }
  }

  connect() {
    this.polling = false
    this.showTimeout = null
    this.hideTimeout = null
    this.dropdownOpen = false
    
    // Hide preview when dropdowns open (context menus shouldn't overlap with previews)
    this.hideOnDropdown = () => {
      this.dropdownOpen = true
      this.hideImmediately()
    }
    document.addEventListener("dropdown:opened", this.hideOnDropdown)
    
    // Allow preview again when dropdown closes
    this.enableOnDropdownClose = () => { this.dropdownOpen = false }
    document.addEventListener("dropdown:closed", this.enableOnDropdownClose)
    
    // Hide preview on click (user is opening the task panel)
    // But NOT if clicking inside the preview itself (e.g., pin button)
    this.hideOnClick = (event) => {
      if (this.hasPreviewTarget && this.previewTarget.contains(event.target)) {
        return // Don't hide when clicking inside the preview
      }
      this.hideImmediately()
    }
    this.element.addEventListener('click', this.hideOnClick)
    this.element.addEventListener('mousedown', this.hideOnClick)
  }

  disconnect() {
    this.stopPolling()
    clearTimeout(this.showTimeout)
    clearTimeout(this.hideTimeout)
    document.removeEventListener("dropdown:opened", this.hideOnDropdown)
    document.removeEventListener("dropdown:closed", this.enableOnDropdownClose)
    if (this.hideOnClick) {
      this.element.removeEventListener('click', this.hideOnClick)
      this.element.removeEventListener('mousedown', this.hideOnClick)
    }
  }

  show() {
    if (!this.hasPreviewTarget) return
    if (this.dropdownOpen) return  // Don't show preview while dropdown is open
    clearTimeout(this.hideTimeout)
    
    // Delay before showing to avoid flicker on quick mouse movements
    this.showTimeout = setTimeout(() => {
      if (this.dropdownOpen) return  // Double-check after timeout
      const rect = this.element.getBoundingClientRect()
      const preview = this.previewTarget
      
      // Use fixed positioning to escape overflow:hidden containers
      preview.style.position = 'fixed'
      preview.style.left = `${rect.left}px`
      preview.style.width = `${rect.width}px`
      preview.style.zIndex = '40'  // Keep below dropdown menus (z-[10000]) and modal overlays
      
      // Reset both top/bottom before calculating
      preview.style.top = 'auto'
      preview.style.bottom = 'auto'
      
      // Try below first, then above if not enough space
      const spaceBelow = window.innerHeight - rect.bottom
      if (spaceBelow > 150) {
        preview.style.top = `${rect.bottom + 4}px`
      } else {
        preview.style.bottom = `${window.innerHeight - rect.top + 4}px`
      }
      
      preview.classList.remove('hidden')
      this.startPolling()
    }, 150)
  }

  hide() {
    clearTimeout(this.showTimeout)
    
    // Small delay to allow mouse to enter the preview
    this.hideTimeout = setTimeout(() => {
      if (this.hasPreviewTarget) {
        this.previewTarget.classList.add('hidden')
      }
      this.stopPolling()
    }, 100)
  }

  // Hide immediately without delay (used when dropdown opens)
  hideImmediately() {
    clearTimeout(this.showTimeout)
    clearTimeout(this.hideTimeout)
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add('hidden')
    }
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
    
    // Build preview content with pin button
    let previewContent = ''
    
    if (messages.length === 0) {
      previewContent = '<span class="text-content-muted text-xs">Waiting for agent...</span>'
    } else {
      previewContent = messages.slice(-3).map(m => {
        const icon = m.role === 'user' ? '👤' : '🤖'
        const rawContent = this.extractContent(m.content)
        const text = this.escapeHtml(rawContent.substring(0, 250))
        const ellipsis = rawContent.length > 250 ? '...' : ''
        return `<div class="text-xs truncate text-content-secondary">${icon} ${text}${ellipsis}</div>`
      }).join('')
    }
    
    // Add pin button
    const pinButton = `
      <button 
        data-action="click->agent-preview#pinToTerminal"
        class="mt-2 w-full flex items-center justify-center gap-1 px-2 py-1 text-[10px] font-medium text-green-400 bg-green-500/10 hover:bg-green-500/20 border border-green-500/30 rounded transition-colors"
        title="Pin to Agent Terminal"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3 h-3">
          <path stroke-linecap="round" stroke-linejoin="round" d="m6.75 7.5 3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0 0 21 18V6a2.25 2.25 0 0 0-2.25-2.25H5.25A2.25 2.25 0 0 0 3 6v12a2.25 2.25 0 0 0 2.25 2.25Z" />
        </svg>
        PIN TO TERMINAL
      </button>
    `
    
    this.previewTarget.innerHTML = previewContent + pinButton
  }

  pinToTerminal(event) {
    event.preventDefault()
    event.stopPropagation()
    
    // Dispatch custom event that the terminal controller listens to
    const pinEvent = new CustomEvent('agent-terminal:pin', {
      bubbles: true,
      detail: {
        taskId: this.taskIdValue,
        taskName: this.taskNameValue || `Task #${this.taskIdValue}`,
        boardIcon: this.boardIconValue || '📋'
      }
    })
    
    document.dispatchEvent(pinEvent)
    
    // Hide the preview after pinning
    this.hide()
  }

  extractContent(content) {
    if (!content) return ''
    if (typeof content === 'string') return content
    if (Array.isArray(content)) {
      // Find first text-type content item
      const textItem = content.find(c => c.type === 'text' || c.type === 'tool_result')
      return textItem?.text || ''
    }
    return ''
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
