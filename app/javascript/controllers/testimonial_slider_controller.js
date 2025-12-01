import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="testimonial-slider"
// Auto-advances through testimonials with smooth transitions

export default class extends Controller {
  static targets = ["slide", "dot", "progress"]
  static values = {
    autoplay: { type: Boolean, default: true },
    interval: { type: Number, default: 5000 },
    current: { type: Number, default: 0 }
  }

  connect() {
    this.showSlide(this.currentValue)
    if (this.autoplayValue) {
      this.startAutoplay()
    }
  }

  disconnect() {
    this.stopAutoplay()
  }

  startAutoplay() {
    this.timer = setInterval(() => this.next(), this.intervalValue)
    this.startProgress()
  }

  stopAutoplay() {
    if (this.timer) {
      clearInterval(this.timer)
    }
    if (this.progressTimer) {
      cancelAnimationFrame(this.progressTimer)
    }
  }

  startProgress() {
    if (!this.hasProgressTarget) return

    this.progressStart = performance.now()
    const animate = (now) => {
      const elapsed = now - this.progressStart
      const progress = Math.min(elapsed / this.intervalValue, 1)
      this.progressTarget.style.width = `${progress * 100}%`

      if (progress < 1) {
        this.progressTimer = requestAnimationFrame(animate)
      }
    }
    this.progressTimer = requestAnimationFrame(animate)
  }

  resetProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = "0%"
    }
    this.progressStart = performance.now()
    this.startProgress()
  }

  next() {
    const nextIndex = (this.currentValue + 1) % this.slideTargets.length
    this.goTo(nextIndex)
  }

  previous() {
    const prevIndex = (this.currentValue - 1 + this.slideTargets.length) % this.slideTargets.length
    this.goTo(prevIndex)
  }

  goTo(index) {
    this.currentValue = index
    this.showSlide(index)
    this.resetProgress()

    // Reset autoplay timer
    if (this.autoplayValue) {
      this.stopAutoplay()
      this.startAutoplay()
    }
  }

  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.goTo(index)
  }

  showSlide(index) {
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove("opacity-0", "scale-95", "pointer-events-none")
        slide.classList.add("opacity-100", "scale-100")
      } else {
        slide.classList.add("opacity-0", "scale-95", "pointer-events-none")
        slide.classList.remove("opacity-100", "scale-100")
      }
    })

    this.dotTargets.forEach((dot, i) => {
      if (i === index) {
        dot.classList.add("bg-amber-500", "w-8")
        dot.classList.remove("bg-slate-300", "w-2")
      } else {
        dot.classList.remove("bg-amber-500", "w-8")
        dot.classList.add("bg-slate-300", "w-2")
      }
    })
  }

  pause() {
    this.stopAutoplay()
  }

  resume() {
    if (this.autoplayValue) {
      this.startAutoplay()
    }
  }
}
