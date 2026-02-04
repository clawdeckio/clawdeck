import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="new-task-modal"
export default class extends Controller {
  static targets = ["priorityField", "priorityButton", "priorityGroup", "statusField", "blockedField"]

  connect() {
    // Update priority UI on connect to show default selection
    this.updatePriorityUI()
  }

  selectPriority(event) {
    event.preventDefault()
    event.stopPropagation()

    const value = event.currentTarget.dataset.priorityValue
    if (!value) return

    if (this.hasPriorityFieldTarget) {
      this.priorityFieldTarget.value = value
    }

    this.updatePriorityUI()
  }

  updatePriorityUI() {
    if (!this.hasPriorityButtonTarget) return

    const current = this.hasPriorityFieldTarget ? this.priorityFieldTarget.value : 'none'

    this.priorityButtonTargets.forEach((btn) => {
      const val = btn.dataset.priorityValue
      const isSelected = (val === current)
      btn.setAttribute('aria-pressed', isSelected ? 'true' : 'false')
    })
  }

  toggleRecurring(event) {
    const checkbox = event.currentTarget
    const recurringOptions = document.getElementById('recurring-options')
    if (!recurringOptions) return

    if (checkbox.checked) {
      recurringOptions.classList.remove('hidden')
    } else {
      recurringOptions.classList.add('hidden')
    }
  }
}
