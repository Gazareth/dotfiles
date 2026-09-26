export default {
  defaultBrowser: "Safari",
  handlers: [
    {
      match: [
        "localhost:*",
        "http://localhost:*",
        "https://localhost:*",
        "*chetwoodbank.co.uk",
        "*modamortgages.co.uk",
      ],
      browser: "Google Chrome",
    },
    {
      match: [
        "https://chetwood.atlassian.net/*",
        "https://github.com/chetwoodfinancial/treasury/*",
      ],
      browser: "Microsoft Edge",
    },
  ],
};
