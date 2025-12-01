import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="billing-toggle"
export default class extends Controller {
  static targets = ["monthlyBtn", "yearlyBtn", "monthlyPlans", "yearlyPlans"]

  connect() {
    // Default to monthly view
    this.showMonthly()
  }

  showMonthly() {
    // Update button styles
    this.monthlyBtnTarget.classList.add("text-white", "bg-indigo-600", "shadow-sm")
    this.monthlyBtnTarget.classList.remove("text-gray-600")

    this.yearlyBtnTarget.classList.remove("text-white", "bg-indigo-600", "shadow-sm")
    this.yearlyBtnTarget.classList.add("text-gray-600")

    // Show/hide plan grids
    this.monthlyPlansTarget.classList.remove("hidden")
    this.yearlyPlansTarget.classList.add("hidden")
  }

  showYearly() {
    // Update button styles
    this.yearlyBtnTarget.classList.add("text-white", "bg-indigo-600", "shadow-sm")
    this.yearlyBtnTarget.classList.remove("text-gray-600")

    this.monthlyBtnTarget.classList.remove("text-white", "bg-indigo-600", "shadow-sm")
    this.monthlyBtnTarget.classList.add("text-gray-600")

    // Show/hide plan grids
    this.yearlyPlansTarget.classList.remove("hidden")
    this.monthlyPlansTarget.classList.add("hidden")
  }
}
