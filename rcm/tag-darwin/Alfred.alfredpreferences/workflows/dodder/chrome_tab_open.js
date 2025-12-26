#! /usr/bin/osascript -l JavaScript

function run (argv) {
  const urlSelected = argv[0]
  const chrome = Application('Google Chrome')
  const windows = chrome.windows()

  for (const idxWindow in windows) {
    for (const idxTab in windows[idxWindow].tabs) {
      if (windows[idxWindow].tabs[idxTab].url() == urlSelected) {
        chrome.windows[idxWindow].activeTabIndex = parseInt(idxTab) + 1
        chrome.windows[idxWindow].index = 1
        chrome.activate()
        return
      }
    }
  }
}
