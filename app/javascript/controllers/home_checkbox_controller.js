import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { taskId: Number, boardId: Number, completed: Boolean, color: String }
  static targets = ["checkbox", "title"]

  toggle() {
    const newCompleted = !this.completedValue
    this.completedValue = newCompleted

    // Optimistic UI update
    this.updateUI(newCompleted)

    // Send PATCH request
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(`/boards/${this.boardIdValue}/tasks/${this.taskIdValue}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify({
        task: {
          status: newCompleted ? "done" : "up_next",
          activity_source: "web"
        }
      })
    }).catch(() => {
      // Revert on failure
      this.completedValue = !newCompleted
      this.updateUI(!newCompleted)
    })
  }

  updateUI(completed) {
    const card = this.element
    const checkbox = this.checkboxTarget
    const title = this.titleTarget
    const color = this.colorValue || "#888888"

    // Convert hex to rgba
    const hexToRgba = (hex, alpha) => {
      const h = hex.replace("#", "")
      const r = parseInt(h.substring(0, 2), 16)
      const g = parseInt(h.substring(2, 4), 16)
      const b = parseInt(h.substring(4, 6), 16)
      return `rgba(${r},${g},${b},${alpha})`
    }

    if (completed) {
      card.style.background = "rgba(255,255,255,0.015)"
      card.style.borderColor = "rgba(255,255,255,0.03)"
      card.style.opacity = "0.35"
      checkbox.style.background = color
      checkbox.style.border = "none"
      checkbox.innerHTML = '<svg width="11" height="11" viewBox="0 0 16 16" fill="none"><path d="M3 8.5L6.5 12L13 4" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>'
      title.style.color = "#444"
      title.style.textDecoration = "line-through"
    } else {
      card.style.background = "rgba(255,255,255,0.035)"
      card.style.borderColor = "rgba(255,255,255,0.06)"
      card.style.opacity = "1"
      checkbox.style.background = "transparent"
      checkbox.style.border = `2px solid ${hexToRgba(color, 0.25)}`
      checkbox.innerHTML = ""
      title.style.color = "#ddd"
      title.style.textDecoration = "none"
    }
  }
}
