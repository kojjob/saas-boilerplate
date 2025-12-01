import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pricing-toggle"
// Toggles between monthly and annual pricing with smooth animations

export default class extends Controller {
  static targets = ["monthly", "annual", "toggle", "savings"]
  static values = {
    annual: { type: Boolean, default: false }
  }

  connect() {
    this.updateDisplay()
  }

  toggle() {
    this.annualValue = !this.annualValue
    this.updateDisplay()
  }

  updateDisplay() {
    // Update toggle position
    if (this.hasToggleTarget) {
      if (this.annualValue) {
        this.toggleTarget.classList.add("translate-x-6")
        this.toggleTarget.classList.remove("translate-x-1")
      } else {
        this.toggleTarget.classList.remove("translate-x-6")
        this.toggleTarget.classList.add("translate-x-1")
      }
    }

    // Show/hide monthly prices
    this.monthlyTargets.forEach((el) => {
      if (this.annualValue) {
        el.classList.add("hidden")
      } else {
        el.classList.remove("hidden")
      }
    })

    // Show/hide annual prices
    this.annualTargets.forEach((el) => {
      if (this.annualValue) {
        el.classList.remove("hidden")
      } else {
        el.classList.add("hidden")
      }
    })

    // Show/hide savings badges
    this.savingsTargets.forEach((el) => {
      if (this.annualValue) {
        el.classList.remove("opacity-0", "scale-0")
        el.classList.add("opacity-100", "scale-100")
      } else {
        el.classList.add("opacity-0", "scale-0")
        el.classList.remove("opacity-100", "scale-100")
      }
    })
  }
}
