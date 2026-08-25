module.exports = {
  // Use Safari as the default browser for everything
  defaultBrowser: "Safari",
  
  handlers: [
    {
      // Open work-related links in Firefox Developer Edition
      match: [
        "*.nav.no*",
        "*github.com/navikt*",
        "*.slack.com*",
        "*slack-edge.com*",
        "*zoom.us*"
      ],
      browser: "Firefox Developer Edition"
    },
    {
      // Open Figma links directly in the Figma desktop app
      match: "https://www.figma.com/file/*",
      browser: "Figma",
    }
  ]
};
