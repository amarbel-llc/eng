
if (typeof browser == "undefined") {
  // Chrome does not support the browser namespace yet.
  globalThis.browser = chrome;
}

function saveOptions(e) {
  e.preventDefault();
  browser.storage.sync.set({
    browser_id: document.querySelector("#browser-id").value,
  });
}

function restoreOptions() {
  function setCurrentChoice(result) {
    document.querySelector("#browser-id").value = result.browser_id || "";
  }

  function onError(error) {
    console.log(`Error: ${error}`);
  }

  let getting = browser.storage.sync.get("browser_id");
  getting.then(setCurrentChoice, onError);
}

document.addEventListener("DOMContentLoaded", restoreOptions);
document.querySelector("form").addEventListener("submit", saveOptions);

