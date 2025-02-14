// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import "../vendor/canvas-confetti";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  hooks: {
    confetti: {
      mounted() {
        let timeout;
    
        this.handleEvent("confetti", () => {
          this.el.classList.remove("hidden");
    
          confetti({
            particleCount: 250,
            spread: 150,
            ticks: 500,
            origin: { y: 0 },
          });
    
          if (timeout) {
            clearTimeout(timeout);
          }
    
          timeout = setTimeout(() => {
            this.el.classList.add("hidden");
          }, 30000);
        });
      },
    },
    time: {
      mounted() {
        this.updateTime();
      },
      updateTime() {
        const timestamp = new Date(this.el.getAttribute("data-timestamp"));
        this.el.textContent = this.formatLocalTime(timestamp);
      },
      formatLocalTime(timestamp) {
        return timestamp.toLocaleString("en-US", {
          weekday: "short", // "Fri"
          hour: "2-digit",  // "15"
          minute: "2-digit", // "29"
          second: "2-digit", // "03"
          hour12: false, // 24-hour format
        }).replace(" ", ", "); // Remove comma to match "Fri 15:29:03"
      }
    },
    timestamp: {
      mounted() {
        this.updateTimestamps();
        this.interval = setInterval(() => this.updateTimestamps(), 1000);
      },
      destroyed() {
        clearInterval(this.interval);
      },
      updateTimestamps() {
        const now = new Date();
        this.el.querySelectorAll(".relative-time").forEach((el) => {
          const timestamp = new Date(el.closest("[data-timestamp]").getAttribute("data-timestamp"));
          const secondsAgo = Math.round((now - timestamp) / 1000);
          el.textContent = this.formatRelativeTime(secondsAgo);
        });
      },
      formatRelativeTime(secondsAgo) {
        if (secondsAgo < 60) {
          return `${secondsAgo} seconds ago`;
        } else if (secondsAgo < 3600) {
          const minutes = Math.floor(secondsAgo / 60);
          return `${minutes} minute${minutes > 1 ? "s" : ""} ago`;
        } else if (secondsAgo < 86400) {
          const hours = Math.floor(secondsAgo / 3600);
          return `${hours} hour${hours > 1 ? "s" : ""} ago`;
        } else {
          const days = Math.floor(secondsAgo / 86400);
          return `${days} day${days > 1 ? "s" : ""} ago`;
        }
      },
    },
    marquee: {
      mounted() {
        const marqueeContainer = this.el;
        let scrollSpeed = 2;
    
        marqueeContainer.innerHTML += marqueeContainer.innerHTML;
    
        let scrollAmount = 0;
    
        function animateMarquee() {
          scrollAmount -= scrollSpeed;
          if (Math.abs(scrollAmount) >= marqueeContainer.scrollWidth / 2) {
            scrollAmount = 0; 
          }
          marqueeContainer.style.transform = `translateX(${scrollAmount}px)`;
          requestAnimationFrame(animateMarquee);
        }
    
        animateMarquee();
      },
    
      updated() {
        const marqueeContainer = this.el;
    
        marqueeContainer.innerHTML += marqueeContainer.innerHTML;
        marqueeContainer.style.transform = `translateX(0px)`;
      }
    }
  },
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())


// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

