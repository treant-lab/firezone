import StatusPage from "../vendor/status_page"

let Hooks = {}

// Copy to clipboard

Hooks.Copy = {
  mounted() {
    this.el.addEventListener("click", (ev) => {
      ev.preventDefault();

      let text = ev.currentTarget.querySelector("[data-copy]").innerHTML.trim();
      let cl = ev.currentTarget.querySelector("[data-icon]").classList

      navigator.clipboard.writeText(text).then(() => {
        cl.add("hero-clipboard-document-check");
        cl.add("text-green-500");
        cl.remove("hero-clipboard-document");
        cl.remove("text-gray-500");
      })
    });
  },
}

// Update status indicator when sidebar is mounted or updated
let statusIndicatorClassNames = {
  none: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300",
  minor: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300",
  major: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300",
  critical: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300",
}

const statusUpdater = function () {
  const self = this
  const sp = new StatusPage.page({
    page: "firezone"
  })

  sp.summary({
    success: function (data) {
      const statusIndicatorClasses = statusIndicatorClassNames[data.status.indicator];
      self.el.innerHTML = `
        <span class="text-xs font-medium mr-2 px-2.5 py-0.5 rounded ${statusIndicatorClasses}">
          ${data.status.description}
        </span>
      `
      const collapsedStatusEl = document.getElementById('collapsed-status');
      if (collapsedStatusEl) {
        statusIndicatorClasses.split(' ').forEach((className) => {
          collapsedStatusEl.classList.add(className)
        });
      }
    },
    error: function (data) {
      console.error("An error occurred while fetching status page data")
      self.el.innerHTML = `<span class="${statusIndicatorClassNames.minor}">Unable to fetch status</span>`
    },
  })
}

Hooks.StatusPage = {
  mounted: statusUpdater,
  updated: statusUpdater,
}

Hooks.Aside = {
  mounted: function () {
    window.addEventListener("phx:aside:toggle-collapse-menu", (event) => {
      localStorage.setItem("aside:collapse-menu", event.detail.aside_collapsed);
    })
    const currentMenuState = localStorage.getItem("aside:collapse-menu") || false;

    this.pushEvent("collapse-menu-state", {
      aside_collapsed: currentMenuState
    })
  }
}

export default Hooks