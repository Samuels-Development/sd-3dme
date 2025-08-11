class ActionPopupManager {
  constructor() {
    this.container = document.getElementById("popup-container")
    this.activePopups = new Map()
    this.popupTimeouts = new Map()

    window.addEventListener('message', (event) => {
      const data = event.data
      if (data.action === 'init') {
        this.container.innerHTML = ''
        this.activePopups.clear()
        this.popupTimeouts.forEach(timeout => clearTimeout(timeout))
        this.popupTimeouts.clear()
      } else if (data.action === 'showPopup') {
        this.showActionPopup(data.type, data.text, data.playerName, data.source, data.screenX, data.screenY)
      } else if (data.action === 'updatePosition') {
        this.updatePopupPosition(data.source, data.screenX, data.screenY, data.visible)
      } else if (data.action === 'hidePopup') {
        this.hidePopup(data.source)
      }
    })

    window.showActionPopup = this.showActionPopup.bind(this)
  }

  formatFiveMText(text) {
    if (!text) return text
    
    let formatted = text.replace(/[&<>"']/g, function(match) {
      const escapeMap = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
      }
      return escapeMap[match]
    })

    const colorMap = {
      '~r~': '<span style="color: #ff4444;">',
      '~g~': '<span style="color: #44ff44;">',
      '~b~': '<span style="color: #4444ff;">',
      '~y~': '<span style="color: #ffff44;">',
      '~p~': '<span style="color: #ff44ff;">',
      '~c~': '<span style="color: #44ffff;">',
      '~m~': '<span style="color: #aaaaaa;">',
      '~u~': '<span style="color: #000000;">',
      '~o~': '<span style="color: #ff8800;">',
      '~q~': '<span style="color: #ff0088;">',
      '~t~': '<span style="color: #88ff00;">',
      '~w~': '<span style="color: #ffffff;">',
      '~s~': '</span>',
      '~n~': '<br>',
      '~~': '~'
    }

    for (const [code, html] of Object.entries(colorMap)) {
      const escapedCode = code.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      formatted = formatted.replace(new RegExp(escapedCode, 'gi'), html)
    }

    formatted = formatted.replace(/~#([0-9a-fA-F]{6})~/g, '<span style="color: #$1;">')

    formatted = formatted.replace(/\^\*([^*]*)\^\*/g, '<strong>$1</strong>')

    formatted = formatted.replace(/\^\/([^/]*)\^\//g, '<em>$1</em>')

    formatted = formatted.replace(/\^_([^_]*)\^_/g, '<u>$1</u>')

    formatted = formatted.replace(/\^-([^-]*)\^-/g, '<s>$1</s>')

    return formatted
  }

  showActionPopup(type, text, playerName = "Player", source, screenX = null, screenY = null) {

    if (this.activePopups.has(source)) {
      this.hidePopup(source)
    }

    const popup = this.createPopup(type, text, playerName)
    popup.dataset.source = source

    if (screenX !== null && screenY !== null) {
      popup.style.position = 'fixed'
      popup.style.left = screenX + 'px'
      popup.style.top = screenY + 'px'
      popup.style.transform = 'translate(-50%, -100%)'
      popup.style.transformOrigin = 'center bottom'
      popup.style.zIndex = '1000'
    } else {
      popup.style.position = 'fixed'
      popup.style.left = '50%'
      popup.style.top = '50%'
      popup.style.transform = 'translate(-50%, -50%)'
      popup.style.zIndex = '1000'
    }

    this.container.appendChild(popup)
    this.activePopups.set(source, popup)

    if (this.popupTimeouts.has(source)) {
      clearTimeout(this.popupTimeouts.get(source))
    }
    
    const timeoutId = setTimeout(() => {
      this.fadeOutPopup(source)
    }, 5000)
    
    this.popupTimeouts.set(source, timeoutId)
  }

  updatePopupPosition(source, screenX, screenY, visible) {
    const popup = this.activePopups.get(source)
    if (popup) {
      if (visible && screenX !== null && screenY !== null) {
        popup.style.left = screenX + 'px'
        popup.style.top = screenY + 'px'
        popup.style.display = 'block'
        popup.style.opacity = '1'
      } else {
        popup.style.display = 'none'
      }
    }
  }

  hidePopup(source) {
    const popup = this.activePopups.get(source)
    if (popup) {
      if (popup.parentNode) {
        popup.parentNode.removeChild(popup)
      }
      this.activePopups.delete(source)
    }
    
    if (this.popupTimeouts.has(source)) {
      clearTimeout(this.popupTimeouts.get(source))
      this.popupTimeouts.delete(source)
    }
  }

  createPopup(type, text, playerName) {
    const popup = document.createElement("div")
    popup.className = `action-popup popup-${type}`

    const config = this.getActionConfig(type)
    
    const formattedText = this.formatFiveMText(text)

    popup.innerHTML = `
            <div class="popup-content">
                <div class="popup-bg-effect"></div>
                <div class="popup-main">
                    <div class="popup-icon ${config.iconClass}"></div>
                    <div class="popup-text-container">
                        <div class="popup-inline-text">
                            <span class="popup-action-type">${type.toUpperCase()}:</span>
                            <span class="popup-action-text">${formattedText}</span>
                        </div>
                    </div>
                </div>
                <div class="popup-glow-line"></div>
            </div>
            <div class="popup-tail">
                <div class="popup-tail-arrow"></div>
            </div>
        `

    return popup
  }

  getActionConfig(type) {
    const configs = {
      do: {
        iconClass: "icon-activity",
      },
      me: {
        iconClass: "icon-user",
      },
      med: {
        iconClass: "icon-stethoscope",
      },
      animal: {
        iconClass: "icon-animal",
      },
    }

    return configs[type] || configs["do"]
  }

  fadeOutPopup(source) {
    const popup = this.activePopups.get(source)
    if (popup) {
      if (this.popupTimeouts.has(source)) {
        clearTimeout(this.popupTimeouts.get(source))
        this.popupTimeouts.delete(source)
      }
      
      popup.classList.add("fade-out")
      setTimeout(() => {
        this.hidePopup(source)
      }, 500)
    }
  }
}

document.addEventListener("DOMContentLoaded", () => {
  new ActionPopupManager()
})