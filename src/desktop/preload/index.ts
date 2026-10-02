import { contextBridge, ipcRenderer } from 'electron'
import { electronAPI } from '@electron-toolkit/preload'
import { IpcEvents } from '@cinny-electron/core'
import log from 'electron-log/renderer'

Object.assign(console, log.functions)

// Custom APIs for renderer
const api = {}

// Use `contextBridge` APIs to expose Electron APIs to
// renderer only if context isolation is enabled, otherwise
// just add to the DOM global.
if (process.contextIsolated) {
  try {
    contextBridge.exposeInMainWorld('electron', electronAPI)
    contextBridge.exposeInMainWorld('api', api)
  } catch (error) {
    console.error(error)
  }
} else {
  // @ts-ignore (define in dts)
  window.electron = electronAPI
  // @ts-ignore (define in dts)
  window.api = api
}

const quickCssEvent = new Event('quickCssChanged')

document.onreadystatechange = async () => {
  if (document.readyState == 'complete') {
    const quickCssStyle = document.createElement('style')
    document.head.appendChild(quickCssStyle)

    ipcRenderer.on(IpcEvents.QUICKCSS_CHANGED, (_e, css) => {
      log.info('Quickcss Changed')
      document.dispatchEvent(quickCssEvent)
      quickCssStyle.innerHTML = css
    })

    ipcRenderer.send(IpcEvents.RENDERER_LOADED)
  }
}

function resetImageSrc(img: HTMLImageElement): void {
  const src = img.src
  if (src && (src.startsWith('http') || src.startsWith('blob:') || src.startsWith('data:'))) {
    img.src = ''
    img.src = src
  }
}

function handleWindowBlur(): void {
  document.querySelectorAll('img').forEach(resetImageSrc)

  document.querySelectorAll('video').forEach((video) => {
    if (!video.paused) {
      video.pause()
      video.dataset.pausedByBlur = 'true'
    }
  })
}

function handleWindowFocus(): void {
  const resume = (): void => {
    document.querySelectorAll('img').forEach(resetImageSrc)

    document.querySelectorAll('video').forEach((video) => {
      if (video.dataset.pausedByBlur === 'true') {
        delete video.dataset.pausedByBlur
        video.play().catch(() => {})
      }
    })
  }

  // Resume immediately
  resume()

  // Retry after short delay to ensure webContents animation policy has updated
  setTimeout(resume, 50)
}

window.addEventListener('blur', handleWindowBlur)
window.addEventListener('focus', handleWindowFocus)

ipcRenderer.on('window-blur', handleWindowBlur)
ipcRenderer.on('window-focus', handleWindowFocus)



