import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="counter"
// Usage: <span data-controller="counter" data-counter-target-value="1000" data-counter-suffix-value="+"></span>

export default class extends Controller {
  static values = {
    target: { type: Number, default: 100 },
    duration: { type: Number, default: 2000 },
    suffix: { type: String, default: "" },
    prefix: { type: String, default: "" },
    decimals: { type: Number, default: 0 }
  }

  connect() {
    this.hasAnimated = false
    this.setupObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupObserver() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !this.hasAnimated) {
            this.hasAnimated = true
            this.animate()
          }
        })
      },
      { threshold: 0.5 }
    )
    
    this.observer.observe(this.element)
  }

  animate() {
    const startTime = performance.now()
    const startValue = 0
    const endValue = this.targetValue
    
    const step = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / this.durationValue, 1)
      
      // Easing function (ease-out-expo)
      const easedProgress = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress)
      
      const currentValue = startValue + (endValue - startValue) * easedProgress
      
      this.element.textContent = this.formatValue(currentValue)
      
      if (progress < 1) {
        requestAnimationFrame(step)
      }
    }
    
    requestAnimationFrame(step)
  }

  formatValue(value) {
    const formatted = this.decimalsValue > 0 
      ? value.toFixed(this.decimalsValue)
      : Math.floor(value).toLocaleString()
    
    return `${this.prefixValue}${formatted}${this.suffixValue}`
  }
}
