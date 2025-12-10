import { Controller } from "@hotwired/stimulus"

// Onboarding Checklist Controller
// Provides smooth animations and progress tracking for the onboarding experience
export default class extends Controller {
  static values = {
    dismissUrl: String
  }

  connect() {
    // Add entrance animation
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-10px)"

    requestAnimationFrame(() => {
      this.element.style.transition = "opacity 0.3s ease, transform 0.3s ease"
      this.element.style.opacity = "1"
      this.element.style.transform = "translateY(0)"
    })
  }

  disconnect() {
    // Clean up if needed
  }

  // Optional: Add confetti or celebration animation when completed
  celebrate() {
    // This could be extended to show confetti using a library like canvas-confetti
    console.log("Onboarding completed! 🎉")
  }
}
