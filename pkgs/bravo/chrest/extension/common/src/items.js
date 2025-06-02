import * as lib from "./lib.js";

export async function focusUrlItems(bid, items) {
  if (items === undefined || items === null) {
    return null;
  }

  return await Promise.all(
    items.map(item => focusUrlItem(bid, item)),
  );
}

export async function focusUrlItem(bid, item) {
  if (item === undefined || item === null) {
    return null;
  }

  if (getItemType(item) !== "tab") {
    throw new Error("cannot focus non-tab item");
  }

  //TODO filter other BID's

  let tab = await lib.getTabFromTabId(item.id.id);

  await Promise.all(
    [
      await browser.tabs.update(tab.id, { active: true }),
      await browser.windows.update(tab.windowId, { focused: true, drawAttention: true }),
    ],
  );

  return item;
}

export async function makeUrlItems(bid, items) {
  if (items === undefined || items === null) {
    return [];
  }

  let groupedItems = Object.groupBy(items, getItemType);

  if (groupedItems.history !== undefined) {
    throw new Error("cannot add history items");
  }

  let results = await Promise.all(
    [
      makeUrlItemTabs(bid, groupedItems.tab),
      makeUrlItemBookmarks(bid, groupedItems.bookmark),
    ],
  );

  return results.flat();
}

export function getItemType(item) {
  let itemType = "tab";

  if (item.id !== undefined && item.id.type !== undefined) {
    itemType = item.id.type;
  }

  return itemType;
}

export async function makeUrlItemBookmarks(bid, items) {
  if (items == undefined) {
    return [];
  }

  return items.map(item => {
    Object.assign(
      result,
      urlItemForBookmark(
        bid,
        browser.bookmarks.create({
          title: item.title,
          url: item.url,
        })
      )
    )
  });
}

export async function makeUrlItemTabs(bid, items) {
  if (items == undefined) {
    return [];
  }

  let groupedTabs = Object.groupBy(items, item => item.windowId);
  let windowPromises = {};

  for (let windowId in groupedTabs) {
    let windowItems = groupedTabs[windowId];
    windowId = await lib.normalizeWindowId(windowId);

    windowPromises[windowId] = makeUrlItemTabsForWindowId(
      windowId,
      windowItems,
    );
  }

  let windowItems = await Promise.all(
    Object.keys(windowPromises).map(
      async windowId => {
        let windowTabs = await windowPromises[windowId];

        return windowTabs.map(
          (tab, idx) => {
            let item = groupedTabs[windowId][idx];
            let url = item.url;
            return { ...urlItemForTabWithUrl(bid, tab, url) };
          },
        );
      },
    ),
  );

  return windowItems.flat();
}

export async function makeUrlItemTabsForWindowId(windowId, items) {
  let window = null;

  try {
    window = browser.windows.get(windowId);

    // TODO filter other BID's
    return await Promise.all(
      items.map(
        item => {
          let url = item.url;
          return browser.tabs.create({ url: url, windowId: windowId });
        }
      ),
    );
  } catch (e) {
    window = browser.windows.create({
      url: items.map(item => item.url),
    });

    return (await window).tabs;
  }
}

export function urlItemForTab(bid, tab) {
  return urlItemForTabWithUrl(bid, tab, tab.url);
}

export function urlItemForTabWithUrl(bid, tab, url) {
  return {
    title: tab.title,
    id: {
      browser: bid,
      id: tab.id.toString(),
      type: "tab",
    },
    windowId: tab.windowId.toString(),
    url: url,
    date: new Date(tab.lastAccessed),
  };
}

export function urlItemForBookmark(bid, o) {
  return {
    title: o.title,
    id: {
      browser: bid,
      id: o.id.toString(),
      type: "bookmark",
    },
    url: o.url,
    date: new Date(o.dateAdded),
  };
}

export async function allTabItems(bid) {
  return (await lib.tabsFromWindows(await lib.getNonAppWindows())).map(
    o => urlItemForTab(bid, o)
  );
}

export async function allBookmarkItems(bid) {
  return (await browser.bookmarks.search({}))
    .filter((b) => {
      b.children === undefined || b.type === "bookmark"
    })
    .map(o => urlItemForBookmark(bid, o));
}

export async function allHistoryItems(bid) {
  let history = await browser.history.search({
    startTime: 0,
    maxResults: 100_000,
    text: "",
  });

  return history.map((o) => ({
    title: o.title,
    id: {
      browser: bid,
      id: o.id.toString(),
      type: "history",
    },
    url: o.url,
    date: new Date(o.lastVisitTime),
  }));
}

export async function removeUrlItems(bid, items) {
  if (items === undefined) {
    return [];
  }

  let promises = [];

  let results = items.filter((item) => {
    let theirBid = item.id.browser;

    if (theirBid.browser != bid.browser || theirBid.id != bid.id) {
      return false;
    }

    try {
      if (item.id.type == "bookmark") {
        promises.push(browser.bookmarks.remove(item.id.id));
        return true;
      } else if (item.id.type == "tab") {
        promises.push(browser.tabs.remove(parseInt(item.id.id)));
        return true;
      } else {
        // TODO find in all urls
        console.log(item);
        return false;
      }
    } catch (e) {
      console.log("failed to remove item", item);
      return false;
    }
  });

  await Promise.all(promises);
  console.log(promises, results);

  return results;
}
