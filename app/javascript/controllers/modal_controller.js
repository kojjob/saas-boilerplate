import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.body.classList.add("overflow-hidden")
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden")
  }

  close(e) {
    if (e) {
      e.preventDefault()
      // Only close on Escape key
      if (e.type === "keyup" && e.key !== "Escape") return
    }

    // Remove the modal element
    const frame = document.getElementById("modal")
    if (frame) {
      frame.innerHTML = ""
    }
  }

  closeBackground(e) {
    if (e.target === e.currentTarget) {
      this.close(e)
    }
  }
}
