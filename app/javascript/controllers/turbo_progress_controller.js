import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-progress"
export default class extends Controller {
  static targets = ["spinner"]

  connect() {
    // Listen to Turbo form submission events
    document.addEventListener("turbo:submit-start", this.showSpinner.bind(this))
    document.addEventListener("turbo:submit-end", this.hideSpinner.bind(this))
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener("turbo:submit-start", this.showSpinner.bind(this))
    document.removeEventListener("turbo:submit-end", this.hideSpinner.bind(this))
  }

  showSpinner(event) {
    if (!this.hasSpinnerTarget) return
    this.spinnerTarget.classList.remove("opacity-0")
    this.spinnerTarget.classList.add("opacity-100")
  }

  hideSpinner(event) {
    if (!this.hasSpinnerTarget) return
    this.spinnerTarget.classList.remove("opacity-100")
    this.spinnerTarget.classList.add("opacity-0")
  }
}
