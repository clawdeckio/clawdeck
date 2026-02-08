import { Controller } from "@hotwired/stimulus"

// Prevent quick-action buttons from triggering the underlying card click
// (which opens the task panel) and from initiating drag interactions.
export default class extends Controller {
  stop(event) {
    event.preventDefault()
    event.stopPropagation()
  }
}
