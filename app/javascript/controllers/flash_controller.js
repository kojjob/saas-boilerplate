import { Controller } from "@hotwired/stimulus"

// Flash message controller with auto-dismiss and animations
export default class extends Controller {
  static targets = ["progress"]
  static values = {
    autoDismiss: { type: Boolean, default: true },
    dismissDelay: { type: Number, default: 5000 }
  }

  connect() {
    // Start auto-dismiss timer if enabled
    if (this.autoDismissValue) {
      this.startAutoDismiss()
    }

    // Pause auto-dismiss on hover
    this.element.addEventListener("mouseenter", this.pauseAutoDismiss.bind(this))
    this.element.addEventListener("mouseleave", this.resumeAutoDismiss.bind(this))
  }

  disconnect() {
    this.clearTimer()
    this.element.removeEventListener("mouseenter", this.pauseAutoDismiss.bind(this))
    this.element.removeEventListener("mouseleave", this.resumeAutoDismiss.bind(this))
  }

  startAutoDismiss() {
    this.dismissTimer = setTimeout(() => {
      this.dismiss()
    }, this.dismissDelayValue)

    // Start progress bar animation
    if (this.hasProgressTarget) {
      this.progressTarget.style.animationPlayState = "running"
    }
  }

  pauseAutoDismiss() {
    this.clearTimer()

    // Pause progress bar animation
    if (this.hasProgressTarget) {
      this.progressTarget.style.animationPlayState = "paused"
    }
  }

  resumeAutoDismiss() {
    if (this.autoDismissValue) {
      // Calculate remaining time based on progress bar width
      const progressWidth = this.hasProgressTarget ?
        parseFloat(getComputedStyle(this.progressTarget).width) : 0
      const totalWidth = this.element.offsetWidth
      const remainingRatio = progressWidth / totalWidth
      const remainingTime = remainingRatio * this.dismissDelayValue

      this.dismissTimer = setTimeout(() => {
        this.dismiss()
      }, remainingTime)

      // Resume progress bar animation
      if (this.hasProgressTarget) {
        this.progressTarget.style.animationPlayState = "running"
      }
    }
  }

  dismiss() {
    this.clearTimer()

    // Animate out
    this.element.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(100%)"

    // Remove element after animation
    setTimeout(() => {
      this.element.remove()
    }, 200)
  }

  clearTimer() {
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
      this.dismissTimer = null
    }
  }
}
