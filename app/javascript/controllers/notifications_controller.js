import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["badge", "list", "count"]

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        connected: () => this.connected(),
        disconnected: () => this.disconnected(),
        received: (data) => this.received(data)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  connected() {
    console.log("Connected to notifications channel")
  }

  disconnected() {
    console.log("Disconnected from notifications channel")
  }

  received(data) {
    if (data.notification) {
      this.addNotification(data.notification)
      this.updateBadge()
      this.showToast(data.notification)
    } else if (data.action === "all_read") {
      this.markAllAsRead()
    }
  }

  addNotification(notification) {
    if (this.hasListTarget) {
      const html = this.buildNotificationHtml(notification)
      this.listTarget.insertAdjacentHTML("afterbegin", html)
    }
  }

  updateBadge() {
    if (this.hasBadgeTarget) {
      const currentCount = parseInt(this.badgeTarget.textContent) || 0
      this.badgeTarget.textContent = currentCount + 1
      this.badgeTarget.classList.remove("hidden")
    }
  }

  showToast(notification) {
    // Create and show toast notification
    const toast = document.createElement("div")
    toast.className = "fixed bottom-4 right-4 bg-white shadow-lg rounded-lg p-4 max-w-sm z-50 border-l-4 border-primary-500"
    toast.innerHTML = `
      <div class="flex items-start">
        <div class="flex-1">
          <p class="text-sm font-medium text-gray-900">${notification.title}</p>
          ${notification.body ? `<p class="mt-1 text-sm text-gray-500">${notification.body}</p>` : ""}
        </div>
        <button type="button" class="ml-4 text-gray-400 hover:text-gray-500" onclick="this.closest('div.fixed').remove()">
          <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
          </svg>
        </button>
      </div>
    `
    document.body.appendChild(toast)

    // Auto-remove after 5 seconds
    setTimeout(() => {
      toast.remove()
    }, 5000)
  }

  markAllAsRead() {
    if (this.hasListTarget) {
      this.listTarget.querySelectorAll(".bg-primary-50").forEach(el => {
        el.classList.remove("bg-primary-50")
      })
    }
    if (this.hasBadgeTarget) {
      this.badgeTarget.classList.add("hidden")
      this.badgeTarget.textContent = "0"
    }
  }

  buildNotificationHtml(notification) {
    const iconClass = this.getIconClass(notification.notification_type)
    return `
      <a href="/notifications/${notification.id}" class="block p-4 hover:bg-gray-50 bg-primary-50">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            ${iconClass}
          </div>
          <div class="ml-3 flex-1">
            <p class="text-sm font-semibold text-gray-900">${notification.title}</p>
            ${notification.body ? `<p class="mt-1 text-sm text-gray-500 line-clamp-2">${notification.body}</p>` : ""}
            <p class="mt-1 text-xs text-gray-400">Just now</p>
          </div>
          <span class="ml-2 h-2 w-2 bg-primary-600 rounded-full"></span>
        </div>
      </a>
    `
  }

  getIconClass(type) {
    const icons = {
      success: `<span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-green-100 text-green-600">
        <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
        </svg>
      </span>`,
      warning: `<span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-yellow-100 text-yellow-600">
        <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
        </svg>
      </span>`,
      error: `<span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-red-100 text-red-600">
        <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
        </svg>
      </span>`
    }
    return icons[type] || `<span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-blue-100 text-blue-600">
      <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
      </svg>
    </span>`
  }
}
