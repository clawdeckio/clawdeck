import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="comment-form"
export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.autoResize()
  }

  submitOnEnter(event) {
    // Submit on Enter without Shift
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.inputTarget.value.trim()) {
        this.element.requestSubmit()
        this.inputTarget.value = ""
        this.autoResize()
      }
    }
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 120) + "px"
  }
}
