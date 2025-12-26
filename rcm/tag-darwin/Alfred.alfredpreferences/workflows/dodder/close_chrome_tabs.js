#! /usr/bin/osascript -l JavaScript

function run(argv) {
  const chrome = Application("Google Chrome");

  count = 0;

  chrome.windows().forEach((window, winIdx) => {
    window.tabs().forEach((tab, tabIdx) => {
      count += 1;
      tab.close();
    });
  });

  return JSON.stringify(count);
}
