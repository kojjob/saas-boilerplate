import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll-animator"
// Add data-scroll-animator-target="item" to elements you want to animate
// Customize animation with data-animation="fade-up|fade-down|fade-left|fade-right|scale|blur"
// Customize delay with data-delay="100" (ms)
// Customize duration with data-duration="700" (ms)

export default class extends Controller {
  static targets = ["item"]
  static values = {
    threshold: { type: Number, default: 0.1 },
    rootMargin: { type: String, default: "0px 0px -50px 0px" }
  }

  connect() {
    this.setupObserver()
    this.prepareItems()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupObserver() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      {
        threshold: this.thresholdValue,
        rootMargin: this.rootMarginValue
      }
    )

    this.itemTargets.forEach((item) => {
      this.observer.observe(item)
    })
  }

  prepareItems() {
    this.itemTargets.forEach((item) => {
      const animation = item.dataset.animation || "fade-up"
      const duration = item.dataset.duration || "700"
      
      // Set initial styles
      item.style.opacity = "0"
      item.style.transition = `all ${duration}ms cubic-bezier(0.4, 0, 0.2, 1)`
      
      // Set initial transform based on animation type
      switch (animation) {
        case "fade-up":
          item.style.transform = "translateY(40px)"
          break
        case "fade-down":
          item.style.transform = "translateY(-40px)"
          break
        case "fade-left":
          item.style.transform = "translateX(40px)"
          break
        case "fade-right":
          item.style.transform = "translateX(-40px)"
          break
        case "scale":
          item.style.transform = "scale(0.9)"
          break
        case "blur":
          item.style.filter = "blur(10px)"
          item.style.transform = "translateY(20px)"
          break
        case "zoom":
          item.style.transform = "scale(0.5)"
          break
        case "flip":
          item.style.transform = "perspective(1000px) rotateX(90deg)"
          break
        default:
          item.style.transform = "translateY(40px)"
      }
    })
  }

  handleIntersection(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const item = entry.target
        const delay = item.dataset.delay || 0
        
        setTimeout(() => {
          this.animateIn(item)
        }, parseInt(delay))
        
        // Unobserve after animation (one-time animation)
        this.observer.unobserve(item)
      }
    })
  }

  animateIn(item) {
    const animation = item.dataset.animation || "fade-up"
    
    item.style.opacity = "1"
    
    switch (animation) {
      case "fade-up":
      case "fade-down":
      case "fade-left":
      case "fade-right":
        item.style.transform = "translate(0, 0)"
        break
      case "scale":
      case "zoom":
        item.style.transform = "scale(1)"
        break
      case "blur":
        item.style.filter = "blur(0)"
        item.style.transform = "translateY(0)"
        break
      case "flip":
        item.style.transform = "perspective(1000px) rotateX(0)"
        break
      default:
        item.style.transform = "translate(0, 0)"
    }
  }
}
