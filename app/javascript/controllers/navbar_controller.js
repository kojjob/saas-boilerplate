import { Controller } from "@hotwired/stimulus"

// Responsive navbar controller with mobile menu toggle
export default class extends Controller {
  static targets = ["mobileMenu", "menuIcon", "closeIcon"]

  connect() {
    // Close mobile menu on escape key
    document.addEventListener("keydown", this.handleEscape.bind(this))
    // Close mobile menu on window resize to desktop
    window.addEventListener("resize", this.handleResize.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape.bind(this))
    window.removeEventListener("resize", this.handleResize.bind(this))
  }

  toggleMobile() {
    const isHidden = this.mobileMenuTarget.classList.contains("hidden")

    if (isHidden) {
      this.openMobileMenu()
    } else {
      this.closeMobileMenu()
    }
  }

  openMobileMenu() {
    this.mobileMenuTarget.classList.remove("hidden")
    this.menuIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")

    // Animate the menu sliding down
    this.mobileMenuTarget.style.maxHeight = "0"
    this.mobileMenuTarget.style.overflow = "hidden"
    requestAnimationFrame(() => {
      this.mobileMenuTarget.style.transition = "max-height 0.2s ease-out"
      this.mobileMenuTarget.style.maxHeight = this.mobileMenuTarget.scrollHeight + "px"
    })

    // Prevent body scroll when menu is open
    document.body.style.overflow = "hidden"
  }

  closeMobileMenu() {
    this.mobileMenuTarget.style.maxHeight = "0"
    this.menuIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")

    // Restore body scroll
    document.body.style.overflow = ""

    // Hide after animation
    setTimeout(() => {
      this.mobileMenuTarget.classList.add("hidden")
      this.mobileMenuTarget.style.maxHeight = ""
      this.mobileMenuTarget.style.overflow = ""
      this.mobileMenuTarget.style.transition = ""
    }, 200)
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.mobileMenuTarget.classList.contains("hidden")) {
      this.closeMobileMenu()
    }
  }

  handleResize() {
    // Close mobile menu if window is resized to desktop size
    if (window.innerWidth >= 768 && !this.mobileMenuTarget.classList.contains("hidden")) {
      this.closeMobileMenu()
    }
  }
}
