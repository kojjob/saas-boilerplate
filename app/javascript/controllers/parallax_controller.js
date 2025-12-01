import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parallax"
// Usage: <div data-controller="parallax" data-parallax-speed-value="0.5">
// Or on children: <div data-parallax-target="layer" data-speed="0.3">

export default class extends Controller {
  static targets = ["layer"]
  static values = {
    speed: { type: Number, default: 0.5 }
  }

  connect() {
    this.ticking = false
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
    this.updatePosition()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    if (!this.ticking) {
      requestAnimationFrame(() => {
        this.updatePosition()
        this.ticking = false
      })
      this.ticking = true
    }
  }

  updatePosition() {
    const scrollY = window.scrollY

    // Apply parallax to the main element
    if (!this.hasLayerTarget) {
      const yPos = scrollY * this.speedValue
      this.element.style.transform = `translate3d(0, ${yPos}px, 0)`
    }

    // Apply parallax to layer targets with individual speeds
    this.layerTargets.forEach((layer) => {
      const speed = parseFloat(layer.dataset.speed) || this.speedValue
      const yPos = scrollY * speed
      layer.style.transform = `translate3d(0, ${yPos}px, 0)`
    })
  }
}
