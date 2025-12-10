import { Controller } from "@hotwired/stimulus"

// Currency symbol mapping for supported currencies
const CURRENCY_SYMBOLS = {
  "USD": "$", "EUR": "€", "GBP": "£", "CAD": "C$", "AUD": "A$",
  "JPY": "¥", "CHF": "CHF", "NZD": "NZ$", "SEK": "kr", "NOK": "kr",
  "DKK": "kr", "SGD": "S$", "HKD": "HK$", "MXN": "MX$", "BRL": "R$",
  "INR": "₹", "ZAR": "R", "PLN": "zł", "CZK": "Kč", "HUF": "Ft",
  "ILS": "₪", "AED": "د.إ", "SAR": "﷼", "KRW": "₩"
}

export default class extends Controller {
  static targets = [
    "lineItems",
    "lineItem",
    "subtotal",
    "taxRate",
    "taxAmount",
    "discountAmount",
    "discountDisplay",
    "total",
    "currency",
    "currencySymbol"
  ]

  connect() {
    this.calculateTotals()
  }

  updateCurrencySymbol() {
    const currency = this.hasCurrencyTarget ? this.currencyTarget.value : "USD"
    const symbol = CURRENCY_SYMBOLS[currency] || "$"

    // Update all currency symbol targets
    this.currencySymbolTargets.forEach(target => {
      target.textContent = symbol
    })

    // Recalculate totals to update formatted amounts
    this.calculateTotals()
  }

  get selectedCurrency() {
    return this.hasCurrencyTarget ? this.currencyTarget.value : "USD"
  }

  addLineItem(event) {
    event.preventDefault()

    const lineItemsContainer = this.lineItemsTarget
    const existingItems = lineItemsContainer.querySelectorAll('[data-invoice-form-target="lineItem"]')
    const newIndex = existingItems.length

    const currencySymbol = CURRENCY_SYMBOLS[this.selectedCurrency] || "$"

    const template = `
      <div class="flex items-start gap-3 p-3 bg-slate-50 rounded-lg" data-invoice-form-target="lineItem">
        <div class="flex-1 grid grid-cols-12 gap-3">
          <div class="col-span-12 md:col-span-5">
            <input type="text" name="invoice[line_items_attributes][${newIndex}][description]" placeholder="Description" class="block w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" />
          </div>
          <div class="col-span-4 md:col-span-2">
            <input type="number" name="invoice[line_items_attributes][${newIndex}][quantity]" step="0.01" min="0" placeholder="Qty" value="1" class="block w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" data-action="change->invoice-form#calculateTotals" />
          </div>
          <div class="col-span-4 md:col-span-3">
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <span class="text-slate-500 text-sm" data-invoice-form-target="currencySymbol">${currencySymbol}</span>
              </div>
              <input type="number" name="invoice[line_items_attributes][${newIndex}][unit_price]" step="0.01" min="0" placeholder="0.00" class="block w-full pl-7 pr-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500" data-action="change->invoice-form#calculateTotals" />
            </div>
          </div>
          <div class="col-span-4 md:col-span-2 flex items-center">
            <span class="text-sm font-medium text-slate-700" data-invoice-form-target="lineAmount">${this.formatCurrency(0)}</span>
          </div>
        </div>
        <div class="flex-shrink-0">
          <input type="hidden" name="invoice[line_items_attributes][${newIndex}][_destroy]" value="false" />
          <button type="button" data-action="click->invoice-form#removeLineItem" class="p-1 text-slate-400 hover:text-red-500 transition-colors">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <input type="hidden" name="invoice[line_items_attributes][${newIndex}][position]" value="${newIndex}" />
      </div>
    `

    lineItemsContainer.insertAdjacentHTML('beforeend', template)
  }

  removeLineItem(event) {
    event.preventDefault()

    const lineItem = event.target.closest('[data-invoice-form-target="lineItem"]')
    const destroyInput = lineItem.querySelector('input[name*="[_destroy]"]')

    if (destroyInput) {
      // If there's a destroy input, this is an existing record - mark for destruction
      destroyInput.value = "true"
      lineItem.style.display = "none"
    } else {
      // This is a new record - just remove from DOM
      lineItem.remove()
    }

    this.calculateTotals()
  }

  calculateTotals() {
    let subtotal = 0

    // Calculate subtotal from line items
    const lineItems = this.element.querySelectorAll('[data-invoice-form-target="lineItem"]')
    lineItems.forEach(item => {
      if (item.style.display === "none") return // Skip destroyed items

      const qty = parseFloat(item.querySelector('input[name*="[quantity]"]')?.value) || 0
      const price = parseFloat(item.querySelector('input[name*="[unit_price]"]')?.value) || 0
      const amount = qty * price

      // Update line item amount display
      const amountDisplay = item.querySelector('[data-invoice-form-target="lineAmount"]')
      if (amountDisplay) {
        amountDisplay.textContent = this.formatCurrency(amount)
      }

      subtotal += amount
    })

    // Get tax rate and discount
    const taxRate = parseFloat(this.taxRateTarget?.value) || 0
    const discount = parseFloat(this.discountAmountTarget?.value) || 0

    // Calculate totals
    const taxAmount = subtotal * (taxRate / 100)
    const total = subtotal + taxAmount - discount

    // Update display
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = this.formatCurrency(subtotal)
    }
    if (this.hasTaxAmountTarget) {
      this.taxAmountTarget.textContent = this.formatCurrency(taxAmount)
    }
    if (this.hasDiscountDisplayTarget) {
      this.discountDisplayTarget.textContent = this.formatCurrency(discount)
    }
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = this.formatCurrency(total)
    }
  }

  formatCurrency(amount) {
    const currency = this.selectedCurrency
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency
    }).format(amount)
  }
}
