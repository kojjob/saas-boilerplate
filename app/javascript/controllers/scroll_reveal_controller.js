import { Controller } from "@hotwired/stimulus"

// Scroll reveal animation controller with IntersectionObserver
// Animates elements as they come into the viewport
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 0 },
    duration: { type: Number, default: 600 },
    distance: { type: Number, default: 30 },
    direction: { type: String, default: "up" }, // up, down, left, right
    once: { type: Boolean, default: true } // Only animate once
  }

  connect() {
    // Set initial hidden state
    this.setInitialState()

    // Create IntersectionObserver
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      {
        root: null,
        rootMargin: "0px 0px -50px 0px",
        threshold: 0.1
      }
    )

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setInitialState() {
    const transform = this.getInitialTransform()

    this.element.style.opacity = "0"
    this.element.style.transform = transform
    this.element.style.transition = `opacity ${this.durationValue}ms ease-out, transform ${this.durationValue}ms ease-out`
    this.element.style.transitionDelay = `${this.delayValue}ms`
  }

  getInitialTransform() {
    const distance = this.distanceValue

    switch (this.directionValue) {
      case "up":
        return `translateY(${distance}px)`
      case "down":
        return `translateY(-${distance}px)`
      case "left":
        return `translateX(${distance}px)`
      case "right":
        return `translateX(-${distance}px)`
      case "scale":
        return `scale(0.95)`
      default:
        return `translateY(${distance}px)`
    }
  }

  handleIntersection(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        this.reveal()

        if (this.onceValue) {
          this.observer.unobserve(this.element)
        }
      } else if (!this.onceValue) {
        this.hide()
      }
    })
  }

  reveal() {
    this.element.style.opacity = "1"
    this.element.style.transform = "translateY(0) translateX(0) scale(1)"
  }

  hide() {
    const transform = this.getInitialTransform()
    this.element.style.opacity = "0"
    this.element.style.transform = transform
  }
}
