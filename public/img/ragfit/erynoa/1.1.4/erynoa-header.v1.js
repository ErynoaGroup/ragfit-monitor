// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Erynoa — <erynoa-header> v1.1.4. No deps, no network calls, no tracking.
// Usage: <erynoa-header current="plan" [domain="example.org"] [skip-target="#main"] [home="https://…/"] [theme="dark|light"] [assets="/assets/erynoa/1.1.4/"]></erynoa-header>
// home defaults to https://source.<domain>/; assets defaults to the directory this script was loaded from.
// Without `domain`, the base domain is derived from location.hostname by dropping the first label
// (plan.example.org -> example.org). Requires erynoa-header.v1.css loaded in the page.
(() => {
  const SCRIPT_BASE = (document.currentScript && document.currentScript.src) ? new URL(".", document.currentScript.src).href : "";
  const SERVICES = [["source", "Source"], ["plan", "Plan"], ["memory", "Memory"], ["docs", "Docs"], ["auth", "Auth"], ["monitor", "Monitor"]];
  const baseDomain = (h) => { const p = h.split("."); return p.length > 2 ? p.slice(1).join(".") : h; };
  class ErynoaHeader extends HTMLElement {
    static get observedAttributes() { return ["current", "domain", "skip-target", "home", "theme", "assets"]; }
    connectedCallback() { this.render(); }
    attributeChangedCallback() { if (this.isConnected) this.render(); }
    render() {
      const domain = this.getAttribute("domain") || baseDomain(location.hostname);
      const current = this.getAttribute("current") || "";
      const skip = this.getAttribute("skip-target") || "#main";
      const home = this.getAttribute("home") || `https://source.${domain}/`;
      const theme = this.getAttribute("theme");
      const slot = this.querySelector(".erh-slot-end");
      const h = document.createElement("header");
      h.className = "erh"; h.setAttribute("role", "banner"); h.dataset.erynoaHeader = "1.1.4";
      if (theme === "dark" || theme === "light") h.dataset.erhTheme = theme;
      const a = (cls, href, text) => { const e = document.createElement("a"); e.className = cls; e.href = href; if (text) e.textContent = text; return e; };
      h.append(a("erh-skip", skip, "Skip to content"));
      const brand = a("erh-brand", home); brand.setAttribute("aria-label", "Erynoa");
      const base = this.getAttribute("assets") || SCRIPT_BASE;
      const NS = "http://www.w3.org/2000/svg";
      const logo = document.createElementNS(NS, "svg");
      logo.setAttribute("class", "erh-logo"); logo.setAttribute("viewBox", "0 0 1150 347"); logo.setAttribute("fill", "currentColor");
      logo.setAttribute("aria-hidden", "true"); logo.setAttribute("focusable", "false");
      for (const id of ["monogram", "divider", "wordmark"]) { const u = document.createElementNS(NS, "use"); u.setAttribute("href", `${base}erynoa-en-lockup.svg#${id}`); logo.append(u); }
      brand.append(logo); h.append(brand);
      const nav = document.createElement("nav"); nav.className = "erh-nav"; nav.setAttribute("aria-label", "RagFit services");
      const ul = document.createElement("ul");
      for (const [id, label] of SERVICES) {
        const li = document.createElement("li"); const l = a("", `https://${id}.${domain}/`, label);
        l.dataset.erhService = id; if (id === current) l.setAttribute("aria-current", "page");
        li.append(l); ul.append(li);
      }
      nav.append(ul); h.append(nav);
      // Even narrower hosts: bring a focused link fully into view (Chrome skips partially visible ones).
      nav.addEventListener("focusin", (e) => { if (e.target.scrollIntoView) e.target.scrollIntoView({ inline: "nearest", block: "nearest" }); });
      const end = slot || document.createElement("div"); end.className = "erh-slot-end"; h.append(end);
      this.replaceChildren(h);
    }
  }
  if (!customElements.get("erynoa-header")) customElements.define("erynoa-header", ErynoaHeader);
})();
