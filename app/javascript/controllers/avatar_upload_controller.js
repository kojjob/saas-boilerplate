import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="avatar-upload"
export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "dropzone", "filename", "removeBtn", "submitBtn"]
  static values = {
    maxSize: { type: Number, default: 5242880 }, // 5MB in bytes
    acceptedTypes: { type: Array, default: ["image/jpeg", "image/png", "image/gif", "image/webp"] }
  }

  connect() {
    this.originalPreviewSrc = this.hasPreviewTarget ? this.previewTarget.src : null
    this.setupDropzone()
  }

  setupDropzone() {
    if (!this.hasDropzoneTarget) return

    this.dropzoneTarget.addEventListener("dragover", this.handleDragOver.bind(this))
    this.dropzoneTarget.addEventListener("dragleave", this.handleDragLeave.bind(this))
    this.dropzoneTarget.addEventListener("drop", this.handleDrop.bind(this))
  }

  handleDragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.add("border-amber-500", "bg-amber-500/10")
    this.dropzoneTarget.classList.remove("border-slate-600")
  }

  handleDragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.remove("border-amber-500", "bg-amber-500/10")
    this.dropzoneTarget.classList.add("border-slate-600")
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.remove("border-amber-500", "bg-amber-500/10")
    this.dropzoneTarget.classList.add("border-slate-600")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.processFile(files[0])
    }
  }

  selectFile() {
    this.inputTarget.click()
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file) {
      this.processFile(file)
    }
  }

  processFile(file) {
    // Validate file type
    if (!this.acceptedTypesValue.includes(file.type)) {
      this.showError(`Invalid file type. Please upload a JPEG, PNG, GIF, or WebP image.`)
      return
    }

    // Validate file size
    if (file.size > this.maxSizeValue) {
      const maxSizeMB = (this.maxSizeValue / 1024 / 1024).toFixed(0)
      this.showError(`File is too large. Maximum size is ${maxSizeMB}MB.`)
      return
    }

    // Update the file input
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files

    // Show preview
    this.showPreview(file)

    // Update filename display
    if (this.hasFilenameTarget) {
      this.filenameTarget.textContent = file.name
      this.filenameTarget.classList.remove("hidden")
    }

    // Show remove button
    if (this.hasRemoveBtnTarget) {
      this.removeBtnTarget.classList.remove("hidden")
      this.removeBtnTarget.classList.add("inline-flex")
    }

    // Enable submit button
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }

  showPreview(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasPreviewTarget) {
        this.previewTarget.src = e.target.result
        this.previewTarget.classList.remove("hidden")
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add("hidden")
      }
    }
    reader.readAsDataURL(file)
  }

  removePreview() {
    // Clear file input
    this.inputTarget.value = ""

    // Reset preview
    if (this.hasPreviewTarget) {
      if (this.originalPreviewSrc) {
        this.previewTarget.src = this.originalPreviewSrc
      } else {
        this.previewTarget.classList.add("hidden")
      }
    }

    // Show placeholder
    if (this.hasPlaceholderTarget && !this.originalPreviewSrc) {
      this.placeholderTarget.classList.remove("hidden")
    }

    // Hide filename
    if (this.hasFilenameTarget) {
      this.filenameTarget.classList.add("hidden")
    }

    // Hide remove button
    if (this.hasRemoveBtnTarget) {
      this.removeBtnTarget.classList.add("hidden")
      this.removeBtnTarget.classList.remove("inline-flex")
    }

    // Disable submit button
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = true
      this.submitBtnTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }

  showError(message) {
    // Dispatch a custom event for flash messages
    this.dispatch("error", { detail: { message } })
    
    // Also show an alert as fallback
    alert(message)
  }
}
