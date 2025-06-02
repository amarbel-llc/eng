export async function isOurBid(ourBid, item) {
  let theirBid = item.id.browser;

  if (theirBid.browser != ourBid.browser || theirBid.id != ourBid.id) {
    return false;
  }

  return true;
}
export async function windowsWithTabs(windowOrWindowList) {
  if (Array.isArray(windowOrWindowList)) {
    const windows = windowOrWindowList;

    return await Promise.all(
      windows.map(async function(w) {
        w["tabs"] = await browser.tabs.query({ windowId: w["id"] });
        return w;
      })
    );
  } else {
    const w = windowOrWindowList;
    w["tabs"] = await browser.tabs.query({ windowId: w["id"] });
    return w;
  }
}

export async function tabsFromWindows(windowOrWindowList) {
  if (Array.isArray(windowOrWindowList)) {
    const windows = windowOrWindowList;

    return (
      await Promise.all(
        windows.map(async function(w) {
          return await browser.tabs.query({ windowId: w["id"] });
        })
      )
    ).flat();
  } else {
    const w = windowOrWindowList;
    return await browser.tabs.query({ windowId: w["id"] });
  }
}

export async function removeBookmarks(urls) {
  if (urls === undefined) {
    return;
  }

  let bookmarks = await browser.bookmarks.search({});
  let removeBookmarks = [];

  await Promise.all(
    bookmarks.reduce((acc, bm) => {
      if (urls.includes(bm.url)) {
        acc.push(browser.bookmarks.remove(bm.id));
      }

      return acc;
    }, [])
  );
}

export const cleanWindowForSave = function(w) {
  delete w["alwaysOnTop"];
  delete w["id"];
  delete w["left"];
  delete w["top"];
  delete w["width"];
  delete w["height"];

  w.tabs = w.tabs.map(cleanTabForSave);

  return w;
};

export async function getTabFromTabId(tabId) {
  if (tabId === "last-focused") {
    let w = await browser.windows.getLastFocused();
    let tabs = await browser.tabs.query({ active: true, windowId: w.id });

    if (tabs.length != 1) {
      throw new Error("must have at least one tab focused");
    }

    return tabs[0];
  } else {
    tabId = parseInt(tabId);
    return await browser.tabs.get(tabId);
  }
}

export async function normalizeTabId(tabId) {
  if (tabId === "last-focused") {
    let w = await browser.windows.getLastFocused();
    let tabs = await browser.tabs.query({ active: true, windowId: w.id });

    if (tabs.length != 1) {
      throw new Error("must have at least one tab focused");
    }

    return tabs[0].id;
  } else {
    return parseInt(tabId);
  }
}

export async function normalizeWindowId(windowId) {
  if (windowId === "last-focused") {
    let w = await browser.windows.getLastFocused();
    return w.id;
  } else {
    return parseInt(windowId);
  }
}

export async function getNonAppWindows() {
  return (await browser.windows.getAll()).filter((w) => w["type"] !== "app");
}

export async function getWindowWithID(windowID) {
  var w;

  if (windowID === "last-focused") {
    w = browser.windows.getLastFocused();
  } else {
    w = browser.windows.get(parseInt(windowID));
  }

  return await windowsWithTabs(await w);
}

export const makeTabs = async function(bodies) {
  const ws = await browser.windows.getAll();

  if (ws.length == 0) {
    return browser.windows.create(bodies.map((b) => b.url));
  } else {
    return Promise.all(bodies.map((b) => browser.tabs.create(b)));
  }
};

export const makeTab = async function(body) {
  try {
    const ws = await browser.windows.getAll();

    if (ws.length == 0) {
      return await browser.windows.create(body);
    } else {
      return await browser.tabs.create(body);
    }
  } catch {
    return await browser.windows.create(body);
  }
};

export const makeTabWithWindowId = async function(body, wid) {
  body.windowId = wid;
  return makeTab(body);
};

export const cleanTabForSave = function(t) {
  delete t["audible"];
  delete t["autoDiscardable"];
  delete t["discarded"];
  delete t["favIconUrl"];
  delete t["groupId"];
  delete t["height"];
  delete t["highlighted"];
  delete t["id"];
  delete t["incognito"];
  delete t["lastAccessed"];
  delete t["mutedInfo"];
  delete t["openerTabId"];
  delete t["status"];
  delete t["title"];
  delete t["width"];
  delete t["windowId"];
  return t;
};

export async function updateTab(body, groupCache, windowCache) {
  const id = body.id;
  delete body.id;

  if (body.windowIdOrName) {
    let windowId = parseInt(body.windowIdOrName);

    if (isNaN(windowId)) {
      windowId = windowCache[body.windowIdOrName];
    }

    if (windowId == -1) {
      await browser.tabs.remove(id);
    } else {
      if (!windowId) {
        const w = await browser.windows.create({ tabId: id });
        windowId = w.id;
      } else {
        await browser.tabs.move(id, {
          index: -1,
          windowId: windowId,
        });
      }

      windowCache[body.windowIdOrName] = windowId;
    }

    delete body.windowIdOrName;
  }

  if (body.groupIdOrName) {
    let groupId = parseInt(body.groupIdOrName);
    let groupObj = {
      tabIds: id,
    };

    if (isNaN(groupId)) {
      groupId = groupCache[groupIdOrName];
    }

    if (!groupId) {
      groupObj["groupId"] = groupId;
    }

    if (groupId == -1) {
      groupId = await browser.tabs.ungroup(id);

      groupCache[body.groupIdOrName] = groupId;
    } else {
      groupId = await browser.tabs.group({
        tabIds: id,
        groupId: groupId,
      });

      groupCache[body.groupIdOrName] = groupId;
    }

    delete body.groupIdOrName;
  }

  if (body.open) {
    delete body.open;
    body.active = true;
    await openTab(id);
  }

  delete body.open;

  return await browser.tabs.update(id, body);
}

export async function openTab(tabId) {
  tabId = await normalizeTabId(tabId);
  let tab = await browser.tabs.get(tabId);
  let windowId = tab.windowId;
  await Promise.all([
    browser.windows.update(windowId, { focused: true }),
    browser.tabs.update(tabId, { active: true }),
  ]);
}

export async function removeTabs(urls) {
  if (urls === undefined) {
    return;
  }

  let tabs = await tabsFromWindows(await browser.windows.getAll());

  await browser.tabs.remove(
    tabs.reduce((acc, tab) => {
      if (urls.includes(tab.url)) {
        acc.push(tab.id);
      }

      return acc;
    }, [])
  );
}

export const stringToUtf8Array = (function() {
  const encoder = new TextEncoder("utf-8");
  return (str) => encoder.encode(str);
})();
