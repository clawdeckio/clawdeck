import { Controller } from "@hotwired/stimulus"

// Keep quick-action interactions isolated from the card link and Sortable drag handlers.
export default class extends Controller {
  stop(event) {
    event.stopPropagation()
  }
}
