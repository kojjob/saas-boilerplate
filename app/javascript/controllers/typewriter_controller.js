import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="typewriter"
// Usage: <span data-controller="typewriter" data-typewriter-words-value='["Launch faster", "Scale easier", "Build better"]'></span>

export default class extends Controller {
  static values = {
    words: { type: Array, default: ["Hello", "World"] },
    typeSpeed: { type: Number, default: 80 },
    deleteSpeed: { type: Number, default: 50 },
    pauseDuration: { type: Number, default: 2000 },
    loop: { type: Boolean, default: true },
    cursor: { type: Boolean, default: true }
  }

  connect() {
    this.wordIndex = 0
    this.charIndex = 0
    this.isDeleting = false
    this.element.innerHTML = ""
    
    if (this.cursorValue) {
      this.createCursor()
    }
    
    this.type()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  createCursor() {
    this.cursor = document.createElement("span")
    this.cursor.className = "typewriter-cursor"
    this.cursor.textContent = "|"
    this.cursor.style.cssText = `
      animation: blink 1s step-end infinite;
      margin-left: 2px;
      font-weight: 300;
    `
    
    // Add keyframes if not already present
    if (!document.getElementById("typewriter-styles")) {
      const style = document.createElement("style")
      style.id = "typewriter-styles"
      style.textContent = `
        @keyframes blink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0; }
        }
      `
      document.head.appendChild(style)
    }
    
    this.element.parentNode.insertBefore(this.cursor, this.element.nextSibling)
  }

  type() {
    const currentWord = this.wordsValue[this.wordIndex]
    
    if (this.isDeleting) {
      // Remove characters
      this.element.textContent = currentWord.substring(0, this.charIndex - 1)
      this.charIndex--
      
      if (this.charIndex === 0) {
        this.isDeleting = false
        this.wordIndex = (this.wordIndex + 1) % this.wordsValue.length
        
        // Check if we should stop (non-looping and finished all words)
        if (!this.loopValue && this.wordIndex === 0) {
          this.element.textContent = this.wordsValue[this.wordsValue.length - 1]
          return
        }
        
        this.timeout = setTimeout(() => this.type(), 500)
        return
      }
      
      this.timeout = setTimeout(() => this.type(), this.deleteSpeedValue)
    } else {
      // Add characters
      this.element.textContent = currentWord.substring(0, this.charIndex + 1)
      this.charIndex++
      
      if (this.charIndex === currentWord.length) {
        // Word complete, pause then delete
        this.isDeleting = true
        this.timeout = setTimeout(() => this.type(), this.pauseDurationValue)
        return
      }
      
      this.timeout = setTimeout(() => this.type(), this.typeSpeedValue)
    }
  }
}
