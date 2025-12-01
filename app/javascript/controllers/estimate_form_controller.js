import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lineItemsContainer",
    "lineItem",
    "lineItemTemplate",
    "taxRate",
    "discount",
    "subtotal",
    "taxAmount",
    "discountDisplay",
    "total"
  ]

  connect() {
    this.lineItemIndex = this.lineItemTargets.length
    this.calculateTotals()
  }

  addLineItem(event) {
    event.preventDefault()

    const template = this.lineItemTemplateTarget.innerHTML
    const newIndex = Date.now() // Use timestamp for unique index
    const newLineItem = template.replace(/NEW_RECORD/g, newIndex)

    this.lineItemsContainerTarget.insertAdjacentHTML('beforeend', newLineItem)
    this.updatePositions()
    this.calculateTotals()
  }

  removeLineItem(event) {
    event.preventDefault()

    const lineItem = event.target.closest('[data-estimate-form-target="lineItem"]')

    if (lineItem) {
      const destroyField = lineItem.querySelector('.destroy-field')

      if (destroyField) {
        // If this is an existing record, mark it for destruction
        destroyField.value = 'true'
        lineItem.style.display = 'none'
      } else {
        // If this is a new record, just remove the DOM element
        lineItem.remove()
      }

      this.updatePositions()
      this.calculateTotals()
    }
  }

  updatePositions() {
    const visibleItems = this.lineItemTargets.filter(item => item.style.display !== 'none')
    visibleItems.forEach((item, index) => {
      const positionField = item.querySelector('input[name*="[position]"]')
      if (positionField) {
        positionField.value = index
      }
    })
  }

  calculateTotals() {
    let subtotal = 0

    this.lineItemTargets.forEach(item => {
      if (item.style.display !== 'none') {
        const quantityInput = item.querySelector('input[name*="[quantity]"]')
        const unitPriceInput = item.querySelector('input[name*="[unit_price]"]')

        const quantity = parseFloat(quantityInput?.value) || 0
        const unitPrice = parseFloat(unitPriceInput?.value) || 0

        subtotal += quantity * unitPrice
      }
    })

    const taxRate = parseFloat(this.taxRateTarget?.value) || 0
    const discount = parseFloat(this.discountTarget?.value) || 0
    const taxAmount = (subtotal * taxRate) / 100
    const total = subtotal + taxAmount - discount

    // Update display
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = this.formatCurrency(subtotal)
    }

    if (this.hasTaxAmountTarget) {
      this.taxAmountTarget.textContent = this.formatCurrency(taxAmount)
    }

    if (this.hasDiscountDisplayTarget) {
      this.discountDisplayTarget.textContent = `-${this.formatCurrency(discount)}`
    }

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = this.formatCurrency(total)
    }
  }

  formatCurrency(amount) {
    return `$${amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`
  }
}
