import { Controller } from "@hotwired/stimulus"

// Dropdown controller for user menu and account switcher
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Close dropdown when clicking outside
    this.outsideClickHandler = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.outsideClickHandler)

    // Close dropdown on escape key
    this.escapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
    document.removeEventListener("keydown", this.escapeHandler)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    // Close any other open dropdowns first
    document.querySelectorAll("[data-dropdown-target='menu']:not(.hidden)").forEach(menu => {
      if (menu !== this.menuTarget) {
        menu.classList.add("hidden")
      }
    })

    this.menuTarget.classList.remove("hidden")

    // Animate in
    this.menuTarget.style.opacity = "0"
    this.menuTarget.style.transform = "translateY(-8px)"
    requestAnimationFrame(() => {
      this.menuTarget.style.transition = "opacity 0.15s ease-out, transform 0.15s ease-out"
      this.menuTarget.style.opacity = "1"
      this.menuTarget.style.transform = "translateY(0)"
    })
  }

  close() {
    // Animate out
    this.menuTarget.style.opacity = "0"
    this.menuTarget.style.transform = "translateY(-8px)"

    setTimeout(() => {
      this.menuTarget.classList.add("hidden")
      this.menuTarget.style.transition = ""
      this.menuTarget.style.opacity = ""
      this.menuTarget.style.transform = ""
    }, 150)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
