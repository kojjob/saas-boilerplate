import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reset-form"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.initialHeight = null
  }

  reset(event) {
    // Reset form after successful Turbo submission
    if (event.detail.success) {
      this.element.reset()

      // Reset textarea height
      const textarea = this.element.querySelector('textarea')
      if (textarea) {
        textarea.style.height = 'auto'
      }
    }
  }

  autoResize(event) {
    const textarea = event.target

    // Store initial height on first resize
    if (!this.initialHeight) {
      this.initialHeight = textarea.scrollHeight
    }

    // Reset height to auto to get the correct scrollHeight
    textarea.style.height = 'auto'

    // Set height based on content, with max height
    const maxHeight = 200 // 200px max height
    const newHeight = Math.min(textarea.scrollHeight, maxHeight)
    textarea.style.height = `${newHeight}px`

    // Add overflow-y auto if content exceeds max height
    if (textarea.scrollHeight > maxHeight) {
      textarea.style.overflowY = 'auto'
    } else {
      textarea.style.overflowY = 'hidden'
    }
  }

  submitOnEnter(event) {
    // Submit on Enter, but allow Shift+Enter for new lines
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()

      // Only submit if there's content
      const textarea = event.target
      if (textarea.value.trim().length > 0) {
        this.element.requestSubmit()
      }
    }
  }
}
