/**
 * SymbolAutocomplete JavaScript Hook
 *
 * Provides client-side enhancements for the SymbolAutocomplete LiveView component:
 * - Keyboard navigation (arrow keys, enter, escape)
 * - Click-outside-to-close behavior
 * - Mobile-friendly touch interactions
 * - Dropdown positioning and responsive design
 * - Visual loading indicators and smooth transitions
 */

const SymbolAutocomplete = {
  mounted() {
    this.initializeComponent()
    this.setupEventListeners()
    this.setupClickOutside()
    this.setupTouchHandlers()
  },

  updated() {
    this.updateDropdownPosition()
    this.updateAccessibilityState()
  },

  destroyed() {
    this.cleanup()
  },

  initializeComponent() {
    this.input = this.el.querySelector('input[type="text"]')
    this.dropdown = this.el.querySelector('[role="listbox"]')
    this.results = this.el.querySelector('[id$="-results"]')
    this.announcements = this.el.querySelector('[aria-live="polite"]')
   
    // State tracking
    this.selectedIndex = -1
    this.isOpen = false
    this.touchStartY = 0
   
    // Configuration
    this.debounceTimeout = 300
    this.animationDuration = 150
   
    // Add CSS classes for smooth transitions
    if (this.dropdown) {
      this.dropdown.style.transition = `opacity ${this.animationDuration}ms ease-in-out, transform ${this.animationDuration}ms ease-in-out`
    }
  },

  setupEventListeners() {
    if (!this.input) return

    // Keyboard navigation
    this.input.addEventListener('keydown', (e) => this.handleKeydown(e))
   
    // Focus management
    this.input.addEventListener('focus', () => this.handleFocus())
    this.input.addEventListener('blur', (e) => this.handleBlur(e))
   
    // Input changes for real-time feedback
    this.input.addEventListener('input', () => this.handleInput())
  },

  setupClickOutside() {
    this.clickOutsideHandler = (e) => {
      if (!this.el.contains(e.target) && this.isOpen) {
        this.closeDropdown()
      }
    }
   
    document.addEventListener('click', this.clickOutsideHandler)
    document.addEventListener('touchstart', this.clickOutsideHandler)
  },

  setupTouchHandlers() {
    if (!this.dropdown) return

    // Handle touch scrolling in dropdown
    this.dropdown.addEventListener('touchstart', (e) => {
      this.touchStartY = e.touches[0].clientY
    })

    this.dropdown.addEventListener('touchmove', (e) => {
      const touchY = e.touches[0].clientY
      const deltaY = touchY - this.touchStartY
     
      // Allow scrolling within dropdown
      const scrollTop = this.dropdown.scrollTop
      const scrollHeight = this.dropdown.scrollHeight
      const clientHeight = this.dropdown.clientHeight
     
      // Prevent page scroll when at dropdown boundaries
      if ((deltaY > 0 && scrollTop === 0) ||
          (deltaY < 0 && scrollTop >= scrollHeight - clientHeight)) {
        e.preventDefault()
      }
    })
  },

  handleKeydown(e) {
    if (!this.isOpen && !['ArrowDown', 'Enter'].includes(e.key)) {
      return
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        this.navigateDown()
        break
       
      case 'ArrowUp':
        e.preventDefault()
        this.navigateUp()
        break
       
      case 'Enter':
        e.preventDefault()
        this.selectCurrent()
        break
       
      case 'Escape':
        e.preventDefault()
        this.closeDropdown()
        this.input.blur()
        break
       
      case 'Tab':
        // Allow tab to close dropdown and move focus
        if (this.isOpen) {
          this.closeDropdown()
        }
        break
    }
  },

  handleFocus() {
    // Show dropdown if there are results and input has content
    if (this.input.value.length >= 2 && this.hasResults()) {
      this.openDropdown()
    }
  },

  handleBlur(e) {
    // Delay closing to allow for clicks on dropdown items
    setTimeout(() => {
      if (!this.el.contains(document.activeElement)) {
        this.closeDropdown()
      }
    }, 150)
  },

  handleInput() {
    // Visual feedback for loading state
    this.showLoadingState()
   
    // Update dropdown visibility based on input length
    if (this.input.value.length < 2) {
      this.closeDropdown()
    }
  },

  navigateDown() {
    const options = this.getDropdownOptions()
    if (options.length === 0) return

    this.selectedIndex = Math.min(this.selectedIndex + 1, options.length - 1)
    this.updateSelection()
    this.scrollToSelected()
  },

  navigateUp() {
    const options = this.getDropdownOptions()
    if (options.length === 0) return

    this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
    this.updateSelection()
    this.scrollToSelected()
  },

  selectCurrent() {
    if (this.selectedIndex >= 0) {
      const options = this.getDropdownOptions()
      const selectedOption = options[this.selectedIndex]
     
      if (selectedOption) {
        // Trigger click event on the selected option
        selectedOption.click()
      }
    } else if (this.input.value.trim()) {
      // If no option selected but there's input, trigger search
      this.pushEvent('search_input', { value: this.input.value })
    }
  },

  openDropdown() {
    if (this.isOpen || !this.dropdown) return

    this.isOpen = true
    this.dropdown.style.display = 'block'
   
    // Smooth entrance animation
    requestAnimationFrame(() => {
      this.dropdown.style.opacity = '1'
      this.dropdown.style.transform = 'translateY(0)'
    })
   
    this.updateDropdownPosition()
    this.updateAccessibilityState()
  },

  closeDropdown() {
    if (!this.isOpen || !this.dropdown) return

    this.isOpen = false
    this.selectedIndex = -1
   
    // Smooth exit animation
    this.dropdown.style.opacity = '0'
    this.dropdown.style.transform = 'translateY(-8px)'
   
    setTimeout(() => {
      if (!this.isOpen) {
        this.dropdown.style.display = 'none'
      }
    }, this.animationDuration)
   
    this.updateAccessibilityState()
  },

  updateSelection() {
    const options = this.getDropdownOptions()
   
    options.forEach((option, index) => {
      const isSelected = index === this.selectedIndex
      option.setAttribute('aria-selected', isSelected.toString())
     
      if (isSelected) {
        option.classList.add('bg-blue-50')
        // Announce selection to screen readers
        const text = option.textContent.trim()
        this.announceToScreenReader(`Selected ${text}`)
      } else {
        option.classList.remove('bg-blue-50')
      }
    })
  },

  scrollToSelected() {
    if (this.selectedIndex < 0 || !this.dropdown) return

    const options = this.getDropdownOptions()
    const selectedOption = options[this.selectedIndex]
   
    if (selectedOption) {
      selectedOption.scrollIntoView({
        block: 'nearest',
        behavior: 'smooth'
      })
    }
  },

  updateDropdownPosition() {
    if (!this.dropdown || !this.isOpen) return

    const inputRect = this.input.getBoundingClientRect()
    const dropdownRect = this.dropdown.getBoundingClientRect()
    const viewportHeight = window.innerHeight
   
    // Check if dropdown fits below input
    const spaceBelow = viewportHeight - inputRect.bottom
    const spaceAbove = inputRect.top
   
    if (spaceBelow < dropdownRect.height && spaceAbove > spaceBelow) {
      // Show above input
      this.dropdown.style.bottom = '100%'
      this.dropdown.style.top = 'auto'
      this.dropdown.style.marginBottom = '4px'
      this.dropdown.style.marginTop = '0'
    } else {
      // Show below input (default)
      this.dropdown.style.top = '100%'
      this.dropdown.style.bottom = 'auto'
      this.dropdown.style.marginTop = '4px'
      this.dropdown.style.marginBottom = '0'
    }
   
    // Ensure dropdown doesn't exceed viewport width on mobile
    const inputWidth = inputRect.width
    this.dropdown.style.minWidth = `${inputWidth}px`
   
    // Adjust for mobile screens
    if (window.innerWidth < 640) {
      this.dropdown.style.maxWidth = '100vw'
      this.dropdown.style.left = '0'
      this.dropdown.style.right = '0'
    }
  },

  updateAccessibilityState() {
    if (!this.input) return

    this.input.setAttribute('aria-expanded', this.isOpen.toString())
   
    if (this.isOpen && this.hasResults()) {
      const resultCount = this.getDropdownOptions().length
      this.input.setAttribute('aria-describedby', `${this.el.id}-results`)
      this.announceToScreenReader(`${resultCount} results available`)
    } else {
      this.input.removeAttribute('aria-describedby')
    }
  },

  showLoadingState() {
    // Add visual loading feedback
    const loadingIndicator = this.el.querySelector('.animate-spin')
    if (loadingIndicator) {
      loadingIndicator.style.opacity = '1'
    }
  },

  hideLoadingState() {
    const loadingIndicator = this.el.querySelector('.animate-spin')
    if (loadingIndicator) {
      loadingIndicator.style.opacity = '0'
    }
  },

  getDropdownOptions() {
    if (!this.dropdown) return []
    return Array.from(this.dropdown.querySelectorAll('[role="option"][phx-click="select_symbol"]'))
  },

  hasResults() {
    return this.getDropdownOptions().length > 0
  },

  announceToScreenReader(message) {
    if (this.announcements) {
      this.announcements.textContent = message
    }
  },

  cleanup() {
    if (this.clickOutsideHandler) {
      document.removeEventListener('click', this.clickOutsideHandler)
      document.removeEventListener('touchstart', this.clickOutsideHandler)
    }
  }
}

export default SymbolAutocomplete