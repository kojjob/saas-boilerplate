import { Controller } from "@hotwired/stimulus"

// Smooth accordion controller for FAQ section with animations
export default class extends Controller {
  static targets = ["item", "content", "icon"]

  connect() {
    // Initialize all items as closed with proper height
    this.contentTargets.forEach((content, index) => {
      content.style.maxHeight = "0px"
      content.style.overflow = "hidden"
      content.style.transition = "max-height 0.4s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.3s ease"
      content.style.opacity = "0"
    })
  }

  toggle(event) {
    const item = event.currentTarget.closest('[data-faq-target="item"]')
    const content = item.querySelector('[data-faq-target="content"]')
    const icon = item.querySelector('[data-faq-target="icon"]')
    const isOpen = item.dataset.open === "true"

    if (isOpen) {
      // Close this item
      this.closeItem(item, content, icon)
    } else {
      // Close all other items first (accordion behavior)
      this.itemTargets.forEach((otherItem) => {
        if (otherItem !== item && otherItem.dataset.open === "true") {
          const otherContent = otherItem.querySelector('[data-faq-target="content"]')
          const otherIcon = otherItem.querySelector('[data-faq-target="icon"]')
          this.closeItem(otherItem, otherContent, otherIcon)
        }
      })
      // Open clicked item
      this.openItem(item, content, icon)
    }
  }

  openItem(item, content, icon) {
    item.dataset.open = "true"
    content.style.maxHeight = content.scrollHeight + "px"
    content.style.opacity = "1"
    icon.style.transform = "rotate(45deg)"

    // Add active state styling
    item.classList.add("ring-2", "ring-amber-400/50", "bg-white")
    item.classList.remove("bg-slate-50/50")
  }

  closeItem(item, content, icon) {
    item.dataset.open = "false"
    content.style.maxHeight = "0px"
    content.style.opacity = "0"
    icon.style.transform = "rotate(0deg)"

    // Remove active state styling
    item.classList.remove("ring-2", "ring-amber-400/50", "bg-white")
    item.classList.add("bg-slate-50/50")
  }
}
