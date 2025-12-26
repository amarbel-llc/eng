#! /usr/bin/osascript -l JavaScript

function run(argv) {
  const chrome = Application("Google Chrome");

  tabs = [];

  chrome.windows().forEach((window, winIdx) => {
    window.tabs().forEach((tab, tabIdx) => {
      tabs.push({ title: tab.title(), url: tab.url() });
    });
  });

  return JSON.stringify(tabs);
}
