import { Controller } from "@hotwired/stimulus"

// Contact form controller with validation and enhanced UX
export default class extends Controller {
  static targets = ["submit", "name", "email", "message"]

  connect() {
    // Store original button content
    if (this.hasSubmitTarget) {
      this.originalButtonText = this.submitTarget.textContent.trim()
    }

    // Add input event listeners for real-time validation
    this.element.querySelectorAll("input, textarea").forEach((field) => {
      field.addEventListener("input", () => this.validateField(field))
      field.addEventListener("blur", () => this.validateField(field))
    })
  }

  validateField(field) {
    const isValid = field.checkValidity()

    if (isValid) {
      field.classList.remove("border-red-400", "focus:border-red-400", "focus:ring-red-100")
      field.classList.add("border-slate-200", "focus:border-amber-400", "focus:ring-amber-100")
    } else if (field.value) {
      field.classList.remove("border-slate-200", "focus:border-amber-400", "focus:ring-amber-100")
      field.classList.add("border-red-400", "focus:border-red-400", "focus:ring-red-100")
    }

    this.updateSubmitButton()
  }

  updateSubmitButton() {
    if (!this.hasSubmitTarget) return

    const requiredFields = this.element.querySelectorAll("[required]")
    const allValid = Array.from(requiredFields).every((field) => field.checkValidity())

    if (allValid) {
      this.submitTarget.classList.remove("opacity-75", "cursor-not-allowed")
      this.submitTarget.disabled = false
    } else {
      this.submitTarget.classList.add("opacity-75", "cursor-not-allowed")
      this.submitTarget.disabled = true
    }
  }

  submit(event) {
    // Add loading state using safe DOM methods
    if (this.hasSubmitTarget) {
      // Clear existing content
      while (this.submitTarget.firstChild) {
        this.submitTarget.removeChild(this.submitTarget.firstChild)
      }

      // Create spinner SVG element
      const spinner = document.createElementNS("http://www.w3.org/2000/svg", "svg")
      spinner.setAttribute("class", "animate-spin -ml-1 mr-3 h-5 w-5 text-white")
      spinner.setAttribute("fill", "none")
      spinner.setAttribute("viewBox", "0 0 24 24")

      const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle")
      circle.setAttribute("class", "opacity-25")
      circle.setAttribute("cx", "12")
      circle.setAttribute("cy", "12")
      circle.setAttribute("r", "10")
      circle.setAttribute("stroke", "currentColor")
      circle.setAttribute("stroke-width", "4")

      const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
      path.setAttribute("class", "opacity-75")
      path.setAttribute("fill", "currentColor")
      path.setAttribute("d", "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z")

      spinner.appendChild(circle)
      spinner.appendChild(path)

      // Create text span
      const textSpan = document.createElement("span")
      textSpan.textContent = "Sending..."

      // Append to button
      this.submitTarget.appendChild(spinner)
      this.submitTarget.appendChild(textSpan)
      this.submitTarget.disabled = true
    }
  }
}
