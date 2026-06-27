import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const dark = document.documentElement.classList.toggle("dark")
    localStorage.setItem("theme", dark ? "dark" : "light")
  }
}
