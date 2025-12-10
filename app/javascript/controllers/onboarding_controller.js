import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    // Send AJAX request to dismiss the onboarding
    fetch("/onboarding/dismiss", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      }
    }).then(response => {
      if (response.ok) {
        // Animate out the checklist
        this.element.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
        this.element.style.opacity = "0"
        this.element.style.transform = "translateY(-10px)"

        setTimeout(() => {
          this.element.remove()
        }, 300)
      }
    })
  }
}
