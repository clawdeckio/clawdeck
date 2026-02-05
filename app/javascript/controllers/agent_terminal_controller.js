import { Controller } from "@hotwired/stimulus"

/**
 * Agent Terminal Panel - Codec-style bottom panel for monitoring agent activity
 * 
 * Features:
 * - Pin/dock agent outputs to bottom panel
 * - Multiple tabs for pinned agents
 * - Resizable panel height
 * - Auto-scroll with latest messages
 * - LocalStorage persistence
 * - Keyboard shortcut (Ctrl+`) to toggle
 */
export default class extends Controller {
  static targets = [
    "panel",
    "tabList",
    "content",
    "resizeHandle",
    "emptyState",
    "toggleButton",
    "floatingToggle",
    "floatingBadge"
  ]

  static values = {
    minHeight: { type: Number, default: 150 },
    maxHeight: { type: Number, default: 500 },
    defaultHeight: { type: Number, default: 250 },
    pollInterval: { type: Number, default: 2000 }
  }

  connect() {
    this.pinnedTasks = new Map() // taskId -> { name, lastLine, content, polling }
    this.activeTabId = null
    this.isCollapsed = false
    this.panelHeight = this.defaultHeightValue
    this.colorScheme = 'green' // 'green' or 'amber'
    
    this.loadFromStorage()
    this.setupKeyboardShortcut()
    this.setupResizeHandler()
    this.setupPinEventListener()
    this.render()
    
    // Start polling for all pinned tasks
    this.pinnedTasks.forEach((_, taskId) => {
      this.startPolling(taskId)
    })
  }

  disconnect() {
    this.removeKeyboardShortcut()
    this.removePinEventListener()
    this.pinnedTasks.forEach((_, taskId) => {
      this.stopPolling(taskId)
    })
  }

  setupPinEventListener() {
    this.pinEventHandler = (event) => {
      this.pinTask(event)
    }
    document.addEventListener('agent-terminal:pin', this.pinEventHandler)
  }

  removePinEventListener() {
    if (this.pinEventHandler) {
      document.removeEventListener('agent-terminal:pin', this.pinEventHandler)
    }
  }

  // ========================================
  // PUBLIC API (called from other controllers)
  // ========================================

  pinTask(event) {
    // Always use integer keys for consistency (Map is type-strict)
    const taskId = parseInt(event.detail.taskId, 10)
    const taskName = event.detail.taskName
    const boardIcon = event.detail.boardIcon || '📋'
    
    if (this.pinnedTasks.has(taskId)) {
      // Already pinned, just switch to it
      this.switchTab(taskId)
      return
    }
    
    this.pinnedTasks.set(taskId, {
      name: taskName || `Task #${taskId}`,
      boardIcon: boardIcon,
      lastLine: 0,
      content: [],
      polling: false
    })
    
    this.activeTabId = taskId
    this.isCollapsed = false
    this.saveToStorage()
    this.render()
    this.startPolling(taskId)
  }

  unpinTask(taskIdOrEvent) {
    let taskId
    if (typeof taskIdOrEvent === 'object' && taskIdOrEvent.currentTarget) {
      // Called from button click - stop propagation to prevent switchTab from firing
      taskIdOrEvent.stopPropagation()
      taskIdOrEvent.preventDefault()
      const btn = taskIdOrEvent.currentTarget
      taskId = parseInt(btn.dataset.taskId, 10)
    } else {
      // Ensure integer for programmatic calls
      taskId = parseInt(taskIdOrEvent, 10)
    }
    
    this.stopPolling(taskId)
    this.pinnedTasks.delete(taskId)
    
    if (this.activeTabId === taskId) {
      const keys = Array.from(this.pinnedTasks.keys())
      this.activeTabId = keys.length > 0 ? keys[0] : null
    }
    
    this.saveToStorage()
    this.render()
  }

  switchTab(taskIdOrEvent) {
    let taskId = taskIdOrEvent
    if (typeof taskIdOrEvent === 'object' && taskIdOrEvent.currentTarget) {
      taskId = parseInt(taskIdOrEvent.currentTarget.dataset.taskId, 10)
    } else {
      // Ensure integer for programmatic calls
      taskId = parseInt(taskId, 10)
    }
    
    this.activeTabId = taskId
    this.saveToStorage() // Persist active tab
    this.render()
    this.scrollToBottom()
  }

  toggle() {
    if (this.pinnedTasks.size === 0) return
    
    this.isCollapsed = !this.isCollapsed
    this.render()
  }

  toggleColorScheme() {
    this.colorScheme = this.colorScheme === 'green' ? 'amber' : 'green'
    this.saveToStorage()
    this.render()
  }

  // ========================================
  // POLLING
  // ========================================

  startPolling(taskId) {
    taskId = parseInt(taskId, 10) // Ensure integer key
    const task = this.pinnedTasks.get(taskId)
    if (!task || task.polling) return
    
    task.polling = true
    this.poll(taskId)
  }

  stopPolling(taskId) {
    taskId = parseInt(taskId, 10) // Ensure integer key
    const task = this.pinnedTasks.get(taskId)
    if (task) {
      task.polling = false
    }
  }

  async poll(taskId) {
    taskId = parseInt(taskId, 10) // Ensure integer key
    const task = this.pinnedTasks.get(taskId)
    if (!task || !task.polling) return
    
    try {
      const response = await fetch(`/api/v1/tasks/${taskId}/agent_log?since=${task.lastLine}`)
      
      if (response.ok) {
        const data = await response.json()
        
        if (data.messages && data.messages.length > 0) {
          task.content = task.content.concat(data.messages)
          task.lastLine = data.total_lines
          
          // Keep only last 200 messages to prevent memory bloat
          if (task.content.length > 200) {
            task.content = task.content.slice(-200)
          }
          
          if (this.activeTabId === taskId) {
            this.renderContent()
            this.scrollToBottom()
          }
          
          // Save to storage for persistence across tab switches and reloads
          this.saveToStorage()
        }
        
        // Update task status
        if (data.task_status) {
          task.status = data.task_status
          this.renderTabs()
        }
        
        // Stop polling if task is done
        if (!['in_progress', 'up_next'].includes(data.task_status)) {
          task.polling = false
        }
      }
    } catch (error) {
      console.error("[agent-terminal] Poll error:", error)
    }
    
    // Schedule next poll
    if (task.polling) {
      setTimeout(() => this.poll(taskId), this.pollIntervalValue)
    }
  }

  // ========================================
  // RESIZE HANDLING
  // ========================================

  setupResizeHandler() {
    this.resizing = false
    this.startY = 0
    this.startHeight = 0
    
    this.onMouseMove = this.handleMouseMove.bind(this)
    this.onMouseUp = this.handleMouseUp.bind(this)
  }

  startResize(event) {
    event.preventDefault()
    this.resizing = true
    this.startY = event.clientY
    this.startHeight = this.panelHeight
    
    document.addEventListener('mousemove', this.onMouseMove)
    document.addEventListener('mouseup', this.onMouseUp)
    document.body.style.cursor = 'ns-resize'
    document.body.style.userSelect = 'none'
  }

  handleMouseMove(event) {
    if (!this.resizing) return
    
    const delta = this.startY - event.clientY
    let newHeight = this.startHeight + delta
    
    newHeight = Math.max(this.minHeightValue, Math.min(this.maxHeightValue, newHeight))
    this.panelHeight = newHeight
    
    if (this.hasPanelTarget) {
      this.panelTarget.style.height = `${newHeight}px`
    }
  }

  handleMouseUp() {
    this.resizing = false
    document.removeEventListener('mousemove', this.onMouseMove)
    document.removeEventListener('mouseup', this.onMouseUp)
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
    
    this.saveToStorage()
  }

  // ========================================
  // KEYBOARD SHORTCUT
  // ========================================

  setupKeyboardShortcut() {
    this.keydownHandler = (event) => {
      // Ctrl+` (backtick) to toggle
      if (event.ctrlKey && event.key === '`') {
        event.preventDefault()
        this.toggle()
      }
    }
    document.addEventListener('keydown', this.keydownHandler)
  }

  removeKeyboardShortcut() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
  }

  // ========================================
  // STORAGE
  // ========================================

  loadFromStorage() {
    try {
      const data = localStorage.getItem('agentTerminal')
      if (data) {
        const parsed = JSON.parse(data)
        
        if (parsed.pinnedTaskIds && Array.isArray(parsed.pinnedTaskIds)) {
          parsed.pinnedTaskIds.forEach(id => {
            // Always use integer keys for consistency
            const taskId = parseInt(id, 10)
            this.pinnedTasks.set(taskId, {
              name: parsed.taskNames?.[id] || parsed.taskNames?.[taskId] || `Task #${taskId}`,
              boardIcon: parsed.boardIcons?.[id] || parsed.boardIcons?.[taskId] || '📋',
              lastLine: parsed.lastLines?.[taskId] || 0,
              content: parsed.contentCache?.[taskId] || [],
              polling: false
            })
          })
        }
        
        const activeId = parseInt(parsed.activeTabId, 10)
        if (activeId && this.pinnedTasks.has(activeId)) {
          this.activeTabId = activeId
        } else if (this.pinnedTasks.size > 0) {
          this.activeTabId = Array.from(this.pinnedTasks.keys())[0]
        }
        
        this.isCollapsed = parsed.isCollapsed ?? false
        this.panelHeight = parsed.panelHeight ?? this.defaultHeightValue
        this.colorScheme = parsed.colorScheme ?? 'green'
      }
    } catch (e) {
      console.error("[agent-terminal] Failed to load from storage:", e)
    }
  }

  saveToStorage() {
    try {
      const taskNames = {}
      const boardIcons = {}
      const lastLines = {}
      const contentCache = {}
      
      this.pinnedTasks.forEach((task, id) => {
        taskNames[id] = task.name
        boardIcons[id] = task.boardIcon || '📋'
        lastLines[id] = task.lastLine || 0
        // Cache last 50 messages per task (enough to restore context, not too much for localStorage)
        contentCache[id] = (task.content || []).slice(-50)
      })
      
      const data = {
        pinnedTaskIds: Array.from(this.pinnedTasks.keys()),
        taskNames,
        boardIcons,
        lastLines,
        contentCache,
        activeTabId: this.activeTabId,
        isCollapsed: this.isCollapsed,
        panelHeight: this.panelHeight,
        colorScheme: this.colorScheme
      }
      localStorage.setItem('agentTerminal', JSON.stringify(data))
    } catch (e) {
      console.error("[agent-terminal] Failed to save to storage:", e)
    }
  }

  // ========================================
  // RENDERING
  // ========================================

  render() {
    if (!this.hasPanelTarget) return
    
    const hasTabs = this.pinnedTasks.size > 0
    
    // Update floating toggle button visibility
    this.updateFloatingButton(hasTabs)
    
    if (!hasTabs) {
      this.panelTarget.classList.add('hidden')
      return
    }
    
    this.panelTarget.classList.remove('hidden')
    
    // Set color scheme data attribute
    this.panelTarget.dataset.colorScheme = this.colorScheme
    
    if (this.isCollapsed) {
      this.panelTarget.style.height = '40px'
      if (this.hasContentTarget) this.contentTarget.classList.add('hidden')
      if (this.hasResizeHandleTarget) this.resizeHandleTarget.classList.add('hidden')
    } else {
      this.panelTarget.style.height = `${this.panelHeight}px`
      if (this.hasContentTarget) this.contentTarget.classList.remove('hidden')
      if (this.hasResizeHandleTarget) this.resizeHandleTarget.classList.remove('hidden')
    }
    
    this.renderTabs()
    this.renderContent()
  }

  renderTabs() {
    if (!this.hasTabListTarget) return
    
    const isAmber = this.colorScheme === 'amber'
    const accentColor = isAmber ? 'amber' : 'green'
    
    let html = ''
    this.pinnedTasks.forEach((task, taskId) => {
      const isActive = taskId === this.activeTabId
      const statusDot = task.status === 'in_progress' 
        ? `<span class="w-2 h-2 rounded-full bg-${accentColor}-500 animate-pulse"></span>`
        : '<span class="w-2 h-2 rounded-full bg-content-muted"></span>'
      
      // Show board icon + task ID (e.g., "🦞 #60")
      const boardIcon = task.boardIcon || '📋'
      const tabLabel = `${boardIcon} #${taskId}`
      
      html += `
        <button 
          data-task-id="${taskId}"
          data-action="click->agent-terminal#switchTab"
          class="group flex items-center gap-2 px-3 py-1.5 text-xs font-mono transition-colors ${
            isActive 
              ? `bg-bg-elevated text-${accentColor}-400 border-t border-x border-${accentColor}-500/30 rounded-t` 
              : 'text-content-muted hover:text-content-secondary hover:bg-bg-surface/50'
          }"
        >
          ${statusDot}
          <span class="truncate max-w-[120px]">${tabLabel}</span>
          <button 
            type="button"
            data-task-id="${taskId}"
            data-action="click->agent-terminal#unpinTask"
            class="ml-1 opacity-0 group-hover:opacity-100 hover:text-accent transition-opacity text-xs leading-none"
            title="Unpin"
          >×</button>
        </button>
      `
    })
    
    // Add color scheme toggle button
    html += `
      <button 
        data-action="click->agent-terminal#toggleColorScheme"
        class="ml-2 px-2 py-1 text-[10px] font-mono text-content-muted hover:text-${accentColor}-400 transition-colors"
        title="Toggle color scheme (green/amber)"
      >
        ${isAmber ? '🟠' : '🟢'}
      </button>
    `
    
    this.tabListTarget.innerHTML = html
  }

  renderContent() {
    if (!this.hasContentTarget) return
    
    const task = this.pinnedTasks.get(this.activeTabId)
    
    if (!task || task.content.length === 0) {
      this.contentTarget.innerHTML = `
        <div class="flex items-center justify-center h-full text-content-muted text-sm font-mono">
          <span class="animate-pulse">⏳ Waiting for agent output...</span>
        </div>
      `
      return
    }
    
    const html = task.content.map(msg => this.renderMessage(msg)).join('')
    this.contentTarget.innerHTML = html
  }

  renderMessage(msg) {
    const isAmber = this.colorScheme === 'amber'
    const primaryColor = isAmber ? 'text-amber-400' : 'text-green-400'
    
    let icon = '📝'
    let borderColor = 'border-content-muted/30'
    let textColor = primaryColor
    
    if (msg.role === 'user') {
      icon = '👤'
      borderColor = 'border-blue-500/30'
      textColor = 'text-blue-300'
    }
    if (msg.role === 'assistant') {
      icon = '🤖'
      borderColor = isAmber ? 'border-amber-500/30' : 'border-purple-500/30'
      textColor = primaryColor
    }
    if (msg.role === 'toolResult') {
      icon = '⚙️'
      borderColor = isAmber ? 'border-orange-500/30' : 'border-amber-500/30'
      textColor = isAmber ? 'text-orange-400' : 'text-amber-400'
    }
    
    let contentHtml = ''
    if (msg.content && Array.isArray(msg.content)) {
      msg.content.forEach(item => {
        if (item.type === 'text' && item.text) {
          const text = item.text.length > 5000 ? item.text.substring(0, 5000) + '...' : item.text
          contentHtml += `<div class="${textColor} whitespace-pre-wrap break-words leading-relaxed">${this.escapeHtml(text)}</div>`
        }
        if (item.type === 'thinking' && item.text) {
          const thinking = item.text.length > 1500 ? item.text.substring(0, 1500) + '...' : item.text
          contentHtml += `<div class="${isAmber ? 'text-yellow-400/70' : 'text-purple-400/70'} italic text-xs mt-1">💭 ${this.escapeHtml(thinking)}</div>`
        }
        if (item.type === 'tool_call') {
          contentHtml += `<div class="${isAmber ? 'text-orange-400' : 'text-amber-400'} text-xs mt-1">🔧 ${this.escapeHtml(item.name || 'tool')}</div>`
        }
        if (item.type === 'tool_result' && item.text) {
          const result = item.text.length > 3000 ? item.text.substring(0, 3000) + '...' : item.text
          contentHtml += `<div class="${isAmber ? 'text-orange-300/60' : 'text-amber-300/60'} text-xs mt-1 font-mono bg-black/30 px-2 py-1 rounded max-h-16 overflow-y-auto">${this.escapeHtml(result)}</div>`
        }
      })
    }
    
    return `
      <div class="flex items-start gap-2 p-2 border-l-2 ${borderColor} mb-1 hover:bg-bg-surface/30 transition-colors">
        <span class="flex-shrink-0 text-xs">${icon}</span>
        <div class="flex-1 min-w-0 text-xs font-mono">
          ${contentHtml || '<span class="text-content-muted">...</span>'}
        </div>
      </div>
    `
  }

  scrollToBottom() {
    if (this.hasContentTarget) {
      requestAnimationFrame(() => {
        this.contentTarget.scrollTop = this.contentTarget.scrollHeight
      })
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // ========================================
  // FLOATING TOGGLE BUTTON (mobile-friendly)
  // ========================================

  updateFloatingButton(hasTabs) {
    if (!this.hasFloatingToggleTarget) return
    
    if (hasTabs) {
      // Show floating button when there are pinned tabs
      this.floatingToggleTarget.classList.remove('hidden')
      this.floatingToggleTarget.classList.add('flex')
      
      // Update badge with tab count
      if (this.hasFloatingBadgeTarget) {
        const count = this.pinnedTasks.size
        this.floatingBadgeTarget.textContent = count
        if (count > 0) {
          this.floatingBadgeTarget.classList.remove('hidden')
          this.floatingBadgeTarget.classList.add('flex')
        } else {
          this.floatingBadgeTarget.classList.add('hidden')
          this.floatingBadgeTarget.classList.remove('flex')
        }
      }
      
      // Change color based on scheme
      const isAmber = this.colorScheme === 'amber'
      this.floatingToggleTarget.classList.toggle('bg-green-600', !isAmber)
      this.floatingToggleTarget.classList.toggle('hover:bg-green-500', !isAmber)
      this.floatingToggleTarget.classList.toggle('shadow-green-500/30', !isAmber)
      this.floatingToggleTarget.classList.toggle('bg-amber-600', isAmber)
      this.floatingToggleTarget.classList.toggle('hover:bg-amber-500', isAmber)
      this.floatingToggleTarget.classList.toggle('shadow-amber-500/30', isAmber)
    } else {
      // Hide when no tabs
      this.floatingToggleTarget.classList.add('hidden')
      this.floatingToggleTarget.classList.remove('flex')
    }
  }
}
