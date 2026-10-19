(async function catppuccin() {
  if (
    !(
      Spicetify.Platform &&
      Spicetify.React &&
      Spicetify.ReactDOM &&
      Spicetify.Config &&
      Spicetify.Platform.History
    )
  ) {
    setTimeout(catppuccin, 100);
    return;
  }

  // Accent colors
  const accents = [
    "none",
    "rosewater",
    "flamingo",
    "pink",
    "maroon",
    "red",
    "peach",
    "yellow",
    "green",
    "teal",
    "sapphire",
    "blue",
    "sky",
    "mauve",
    "lavender",
  ];

  function applyAccent(selectedValue, colorScheme) {
    const accent = selectedValue === "none" ? "text" : selectedValue;
    const properties = {
      "--spice-text": `var(--spice-${selectedValue})`,
      "--spice-button-active": `var(--spice-${selectedValue})`,
      "--spice-equalizer": document.querySelector(
        "body > script.marketplaceScript"
      )
        ? `url('https://github.com/catppuccin/spicetify/blob/main/catppuccin/assets/${colorScheme}/equalizer-animated-${accent}.gif?raw=true')`
        : `url('${colorScheme}/equalizer-animated-${accent}.gif')`,
    };

    Object.entries(properties).forEach(([property, value]) => {
      if (value.includes("none")) {
        document.documentElement.style.removeProperty(property);
      } else {
        document.documentElement.style.setProperty(property, value);
      }
    });
  }

  // Create our own section matching spotifys style and structure
  const Section = Spicetify.React.memo(() => {
    const colorScheme = Spicetify.Config.color_scheme || "frappe";
    const initialValue =
      localStorage.getItem("catppuccin-accentColor") ?? "none";
    const [selectedValue, setSelectedValue] =
      Spicetify.React.useState(initialValue);

    Spicetify.React.useEffect(() => {
      applyAccent(selectedValue, colorScheme);

      if (initialValue !== selectedValue) {
        localStorage.setItem("catppuccin-accentColor", selectedValue);
      }
    }, [selectedValue]);

    return Spicetify.React.createElement(
      "div",
      { className: "x-settings-section" },
      [
        Spicetify.React.createElement(
          "h2",
          {
            "data-encore-id": "type",
            className:
              "TextElement-bodyMediumBold-textBase-text encore-text-body-medium-bold",
          },
          "Catppuccin"
        ),
        Spicetify.React.createElement("div", { className: "x-settings-row" }, [
          Spicetify.React.createElement(
            "div",
            { className: "x-settings-firstColumn" },
            [
              Spicetify.React.createElement(
                "label",
                {
                  htmlFor: "desktop.settings.selectLanguage",
                  className:
                    "TextElement-bodySmall-textSubdued-text encore-text-body-small",
                  "data-encore-id": "type",
                },
                "Choose an accent color"
              ),
            ]
          ),
          Spicetify.React.createElement(
            "div",
            { className: "x-settings-secondColumn" },
            [
              Spicetify.React.createElement("span", null, [
                Spicetify.React.createElement(
                  "select",
                  {
                    className: "main-dropDown-dropDown",
                    id: "desktop.settings.selectLanguage",
                    dir: "auto",
                    value: selectedValue,
                    onChange: (event) => {
                      setSelectedValue(event.target.value);
                    },
                  },
                  accents.map((option) => {
                    return Spicetify.React.createElement(
                      "option",
                      {
                        key: option,
                        value: option,
                        selected: option === selectedValue,
                      },
                      option
                    );
                  })
                ),
              ]),
            ]
          ),
        ]),
      ]
    );
  });

  let settingsObserver = null;

  function mountSettingsSection() {
    const header = document.querySelector(
      "[data-testid='settings-page'] > div:first-of-type, .x-settings-headerContainer"
    );
    if (!header?.parentNode) return false;

    if (!header.parentNode.querySelector("#catppuccin-settings-section")) {
      const sectionContainer = document.createElement("div");
      sectionContainer.id = "catppuccin-settings-section";
      Spicetify.ReactDOM.render(
        Spicetify.React.createElement(Section),
        sectionContainer
      );
      header.parentNode.insertBefore(sectionContainer, header.nextSibling);
    }
    return true;
  }

  // Mount when the SPA creates the settings header, without a millisecond poll.
  function insertOption(name) {
    if (name !== "/preferences") {
      settingsObserver?.disconnect();
      settingsObserver = null;
      return;
    }

    if (mountSettingsSection()) {
      settingsObserver?.disconnect();
      settingsObserver = null;
      return;
    }

    if (settingsObserver) return;
    settingsObserver = new MutationObserver(() => {
      if (mountSettingsSection()) {
        settingsObserver.disconnect();
        settingsObserver = null;
      }
    });
    settingsObserver.observe(document.documentElement, {
      childList: true,
      subtree: true,
    });
  }

  // Apply the saved accent without mounting a detached React tree.
  applyAccent(
    localStorage.getItem("catppuccin-accentColor") ?? "none",
    Spicetify.Config.color_scheme || "frappe"
  );

  // Initialize + Listener
  insertOption(Spicetify.Platform.History.location?.pathname);
  Spicetify.Platform.History.listen((event) => {
    insertOption(event.pathname);
  });
})();
