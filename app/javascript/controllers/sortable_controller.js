import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Connects to data-controller="sortable"
// Used for kanban board column drag-and-drop
export default class extends Controller {
  static values = {
    group: String,
    status: String,
    url: String
  }

  connect() {
    // Disable sorting within in_review and done columns (they auto-sort by date)
    const isAutoSortColumn = ['in_review', 'done'].includes(this.statusValue)
    
    const options = {
      animation: 150,
      ghostClass: "sortable-ghost",
      dragClass: "sortable-drag",
      delay: 150,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      emptyInsertThreshold: 50,
      swapThreshold: 0.65,
      invertSwap: true,
      sort: !isAutoSortColumn, // Disable reordering within in_review/done
      filter: '[style*="display: none"]',
      onStart: this.handleStart.bind(this),
      onEnd: this.handleEnd.bind(this),
      onMove: this.move.bind(this),
      onChange: this.handleChange.bind(this),
      onUpdate: this.handleUpdate.bind(this)
    }

    // Board mode: enable cross-column dragging
    if (this.hasGroupValue) {
      options.group = this.groupValue
      options.onAdd = this.handleAdd.bind(this)
    }

    this.sortable = Sortable.create(this.element, options)
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  // Dispatch event when drag starts (for delete zone visibility)
  handleStart(event) {
    document.dispatchEvent(new CustomEvent("sortable:dragstart", { detail: { item: event.item } }))
  }

  // Dispatch event when drag ends (for delete zone visibility)
  handleEnd(event) {
    document.dispatchEvent(new CustomEvent("sortable:dragend", { detail: { item: event.item } }))

    // Remove column highlight from all columns
    document.querySelectorAll('.column-drag-over').forEach(el => {
      el.classList.remove('column-drag-over')
    })
  }

  // Handle visual feedback during drag
  handleChange(event) {
    // Add column highlight to the column being dragged over
    const targetColumn = event.to.closest('[data-status]')
    if (targetColumn) {
      // Remove highlight from all columns first
      document.querySelectorAll('.column-drag-over').forEach(el => {
        el.classList.remove('column-drag-over')
      })
      // Add highlight to current column
      targetColumn.classList.add('column-drag-over')
    }
  }

  move(event) {
    // Don't allow moving hidden (filtered) items
    if (event.related?.style?.display === 'none') {
      return false
    }
    return true
  }

  // Handle reordering within the same column
  async handleUpdate(event) {
    if (!this.hasUrlValue) return

    // Get all task IDs in their new order
    const taskIds = Array.from(this.element.querySelectorAll("[data-task-id]"))
      .map(el => el.dataset.taskId)

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ task_ids: taskIds, status: this.statusValue })
      })

      if (!response.ok) {
        console.error("Failed to update task positions")
      }
    } catch (error) {
      console.error("Error updating task positions:", error)
    }
  }

  // Handle task added from another column (board mode)
  async handleAdd(event) {
    if (!this.hasUrlValue || !this.hasStatusValue) return

    const taskId = event.item.dataset.taskId
    const newStatus = this.statusValue
    const oldStatus = event.from.id.replace("column-", "")

    // Get all task IDs in their new order (including the newly added one)
    const taskIds = Array.from(this.element.querySelectorAll("[data-task-id]"))
      .map(el => el.dataset.taskId)

    // Update the task's data attributes
    event.item.dataset.taskStatus = newStatus

    // Update column counters
    this.updateColumnCount(oldStatus, -1)
    this.updateColumnCount(newStatus, 1)

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ task_id: taskId, status: newStatus, task_ids: taskIds })
      })

      if (!response.ok) {
        console.error("Failed to update task status")
        return
      }

      // Replace the card HTML to update status-dependent elements (NEXT button, etc.)
      const data = await response.json()
      if (data.html && data.task_id) {
        const cardElement = document.getElementById(`task_${data.task_id}`)
        if (cardElement) {
          cardElement.outerHTML = data.html
        }
      }
    } catch (error) {
      console.error("Error updating task status:", error)
    }
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']").content
  }

  updateColumnCount(status, delta) {
    // Update column header count
    const countEl = document.getElementById(`column-${status}-count`)
    if (countEl) {
      const currentCount = parseInt(countEl.textContent, 10) || 0
      countEl.textContent = currentCount + delta
    }
    // Update header stats count
    const headerCountEl = document.getElementById(`header-${status}-count`)
    if (headerCountEl) {
      const currentCount = parseInt(headerCountEl.textContent, 10) || 0
      headerCountEl.textContent = currentCount + delta
    }
  }
}
