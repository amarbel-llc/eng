// Use https://finicky-kickstart.now.sh to generate basic configuration
// Learn more about configuration options: https://github.com/johnste/finicky/wiki/Configuration
// @ts-check

/**
 * @typedef {import('/Applications/Finicky.app/Contents/Resources/finicky.d.ts').FinickyConfig} FinickyConfig
 */

/**
 * @type {FinickyConfig}
 */
export default {
  defaultBrowser: "Google Chrome",
  options: {
    checkForUpdates: false,
    logRequests: false,
    keepRunning: true,
    hideIcon: true
  },
};
