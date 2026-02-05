import { Controller } from "@hotwired/stimulus"

/**
 * Agent Modal Controller
 * Mobile-friendly bottom sheet modal for agent activity preview
 * - Bottom sheet on mobile (slides up from bottom)
 * - Centered modal on desktop
 * - Auto-refreshes content every 5s while open
 * - Accessible: focus trap, ESC key, aria-modal
 */
export default class extends Controller {
  static targets = ["modal", "log", "statusBadge"]
  static values = {
    taskId: Number,
    boardId: Number,
    sessionId: String,
    taskStatus: String,
    pollInterval: { type: Number, default: 5000 }
  }

  connect() {
    this.isOpen = false
    this.isPolling = false
    this.pollTimer = null
    this.lastLine = 0
    
    // Bind ESC key handler
    this.boundKeyHandler = this.handleKeydown.bind(this)
  }

  disconnect() {
    this.close()
    document.removeEventListener("keydown", this.boundKeyHandler)
  }

  open(event) {
    event?.preventDefault()
    event?.stopPropagation()
    
    if (this.isOpen) return
    this.isOpen = true
    
    // Show modal (simple show/hide like followup_modal)
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
    }
    
    // Prevent body scroll
    document.body.style.overflow = "hidden"
    
    // Add ESC key listener
    document.addEventListener("keydown", this.boundKeyHandler)
    
    // Focus trap - focus first focusable element
    this.trapFocus()
    
    // Start polling for content
    this.startPolling()
  }

  close() {
    if (!this.isOpen) return
    this.isOpen = false
    
    // Hide modal (simple show/hide)
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
    }
    
    // Restore body scroll
    document.body.style.overflow = ""
    
    // Remove ESC key listener
    document.removeEventListener("keydown", this.boundKeyHandler)
    
    // Stop polling
    this.stopPolling()
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
    // Focus trap: Tab key
    if (event.key === "Tab") {
      this.handleTabKey(event)
    }
  }

  trapFocus() {
    if (!this.hasModalTarget) return
    
    const focusable = this.modalTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    if (focusable.length > 0) {
      focusable[0].focus()
    }
  }

  handleTabKey(event) {
    if (!this.hasModalTarget) return
    
    const focusable = this.modalTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    const firstFocusable = focusable[0]
    const lastFocusable = focusable[focusable.length - 1]
    
    if (event.shiftKey) {
      if (document.activeElement === firstFocusable) {
        lastFocusable.focus()
        event.preventDefault()
      }
    } else {
      if (document.activeElement === lastFocusable) {
        firstFocusable.focus()
        event.preventDefault()
      }
    }
  }

  // Polling for agent activity
  startPolling() {
    if (this.isPolling) return
    this.isPolling = true
    this.lastLine = 0
    this.poll()
  }

  stopPolling() {
    this.isPolling = false
    if (this.pollTimer) {
      clearTimeout(this.pollTimer)
      this.pollTimer = null
    }
  }

  async poll() {
    if (!this.isPolling || !this.isOpen) return
    
    try {
      const response = await fetch(`/api/v1/tasks/${this.taskIdValue}/agent_log?since=${this.lastLine}`)
      
      if (!response.ok) {
        this.scheduleNextPoll()
        return
      }

      const data = await response.json()
      
      // Update status badge
      if (data.task_status) {
        this.taskStatusValue = data.task_status
        this.updateStatusBadge(data.task_status)
      }

      // Render messages
      if (data.messages && data.messages.length > 0) {
        data.messages.forEach(msg => this.renderMessage(msg))
        this.lastLine = data.total_lines
        this.scrollToBottom()
      } else if (this.lastLine === 0 && this.hasLogTarget) {
        this.logTarget.innerHTML = '<div class="text-center py-4 text-content-muted text-sm">Waiting for agent activity...</div>'
      }

      // Continue polling if still in progress
      if (data.task_status === 'in_progress') {
        this.scheduleNextPoll()
      }
    } catch (error) {
      console.error('[AgentModal] Poll error:', error)
      this.scheduleNextPoll()
    }
  }

  scheduleNextPoll() {
    if (!this.isPolling || !this.isOpen) return
    this.pollTimer = setTimeout(() => this.poll(), this.pollIntervalValue)
  }

  renderMessage(msg) {
    if (!this.hasLogTarget) return
    
    const div = document.createElement('div')
    div.className = 'agent-log-entry mb-2'
    
    let icon = '📝'
    let roleClass = 'border-content-muted'
    if (msg.role === 'user') { icon = '👤'; roleClass = 'border-blue-500' }
    if (msg.role === 'assistant') { icon = '🤖'; roleClass = 'border-purple-500' }
    if (msg.role === 'toolResult') { icon = '⚙️'; roleClass = 'border-green-500' }
    
    let contentHtml = ''
    if (msg.content && Array.isArray(msg.content)) {
      msg.content.forEach(item => {
        if (item.type === 'text' && item.text) {
          const text = item.text.length > 300 ? item.text.substring(0, 300) + '...' : item.text
          contentHtml += `<div class="text-xs text-content whitespace-pre-wrap break-words">${this.escapeHtml(text)}</div>`
        }
        if (item.type === 'thinking' && item.text) {
          const thinking = item.text.length > 100 ? item.text.substring(0, 100) + '...' : item.text
          contentHtml += `<div class="text-[10px] text-content-muted italic bg-bg-surface/50 rounded px-1.5 py-0.5 mt-1">💭 ${this.escapeHtml(thinking)}</div>`
        }
        if (item.type === 'tool_call') {
          contentHtml += `<div class="text-[10px] font-mono text-accent mt-1">🔧 ${this.escapeHtml(item.name || 'tool')}</div>`
        }
        if (item.type === 'tool_result' && item.text) {
          const result = item.text.length > 150 ? item.text.substring(0, 150) + '...' : item.text
          contentHtml += `<div class="text-[10px] font-mono text-content-muted bg-bg-surface rounded px-1.5 py-0.5 mt-1 max-h-12 overflow-y-auto whitespace-pre-wrap">${this.escapeHtml(result)}</div>`
        }
      })
    }
    
    div.innerHTML = `
      <div class="flex items-start gap-2 p-2 rounded-lg bg-bg-elevated border-l-2 ${roleClass}">
        <span class="text-xs flex-shrink-0">${icon}</span>
        <div class="flex-1 min-w-0">
          ${contentHtml || '<span class="text-[10px] text-content-muted">...</span>'}
        </div>
      </div>
    `
    this.logTarget.appendChild(div)
  }

  scrollToBottom() {
    if (this.hasLogTarget) {
      this.logTarget.scrollTop = this.logTarget.scrollHeight
    }
  }

  updateStatusBadge(status) {
    if (!this.hasStatusBadgeTarget) return
    const labels = { in_progress: '🔴 Live', up_next: '⏳ Up Next', done: '✅ Done', in_review: '👀 Review' }
    const colors = { in_progress: 'bg-green-500/20 text-green-400', up_next: 'bg-yellow-500/20 text-yellow-400', done: 'bg-gray-500/20 text-gray-400', in_review: 'bg-blue-500/20 text-blue-400' }
    this.statusBadgeTarget.textContent = labels[status] || status
    this.statusBadgeTarget.className = `inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium ${colors[status] || 'bg-bg-surface text-content-muted'}`
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // Action handlers for buttons in modal
  async moveToNext(event) {
    event.preventDefault()
    const nextStatus = this.getNextStatus(this.taskStatusValue)
    if (!nextStatus) return
    
    try {
      const response = await fetch(`/boards/${this.boardIdValue}/tasks/${this.taskIdValue}/move?status=${nextStatus}`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })
      if (response.ok) {
        this.close()
        // Turbo will handle the update
        window.Turbo.visit(window.location.href, { action: 'replace' })
      }
    } catch (e) {
      console.error('[AgentModal] Move failed:', e)
    }
  }

  getNextStatus(current) {
    const map = { inbox: 'up_next', up_next: 'in_progress', in_progress: 'in_review', in_review: 'done' }
    return map[current]
  }

  // Pin to Terminal - dispatches event to agent-terminal controller
  pinToTerminal(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const taskId = btn.dataset.taskId || this.taskIdValue
    const taskName = btn.dataset.taskName || `Task #${taskId}`
    
    // Dispatch custom event for terminal panel to catch
    document.dispatchEvent(new CustomEvent('agent-terminal:pin', {
      detail: { taskId, taskName }
    }))
    
    // Visual feedback
    btn.textContent = '✅ Pinned!'
    setTimeout(() => {
      btn.textContent = '📌 Pin to Terminal'
    }, 1500)
  }
}
