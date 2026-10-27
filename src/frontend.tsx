import './instrument.client'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
import { reactErrorHandler } from '@sentry/react'

const elem = document.getElementById('root')!
const app = (
  <StrictMode>
    <App />
  </StrictMode>
)

;(import.meta.hot.data.root ??= createRoot(elem, {
  onUncaughtError: reactErrorHandler(),
  onCaughtError: reactErrorHandler(),
  onRecoverableError: reactErrorHandler()
})).render(app)
