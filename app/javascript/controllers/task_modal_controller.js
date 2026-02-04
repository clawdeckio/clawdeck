import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="task-modal"
export default class extends Controller {
  static targets = ["modal", "backdrop", "form", "nameField", "descriptionField", "submitButton", "priorityField", "priorityButton", "priorityGroup", "dueDateField", "dueDateDisplay", "recurringCheckbox", "recurringOptions"]
  static values = { taskId: Number }

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.boundResizeDescription = this.resizeDescription.bind(this)
    this.autoSaveTimeout = null

    // Auto-open the modal when it's loaded
    setTimeout(() => {
      this.open()
      this.resizeDescription()
      this.updatePriorityUI()
    }, 10)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    // Clear any pending auto-save
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
  }

  open(event) {
    // Prevent the click from bubbling up to the card (which would also trigger edit mode)
    if (event) {
      event.stopPropagation()
    }

    // Add document-level listener for ESC key
    document.addEventListener("keydown", this.boundHandleKeydown)

    // Show backdrop
    this.backdropTarget.classList.remove("hidden")
    setTimeout(() => {
      this.backdropTarget.classList.remove("opacity-0")
    }, 10)

    // Show panel (slide in from right)
    this.modalTarget.classList.remove("hidden")
    setTimeout(() => {
      this.modalTarget.classList.remove("translate-x-full")
    }, 10)
  }

  close() {
    // Save any pending changes before closing
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
      this.autoSaveTimeout = null
      this.save()
    }

    // Hide panel (slide out to right)
    this.modalTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.add("opacity-0")

    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      this.backdropTarget.classList.add("hidden")

      // Apply any pending turbo stream updates now that modal is closing
      if (this.pendingTurboStream) {
        Turbo.renderStreamMessage(this.pendingTurboStream)
        this.pendingTurboStream = null
      }

      // Clear the turbo frame to remove the panel
      const taskPanelFrame = document.getElementById('task_panel')
      if (taskPanelFrame) {
        taskPanelFrame.innerHTML = ''
      }
    }, 300) // Match the duration-300 transition

    // Remove ESC listener
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  save() {
    // Submit form data via fetch to avoid Turbo navigation/panel closing
    const form = this.formTarget
    const formData = new FormData(form)
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken
      }
    }).then(response => {
      if (response.ok) {
        return response.text()
      }
    }).then(html => {
      if (html) {
        // Parse the turbo-stream response
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const streams = doc.querySelectorAll('turbo-stream')

        let activityStreams = ''
        let otherStreams = ''

        streams.forEach(stream => {
          const target = stream.getAttribute('target') || ''
          // Apply activity updates immediately
          if (target.startsWith('task-activities-')) {
            activityStreams += stream.outerHTML
          } else {
            otherStreams += stream.outerHTML
          }
        })

        // Apply activity updates now
        if (activityStreams) {
          Turbo.renderStreamMessage(activityStreams)
        }

        // Store other updates for when modal closes
        if (otherStreams) {
          this.pendingTurboStream = otherStreams
        }
      }
    })
  }

  scheduleAutoSave() {
    // Debounce auto-save to avoid too many requests
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
    this.autoSaveTimeout = setTimeout(() => {
      this.save()
      this.autoSaveTimeout = null
    }, 500) // Save 500ms after user stops typing
  }

  handleKeydown(event) {
    // Close on ESC
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  resizeDescription() {
    if (this.hasDescriptionFieldTarget) {
      const textarea = this.descriptionFieldTarget
      const maxHeight = 256 // max-h-64 = 16rem = 256px
      const minHeight = 80 // 5rem minimum

      // Reset height to 0 to get accurate scrollHeight
      textarea.style.height = '0'

      // Calculate the desired height, respecting min and max
      const desiredHeight = Math.max(textarea.scrollHeight, minHeight)
      const newHeight = Math.min(desiredHeight, maxHeight)

      textarea.style.height = newHeight + 'px'

      // Add input listener to auto-resize as user types
      textarea.addEventListener('input', this.boundResizeDescription)
    }
  }

  selectPriority(event) {
    const value = event.currentTarget.dataset.priorityValue
    if (!value) return
    if (this.hasPriorityFieldTarget) {
      this.priorityFieldTarget.value = value
    }
    this.updatePriorityUI()
    // Auto-save when priority changes
    this.save()
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

  onDueDateChange() {
    // Due date changed via datepicker - save the form
    this.save()
  }

  toggleRecurring() {
    if (!this.hasRecurringOptionsTarget) return
    const checkbox = this.recurringCheckboxTarget
    if (checkbox.checked) {
      this.recurringOptionsTarget.classList.remove('hidden')
    } else {
      this.recurringOptionsTarget.classList.add('hidden')
    }
  }
}
