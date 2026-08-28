(() => {
  "use strict";

  const languageKey = "photoreport-site-language";
  const supportedLanguages = new Set(["zh", "en"]);
  const page = document.body.dataset.page || "home";

  const pageMetadata = {
    home: {
      zh: {
        title: "现场照片记录 — 拍摄、标注、整理分享",
        description:
          "现场照片记录是一款本地优先的 iOS 照片整理工具：拍摄、标注、编号并生成便于分享的 PDF 沟通记录。",
      },
      en: {
        title: "Site Photo Log — Capture, Mark Up, Organize, Share",
        description:
          "A local-first iOS tool for capturing, annotating, numbering, and organizing site photos into shareable PDF records.",
      },
    },
    privacy: {
      zh: {
        title: "现场照片记录隐私政策",
        description:
          "了解现场照片记录的本地存储、系统权限、分享、备份与删除方式。",
      },
      en: {
        title: "Site Photo Log Privacy Policy",
        description:
          "Learn how Site Photo Log handles on-device storage, system permissions, sharing, backups, and deletion.",
      },
    },
  };

  function preferredLanguage() {
    const queryLanguage = new URLSearchParams(window.location.search).get("lang");
    if (supportedLanguages.has(queryLanguage)) return queryLanguage;

    try {
      const saved = window.localStorage.getItem(languageKey);
      if (supportedLanguages.has(saved)) return saved;
    } catch (_) {
      // The site remains usable when browser storage is unavailable.
    }

    return navigator.language.toLowerCase().startsWith("zh") ? "zh" : "en";
  }

  function updateInternalLinks(language) {
    document.querySelectorAll("[data-language-link]").forEach((link) => {
      const href = link.getAttribute("href");
      if (!href || href.startsWith("#") || href.startsWith("mailto:")) return;

      try {
        const url = new URL(href, window.location.href);
        if (!["http:", "https:", "file:"].includes(url.protocol)) return;
        if (url.protocol !== "file:" && url.origin !== window.location.origin) return;
        url.searchParams.set("lang", language);
        link.href = url.href;
      } catch (_) {
        // Leave malformed or unsupported links unchanged.
      }
    });
  }

  function setLanguage(language, persist = true) {
    if (!supportedLanguages.has(language)) return;

    document.documentElement.lang = language === "zh" ? "zh-CN" : "en";

    document.querySelectorAll("[data-zh][data-en]").forEach((element) => {
      element.textContent = element.dataset[language];
    });

    document.querySelectorAll("[data-lang-choice]").forEach((button) => {
      button.setAttribute(
        "aria-pressed",
        String(button.dataset.langChoice === language),
      );
    });

    document.querySelectorAll("[data-policy-language]").forEach((block) => {
      block.hidden = block.dataset.policyLanguage !== language;
    });

    document.querySelectorAll("[data-anchor-zh][data-anchor-en]").forEach((link) => {
      const target = link.dataset[`anchor${language === "zh" ? "Zh" : "En"}`];
      const href = link.getAttribute("href") || "";
      if (href.startsWith("#")) {
        link.setAttribute("href", `#${target}`);
        return;
      }

      try {
        const url = new URL(href, window.location.href);
        url.hash = target;
        link.href = url.href;
      } catch (_) {
        // Leave malformed links unchanged.
      }
    });

    const metadata = pageMetadata[page]?.[language];
    if (metadata) {
      document.title = metadata.title;
      const description = document.querySelector('meta[name="description"]');
      if (description) description.content = metadata.description;
    }

    updateInternalLinks(language);

    if (persist) {
      try {
        window.localStorage.setItem(languageKey, language);
      } catch (_) {
        // The selected language still applies to this page view.
      }
    }
  }

  setLanguage(preferredLanguage(), false);

  document.querySelectorAll("[data-lang-choice]").forEach((button) => {
    button.addEventListener("click", () => setLanguage(button.dataset.langChoice));
  });

  document.querySelectorAll("[data-current-year]").forEach((element) => {
    element.textContent = String(new Date().getFullYear());
  });

  const header = document.querySelector("[data-header]");
  const updateHeader = () => {
    if (!header || page === "privacy") return;
    header.classList.toggle("is-scrolled", window.scrollY > 18);
  };
  updateHeader();
  window.addEventListener("scroll", updateHeader, { passive: true });

  const menuButton = document.querySelector("[data-menu-button]");
  const navigation = document.querySelector("[data-nav]");

  const closeMenu = () => {
    menuButton?.setAttribute("aria-expanded", "false");
    navigation?.classList.remove("is-open");
    document.body.classList.remove("menu-open");
  };

  menuButton?.addEventListener("click", () => {
    const willOpen = menuButton.getAttribute("aria-expanded") !== "true";
    menuButton.setAttribute("aria-expanded", String(willOpen));
    navigation?.classList.toggle("is-open", willOpen);
    document.body.classList.toggle("menu-open", willOpen);
  });

  navigation?.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeMenu);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeMenu();
  });

  const desktopQuery = window.matchMedia("(min-width: 841px)");
  desktopQuery.addEventListener?.("change", (event) => {
    if (event.matches) closeMenu();
  });
})();
