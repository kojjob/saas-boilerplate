import { Controller } from "@hotwired/stimulus"

// Handles copying text to clipboard with visual feedback
export default class extends Controller {
  static targets = ["source", "button", "copyIcon", "checkIcon", "label"]

  async copy() {
    const text = this.sourceTarget.value || this.sourceTarget.textContent

    try {
      await navigator.clipboard.writeText(text)
      this.showSuccess()
    } catch (err) {
      // Fallback for older browsers
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()

    try {
      document.execCommand("copy")
      this.showSuccess()
    } catch (err) {
      console.error("Failed to copy:", err)
    } finally {
      document.body.removeChild(textarea)
    }
  }

  showSuccess() {
    // Toggle icons if they exist
    if (this.hasCopyIconTarget && this.hasCheckIconTarget) {
      this.copyIconTarget.classList.add("hidden")
      this.checkIconTarget.classList.remove("hidden")
    }

    // Update label if it exists
    if (this.hasLabelTarget) {
      this.originalLabel = this.labelTarget.textContent
      this.labelTarget.textContent = "Copied!"
    }

    // Add visual feedback to button
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.add("text-emerald-600", "border-emerald-300")
    }

    // Reset after 2 seconds
    setTimeout(() => this.reset(), 2000)
  }

  reset() {
    if (this.hasCopyIconTarget && this.hasCheckIconTarget) {
      this.copyIconTarget.classList.remove("hidden")
      this.checkIconTarget.classList.add("hidden")
    }

    if (this.hasLabelTarget && this.originalLabel) {
      this.labelTarget.textContent = this.originalLabel
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.classList.remove("text-emerald-600", "border-emerald-300")
    }
  }
}
