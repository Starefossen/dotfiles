module.exports = {
  // Your "Personal" profile is the fallback for everything else
  defaultBrowser: {
    name: "Safari",
    profile: "Personal"
  },
  
  options: {
    // Hide the finicky icon from the menu bar
    hideIcon: false,
    checkForUpdate: true,
  },

  handlers: [
    {
      // NAV (Work) Profile
      match: [
        "*.nav.no*",
        "*github.com/navikt*",
        "*.slack.com*",
        "*slack-edge.com*",
        "*zoom.us*",
        "*.nais.io*"
      ],
      browser: {
        name: "Safari",
        profile: "Nav"
      }
    },
    {
      // Developer Profile
      match: [
        "github.com*",
        "*.github.com*",
        "stackoverflow.com*",
        "*.aws.amazon.com*",
        "console.cloud.google.com*"
      ],
      browser: {
        name: "Safari",
        profile: "Developer"
      }
    },
    {
      // Social Profile
      match: [
        "*.facebook.com*",
        "*.twitter.com*",
        "*.x.com*",
        "bsky.app*",
        "*.linkedin.com*",
        "*.instagram.com*"
      ],
      browser: {
        name: "Safari",
        profile: "Social"
      }
    },
    {
      // Figma Links -> Native App
      match: "https://www.figma.com/file/*",
      browser: "Figma",
    }
  ]
};
