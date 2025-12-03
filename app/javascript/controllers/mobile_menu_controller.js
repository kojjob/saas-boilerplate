import { Controller } from "@hotwired/stimulus"

// Simple mobile menu toggle controller for Owner Portal navigation
export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]

  connect() {
    // Close on escape key
    this.handleEscape = this.handleEscape.bind(this)
    this.handleResize = this.handleResize.bind(this)
    document.addEventListener("keydown", this.handleEscape)
    window.addEventListener("resize", this.handleResize)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
    window.removeEventListener("resize", this.handleResize)
  }

  toggle() {
    const isHidden = this.menuTarget.classList.contains("hidden")

    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add("hidden")
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  handleResize() {
    // Close mobile menu when resized to desktop (md breakpoint = 768px)
    if (window.innerWidth >= 768 && !this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}

