import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["log", "emptyState", "loadingState", "statusBadge"]
  static values = { 
    taskId: Number,
    sessionId: String,
    taskStatus: String,
    pollInterval: { type: Number, default: 2500 }
  }

  connect() {
    console.log('[AgentActivity] Controller connected', this.taskIdValue, this.sessionIdValue)
    this.lastLine = 0
    this.isPolling = false
    this.pollTimer = null
    
    if (this.sessionIdValue) {
      this.startPolling()
    } else {
      this.showEmptyState()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    if (this.isPolling) return
    this.isPolling = true
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
    if (!this.isPolling) return
    
    try {
      const response = await fetch(`/api/v1/tasks/${this.taskIdValue}/agent_log?since=${this.lastLine}`)
      
      if (!response.ok) {
        console.error('Fetch failed:', response.status)
        this.scheduleNextPoll()
        return
      }

      const data = await response.json()
      console.log('[AgentActivity] Got data:', data.messages?.length, 'messages')
      
      if (data.task_status) {
        this.taskStatusValue = data.task_status
        this.updateStatusBadge(data.task_status)
      }

      if (!data.has_session) {
        this.showEmptyState()
        this.stopPolling()
        return
      }

      if (data.messages && data.messages.length > 0) {
        this.hideEmptyState()
        this.hideLoadingState()
        data.messages.forEach(msg => this.renderMessage(msg))
        this.lastLine = data.total_lines
        this.scrollToBottom()
      } else if (this.lastLine === 0) {
        this.hideLoadingState()
        if (data.has_session) {
          this.showWaitingState()
        } else {
          this.showEmptyState()
        }
      }

      if (!['in_progress', 'up_next'].includes(data.task_status)) {
        this.stopPolling()
        return
      }

    } catch (error) {
      console.error('Poll error:', error)
    }

    this.scheduleNextPoll()
  }

  scheduleNextPoll() {
    if (!this.isPolling) return
    this.pollTimer = setTimeout(() => this.poll(), this.pollIntervalValue)
  }

  renderMessage(msg) {
    const container = this.logTarget
    const div = document.createElement('div')
    div.className = 'agent-log-entry mb-3'
    
    let icon = '📝'
    let roleClass = 'border-content-muted'
    if (msg.role === 'user') { icon = '👤'; roleClass = 'border-blue-500' }
    if (msg.role === 'assistant') { icon = '🤖'; roleClass = 'border-purple-500' }
    if (msg.role === 'toolResult') { icon = '⚙️'; roleClass = 'border-green-500' }
    
    let contentHtml = ''
    if (msg.content && Array.isArray(msg.content)) {
      msg.content.forEach(item => {
        if (item.type === 'text' && item.text) {
          // User messages and text content
          const text = item.text.length > 500 ? item.text.substring(0, 500) + '...' : item.text
          contentHtml += `<div class="text-sm text-content whitespace-pre-wrap break-words">${this.escapeHtml(text)}</div>`
        }
        if (item.type === 'thinking' && item.text) {
          // Assistant thinking - show collapsed
          const thinking = item.text.length > 200 ? item.text.substring(0, 200) + '...' : item.text
          contentHtml += `<div class="text-xs text-content-muted italic bg-bg-surface/50 rounded px-2 py-1 mt-1">💭 ${this.escapeHtml(thinking)}</div>`
        }
        if (item.type === 'tool_call') {
          contentHtml += `<div class="text-xs font-mono text-accent mt-1">🔧 ${this.escapeHtml(item.name || 'tool')}</div>`
        }
        if (item.type === 'tool_result' && item.text) {
          // Tool results - show truncated
          const result = item.text.length > 300 ? item.text.substring(0, 300) + '...' : item.text
          contentHtml += `<div class="text-xs font-mono text-content-muted bg-bg-surface rounded px-2 py-1 mt-1 max-h-20 overflow-y-auto whitespace-pre-wrap">${this.escapeHtml(result)}</div>`
        }
      })
    }
    
    div.innerHTML = `
      <div class="flex items-start gap-2 p-2 rounded-lg bg-bg-elevated border-l-2 ${roleClass}">
        <span class="text-sm flex-shrink-0">${icon}</span>
        <div class="flex-1 min-w-0">
          ${contentHtml || '<span class="text-xs text-content-muted">...</span>'}
        </div>
      </div>
    `
    container.appendChild(div)
  }

  scrollToBottom() {
    if (this.hasLogTarget) {
      this.logTarget.scrollTop = this.logTarget.scrollHeight
    }
  }

  showEmptyState() {
    if (this.hasEmptyStateTarget) this.emptyStateTarget.classList.remove('hidden')
    if (this.hasLogTarget) this.logTarget.classList.add('hidden')
    this.hideLoadingState()
  }

  hideEmptyState() {
    if (this.hasEmptyStateTarget) this.emptyStateTarget.classList.add('hidden')
    if (this.hasLogTarget) this.logTarget.classList.remove('hidden')
  }

  showWaitingState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.remove('hidden')
      const msgEl = this.emptyStateTarget.querySelector('.empty-message')
      if (msgEl) msgEl.textContent = 'Waiting for agent...'
    }
    if (this.hasLogTarget) this.logTarget.classList.add('hidden')
  }

  showLoadingState() {
    if (this.hasLoadingStateTarget) this.loadingStateTarget.classList.remove('hidden')
  }

  hideLoadingState() {
    if (this.hasLoadingStateTarget) this.loadingStateTarget.classList.add('hidden')
  }

  updateStatusBadge(status) {
    if (!this.hasStatusBadgeTarget) return
    const labels = { in_progress: 'Live', up_next: 'Up Next', done: 'Done', in_review: 'In Review' }
    this.statusBadgeTarget.textContent = labels[status] || status
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  refresh() {
    this.lastLine = 0
    if (this.hasLogTarget) this.logTarget.innerHTML = ''
    if (!this.isPolling) this.startPolling()
    else this.poll()
  }
}
