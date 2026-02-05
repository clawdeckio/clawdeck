import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loading", "textarea"]
  static values = { url: String }

  connect() {
    this.fetchSuggestion()
  }

  async fetchSuggestion() {
    if (!this.urlValue) {
      this.showTextarea()
      return
    }

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok) {
        throw new Error('Failed to fetch suggestion')
      }

      const data = await response.json()
      
      if (this.hasTextareaTarget && data.suggested_followup) {
        this.textareaTarget.value = data.suggested_followup
      }
    } catch (error) {
      console.error("Failed to fetch suggestion:", error)
      // Show a default message on error
      if (this.hasTextareaTarget) {
        this.textareaTarget.value = "Review the task results and determine next steps."
      }
    } finally {
      this.showTextarea()
    }
  }

  showTextarea() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
    if (this.hasTextareaTarget) {
      this.textareaTarget.classList.remove("hidden")
    }
  }
}
