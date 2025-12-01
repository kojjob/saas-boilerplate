import { Controller } from "@hotwired/stimulus"

// Sidebar controller for mobile navigation toggle
export default class extends Controller {
  connect() {
    this.mobileSidebar = document.getElementById("mobile-sidebar")
    this.overlay = document.getElementById("mobile-sidebar-overlay")

    // Close on escape key
    this.escapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  toggle() {
    if (this.mobileSidebar.classList.contains("-translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    // Show overlay
    this.overlay.classList.remove("hidden")

    // Slide in sidebar
    requestAnimationFrame(() => {
      this.mobileSidebar.classList.remove("-translate-x-full")
      this.mobileSidebar.classList.add("translate-x-0")

      // Fade in overlay
      this.overlay.style.opacity = "0"
      requestAnimationFrame(() => {
        this.overlay.style.transition = "opacity 0.3s ease-out"
        this.overlay.style.opacity = "1"
      })
    })

    // Prevent body scroll when sidebar is open
    document.body.style.overflow = "hidden"
  }

  close() {
    // Fade out overlay
    this.overlay.style.opacity = "0"

    // Slide out sidebar
    this.mobileSidebar.classList.remove("translate-x-0")
    this.mobileSidebar.classList.add("-translate-x-full")

    setTimeout(() => {
      this.overlay.classList.add("hidden")
      this.overlay.style.transition = ""
      this.overlay.style.opacity = ""
    }, 300)

    // Restore body scroll
    document.body.style.overflow = ""
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.mobileSidebar.classList.contains("-translate-x-full")) {
      this.close()
    }
  }
}
