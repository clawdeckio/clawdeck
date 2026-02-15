import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="command-bar"
export default class extends Controller {
  static targets = ["dialog", "backdrop", "input", "body", "searchResults", "actionsPanel", "agentPanel", "agentMessages", "modeIcon", "backButton", "escBadge"]
  static values = { mode: { type: String, default: "search" }, open: { type: Boolean, default: false } }

  connect() {
    this.boundKeydown = this.globalKeydown.bind(this)
    this.boundToggle = this.toggle.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
    document.addEventListener("command-bar:toggle", this.boundToggle)
    this.messages = []
    this.typing = false
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    document.removeEventListener("command-bar:toggle", this.boundToggle)
  }

  globalKeydown(e) {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault()
      this.toggle()
    }
    if (e.key === "Escape" && this.openValue) {
      e.preventDefault()
      this.close()
    }
  }

  toggle() {
    this.openValue ? this.close() : this.open()
  }

  open() {
    this.openValue = true
    this.modeValue = "search"
    this.messages = []
    this.dialogTarget.classList.remove("hidden")
    this.backdropTarget.classList.remove("hidden")
    this.showSearchMode()
    requestAnimationFrame(() => {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    })
  }

  close() {
    this.openValue = false
    this.dialogTarget.classList.add("hidden")
    this.backdropTarget.classList.add("hidden")
    this.inputTarget.value = ""
    this.messages = []
    this.typing = false
    this.modeValue = "search"
  }

  onInputKeydown(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      if (this.modeValue === "agent") {
        this.sendMessage()
      } else {
        // Select first search result
        const firstLink = this.searchResultsTarget.querySelector("a, button")
        if (firstLink) firstLink.click()
      }
    }
  }

  onInput() {
    if (this.modeValue === "search") {
      this.search()
    }
  }

  // --- Search mode ---

  showSearchMode() {
    this.modeValue = "search"
    this.agentPanelTarget.classList.add("hidden")
    this.searchResultsTarget.classList.remove("hidden")
    this.actionsPanelTarget.classList.remove("hidden")
    this.updateModeIcon()
    this.updateInputPlaceholder()
    if (this.hasBackButtonTarget) this.backButtonTarget.classList.add("hidden")
    this.search()
  }

  search() {
    const query = this.inputTarget.value.trim().toLowerCase()

    if (!query) {
      this.searchResultsTarget.classList.add("hidden")
      this.actionsPanelTarget.classList.remove("hidden")
      return
    }

    this.actionsPanelTarget.classList.add("hidden")
    this.searchResultsTarget.classList.remove("hidden")

    // Client-side search from DOM
    const cards = document.querySelectorAll("[data-task-id]")
    const results = []

    cards.forEach(card => {
      const nameEl = card.querySelector(".text-sm.font-medium")
      if (!nameEl) return
      const name = nameEl.textContent.trim()
      if (name.toLowerCase().includes(query)) {
        const link = card.querySelector("a[href]")
        results.push({
          name,
          status: card.dataset.taskStatus,
          href: link ? link.getAttribute("href") : null,
          taskId: card.dataset.taskId,
        })
      }
    })

    const shown = results.slice(0, 6)
    if (shown.length === 0) {
      this.searchResultsTarget.innerHTML = `<div class="py-5 text-center text-xs text-[#444]">No cards found for &ldquo;${this.escapeHtml(this.inputTarget.value.trim())}&rdquo;</div>`
      return
    }

    const statusLabels = { inbox: "Inbox", up_next: "Up Next", in_progress: "In Progress", in_review: "In Review", done: "Done" }
    const statusDots = { inbox: "#888", up_next: "#60a5fa", in_progress: "#fbbf24", in_review: "#a78bfa", done: "#34d399" }

    this.searchResultsTarget.innerHTML = `
      <div class="px-2 py-1">
        <div class="px-2.5 py-1.5 text-[10px] font-bold uppercase tracking-[0.06em] text-[#444]">Cards</div>
        ${shown.map(r => {
          const label = statusLabels[r.status] || r.status
          const dot = statusDots[r.status] || "#444"
          return `<a href="${r.href}" data-turbo-frame="task_panel" data-action="click->command-bar#close"
                    class="flex items-center gap-2.5 w-full px-2.5 py-[9px] rounded-lg hover:bg-white/[0.04] transition-colors cursor-pointer no-underline">
                   <div class="w-1.5 h-1.5 rounded-full flex-shrink-0" style="background:${dot}"></div>
                   <span class="flex-1 text-[13px] font-medium text-[#ccc] truncate">${this.escapeHtml(r.name)}</span>
                   <div class="flex items-center gap-1">
                     <div class="w-[5px] h-[5px] rounded-full" style="background:${dot}"></div>
                     <span class="text-[10px] font-medium text-[#444]">${label}</span>
                   </div>
                 </a>`
        }).join("")}
      </div>`
  }

  // --- Agent mode ---

  switchToAgent(e) {
    const prompt = e?.currentTarget?.dataset?.prompt || ""
    this.modeValue = "agent"
    this.messages = []
    this.typing = false
    this.searchResultsTarget.classList.add("hidden")
    this.actionsPanelTarget.classList.add("hidden")
    this.agentPanelTarget.classList.remove("hidden")
    this.updateModeIcon()
    this.updateInputPlaceholder()
    if (this.hasBackButtonTarget) this.backButtonTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.renderAgentPanel()

    if (prompt) {
      this.sendAgentMessage(prompt)
    }
  }

  switchToSearch() {
    this.inputTarget.value = ""
    this.showSearchMode()
  }

  sendMessage() {
    const text = this.inputTarget.value.trim()
    if (!text) return
    this.inputTarget.value = ""
    this.sendAgentMessage(text)
  }

  sendAgentMessage(text) {
    this.messages.push({ type: "user", text })
    this.typing = true
    this.renderAgentPanel()
    this.scrollAgentToBottom()

    setTimeout(() => {
      this.typing = false
      this.messages.push({ type: "agent", text: this.getAgentResponse(text) })
      this.renderAgentPanel()
      this.scrollAgentToBottom()
    }, 1200)
  }

  executeAction(e) {
    const actionId = e.currentTarget.dataset.actionId
    if (actionId === "add") {
      this.close()
      // Try to click the first inline-add button on the page
      const addBtn = document.querySelector("[data-action='click->inline-add#show']")
      if (addBtn) addBtn.click()
      return
    }
    // All others switch to agent mode
    const prompts = {
      agent: "",
      today: "What should I focus on today?",
      breakdown: "Break down my top priority task",
      draft: "Help me draft an announcement post",
      recap: "Give me a weekly recap",
    }
    this.modeValue = "agent"
    this.messages = []
    this.typing = false
    this.searchResultsTarget.classList.add("hidden")
    this.actionsPanelTarget.classList.add("hidden")
    this.agentPanelTarget.classList.remove("hidden")
    this.updateModeIcon()
    this.updateInputPlaceholder()
    if (this.hasBackButtonTarget) this.backButtonTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.renderAgentPanel()

    const prompt = prompts[actionId] || ""
    if (prompt) this.sendAgentMessage(prompt)
  }

  renderAgentPanel() {
    if (!this.hasAgentMessagesTarget) return

    if (this.messages.length === 0 && !this.typing) {
      // Empty state
      this.agentMessagesTarget.innerHTML = `
        <div class="py-5 text-center">
          <div class="text-[28px] mb-2.5">🤖</div>
          <div class="text-[13px] font-semibold text-[#666]">Ask me anything about your tasks</div>
          <div class="text-[11px] font-medium text-[#444] mt-1">I can prioritize, break down tasks, draft content, or recap your week</div>
          <div class="flex gap-[5px] justify-center mt-4 flex-wrap">
            ${["What should I focus on?", "Break down top task", "Draft X post", "Weekly recap"].map(q =>
              `<button data-action="click->command-bar#chipSend" data-prompt="${this.escapeHtml(q)}"
                       class="text-[11px] font-medium py-[5px] px-[11px] rounded-[7px] cursor-pointer text-[#999]"
                       style="background:rgba(251,191,36,0.06);border:1px solid rgba(251,191,36,0.10)">${this.escapeHtml(q)}</button>`
            ).join("")}
          </div>
        </div>`
      return
    }

    let html = ""
    this.messages.forEach(m => {
      if (m.type === "user") {
        html += `<div class="self-end max-w-[88%] whitespace-pre-wrap" style="padding:9px 13px;border-radius:12px 12px 3px 12px;background:rgba(255,255,255,0.08);border:1px solid rgba(255,255,255,0.08);color:#ddd;font-size:12.5px;line-height:1.55">${this.escapeHtml(m.text)}</div>`
      } else {
        html += `<div class="self-start max-w-[88%] whitespace-pre-wrap" style="padding:9px 13px;border-radius:12px 12px 12px 3px;background:rgba(251,191,36,0.05);border:1px solid rgba(251,191,36,0.08);color:#bbb;font-size:12.5px;line-height:1.55">${this.escapeHtml(m.text)}</div>`
      }
    })

    if (this.typing) {
      html += `<div class="self-start" style="padding:9px 13px;border-radius:12px 12px 12px 3px;background:rgba(251,191,36,0.05);border:1px solid rgba(251,191,36,0.08);display:flex;align-items:center;gap:6px">
        <div style="display:flex;gap:3px">
          <div class="cmd-dot" style="animation-delay:0s"></div>
          <div class="cmd-dot" style="animation-delay:0.15s"></div>
          <div class="cmd-dot" style="animation-delay:0.3s"></div>
        </div>
      </div>`
    }

    html += `<div data-command-bar-target="scrollAnchor"></div>`
    this.agentMessagesTarget.innerHTML = html
  }

  chipSend(e) {
    const prompt = e.currentTarget.dataset.prompt
    if (prompt) this.sendAgentMessage(prompt)
  }

  scrollAgentToBottom() {
    requestAnimationFrame(() => {
      const anchor = this.agentMessagesTarget.querySelector("[data-command-bar-target='scrollAnchor']")
      if (anchor) anchor.scrollIntoView({ behavior: "smooth" })
    })
  }

  // --- Helpers ---

  updateModeIcon() {
    if (!this.hasModeIconTarget) return
    if (this.modeValue === "agent") {
      this.modeIconTarget.innerHTML = `<span class="text-base">🤖</span>`
    } else {
      this.modeIconTarget.innerHTML = `<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="opacity:0.3"><circle cx="7" cy="7" r="5" stroke="#888" stroke-width="1.5"/><path d="M11 11L14 14" stroke="#888" stroke-width="1.5" stroke-linecap="round"/></svg>`
    }
  }

  updateInputPlaceholder() {
    if (this.modeValue === "agent") {
      this.inputTarget.placeholder = "Ask your agent anything..."
    } else {
      this.inputTarget.placeholder = "Search cards, ask agent, or take an action..."
    }
  }

  getAgentResponse(text) {
    const t = text.toLowerCase()
    if (t.includes("focus") || t.includes("today") || t.includes("priorit")) {
      return "Looking at your board, here's what I'd tackle:\n\n1. Review the board limit enforcement card — I've finished it, just needs your eyes\n2. Polar.sh integration — I'm on it but the webhook handler needs your input\n3. RevenueCat for Gratu — this blocks your App Store launch\n\nWant me to move these to In Progress?"
    }
    if (t.includes("break") || t.includes("subtask")) {
      return "I'd break \"Integrate Polar.sh payments\" into:\n\n1. Set up Polar.sh account & products ✅\n2. Implement webhook handler for payment events\n3. Create billing settings page UI\n4. Add subscription status to user model\n5. Test end-to-end payment flow\n\nWant me to add these as subtasks?"
    }
    if (t.includes("draft") || t.includes("post") || t.includes("announce")) {
      return "Here's a draft for tini.bio:\n\n\"🔗 Built this for founders who hate bloated link-in-bio tools.\n\ntini.bio — dead simple. Beautifully minimal.\n\nNo templates. No analytics dashboards. Just your links.\n\nFree → tini.bio\"\n\nWant me to tweak the tone or make it longer?"
    }
    if (t.includes("recap") || t.includes("week") || t.includes("summary")) {
      return "This week across your projects:\n\n🦞 ClawDeck — 7 cards completed, billing flow nearly done\n🔗 tini.bio — 2 cards moved forward, AppSumo still in inbox\n🙏 Gratu — RevenueCat blocked, needs your attention\n📬 nod.so — 1 card, pricing research queued\n\nBiggest win: the agent knocked out 5 ClawDeck tasks autonomously."
    }
    return "I can help with that. What specifically would you like me to do?"
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
