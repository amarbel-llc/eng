import * as lib from "./lib.js";
import * as items from "./items.js";

export let Routes = {};

Routes["/"] = {
  async get(req) {
    return {
      status: 200,
      body: {
        browser: "firefox",
        platform_info: browser.runtime.getPlatformInfo(),
        request: req,
      },
    };
  },
};

Routes["/items"] = {
  async get(req) {
    return {
      status: 200,
      body: [
        // TODO return favicon data
        await items.allTabItems(req.browser_id),
        await items.allBookmarkItems(req.browser_id),
        await items.allHistoryItems(req.browser_id),
      ].flat(),
    };
  },
  async put(req) {
    let isOurBid = function(item) {
      return lib.isOurBid(req.browser_id, item);
    };

    if (req.body.added == undefined) {
      req.body.added = [];
    }

    if (req.body.deleted == undefined) {
      req.body.deleted = [];
    }

    if (req.body.focused == undefined) {
      req.body.focused = [];
    }

    // TODO check existing tabs for "added" elements and switch them to
    // "focused"
    let body = {
      added: await items.makeUrlItems(req.browser_id, req.body.added.filter(isOurBid)),
      deleted: await items.removeUrlItems(req.browser_id, req.body.deleted.filter(isOurBid)),
      focused: await items.focusUrlItems(req.browser_id, req.body.focused.filter(isOurBid)),
    };

    // let addedWindowIds = {}

    // for (let item of body.added) {
    //   if (item.id.type === "tab") {
    //     addedWindowIds[item.windowId] = true;
    //     break;
    //   }
    // }

    // await Promise.all(Object.keys(addedWindowIds).map(
    //   windowId => browser.windows.update(parseInt(windowId), { focused: true, drawAttention: true })),
    // );

    return {
      body: body,
      status: 200,
    };
  },
};

//  ____  _        _
// / ___|| |_ __ _| |_ ___
// \___ \| __/ _` | __/ _ \
//  ___) | || (_| | ||  __/
// |____/ \__\__,_|\__\___|
//

Routes["/state"] = {
  description:
    "Save, restore, or clear browser windows and tabs with to a state",
  async get(req) {
    const windows = await browser.windows.getAll();
    return {
      status: 200,
      body: (await lib.windowsWithTabs(windows)).map(lib.cleanWindowForSave),
    };
  },
  async delete(req) {
    await Promise.all(
      (
        await browser.windows.getAll()
      ).map((w) => {
        return browser.windows.remove(w.id);
      })
    );

    return {
      status: 204,
    };
  },
  async post(req) {
    const makePromise = async function(body) {
      let tabs = body["tabs"];
      delete body["tabs"];

      if (body.type !== "normal") {
        return null;
      }

      delete body.type;

      let w = await browser.windows.create(body);

      tabs = tabs.map((t) => {
        t = lib.cleanTabForSave(t);
        t["windowId"] = w.id;
        return t;
      });

      w.tabs = await Promise.all(tabs.map(lib.makeTab));

      return w;
    };

    return {
      status: 201,
      body: await Promise.all(req.body.map((b) => makePromise(b))),
    };
  },
};

// __        ___           _
// \ \      / (_)_ __   __| | _____      _____
//  \ \ /\ / /| | '_ \ / _` |/ _ \ \ /\ / / __|
//   \ V  V / | | | | | (_| | (_) \ V  V /\__ \
//    \_/\_/  |_|_| |_|\__,_|\___/ \_/\_/ |___/
//

Routes["/windows"] = {
  description: "Create a new window.",
  usage: 'echo "https://www.google.com" > $0',
  async post(req) {
    const makePromise = async function(body) {
      return await browser.windows.create(body);
    };

    if (Array.isArray(req.body)) {
      return {
        status: 201,
        body: await Promise.all(req.body.map((b) => makePromise(b))),
      };
    } else {
      return {
        status: 201,
        body: await makePromise(req.body),
      };
    }
  },
  async put(req) {
    const makePromise = async function(body) {
      const id = body.id;
      delete body.id;
      return await browser.windows.update(id, body);
    };

    if (Array.isArray(req.body)) {
      return {
        status: 200,
        body: await Promise.all(req.body.map((b) => makePromise(b))),
      };
    } else {
      return {
        status: 200,
        body: await makePromise(req.body),
      };
    }
  },
  async get(req) {
    const windows = await browser.windows.getAll();
    return {
      status: 200,
      body: await lib.windowsWithTabs(windows),
    };
  },
};

Routes["/windows/current"] = {
  description: `A symbolic link to /windows/[id for the last focused window].`,
  async get() {
    return {
      status: 200,
      body: await lib.windowsWithTabs(await browser.windows.getCurrent()),
    };
  },
};

// Routes["/windows/last-focused"] = {
//   description: `A symbolic link to /windows/[id for the last focused window].`,
//   async get() {
//     return {
//       status: 200,
//       body: await windowsWithTabs(await browser.windows.getLastFocused()),
//     };
//   },
// };

// Routes["/windows/last-focused/tabs"] = {
//   description: `A symbolic link to /windows/[id for the last focused window].`,
//   async get(req) {
//     return {
//       status: 200,
//       body: await browser.tabs.query({ windowId }),
//     };
//   },
//   async post(req) {
//     let w = await windowsWithTabs(await browser.windows.getLastFocused());

//     let added_tabs = await Promise.all(
//       req.body.map((url) => makeTab({ url: url, windowId: w.id }))
//     );

//     w.tabs.push(added_tabs);

//     return {
//       status: 201,
//       body: w,
//     };
//   },
// };
Routes["/windows/#WINDOW_ID"] = {
  async get({ windowId }) {
    return {
      status: 200,
      body: await lib.getWindowWithID(windowId),
    };
  },
  async put(req) {
    let wid = await lib.normalizeWindowId(req.windowId);

    return {
      status: 200,
      body: await lib.windowsWithTabs(
        await browser.windows.update(wid, req.body)
      ),
    };
  },
  async delete({ windowId }) {
    await browser.windows.remove(windowId);

    return {
      status: 204,
    };
  },
};

Routes["/windows/#WINDOW_ID/tabs"] = {
  async get({ windowId }) {
    return {
      status: 200,
      body: await browser.tabs.query({ windowId }),
    };
  },
  async post(req) {
    let wid = await lib.normalizeWindowId(req.windowId);

    if (Array.isArray(req.body)) {
      return {
        status: 201,
        body: await Promise.all(
          req.body.map((b) => lib.makeTabWithWindowId(b, wid))
        ),
      };
    } else {
      return {
        status: 201,
        body: await lib.makeTabWithWindowId(req.body, wid),
      };
    }
  },
};

Routes["/windows/#WINDOW_ID/tab-urls"] = {
  async get({ windowId }) {
    return {
      status: 200,
      body: (await browser.tabs.query({ windowId })).map((t) => t.url),
    };
  },
  async post(req) {
    let wid = await lib.normalizeWindowId(req.windowId);

    await Promise.all(
      req.body.map((url) => {
        return browser.tabs.create({ windowId: wid, url: url });
      })
    );

    return {
      status: 200,
    };
  },
  async post(req) {
    let wid = await lib.normalizeWindowId(req.windowId);

    await Promise.all(
      req.body.map((url) => {
        return browser.tabs.create({ windowId: wid, url: url });
      })
    );

    return {
      status: 200,
    };
  },
};

//  _____     _
// |_   _|_ _| |__  ___
//   | |/ _` | '_ \/ __|
//   | | (_| | |_) \__ \
//   |_|\__,_|_.__/|___/
//

Routes["/tabs"] = {
  description: "Create a new window.",
  usage: 'echo "https://www.google.com" > $0',
  async post(req) {
    if (Array.isArray(req.body)) {
      return {
        status: 201,
        body: await Promise.all(req.body.map((b) => lib.makeTab(b))),
      };
    } else {
      return {
        status: 201,
        body: await lib.makeTab(req.body),
      };
    }
  },
  async patch(req) {
    const groupCache = {};
    const windowCache = {};

    if (Array.isArray(req.body)) {
      return {
        status: 200,
        body: await Promise.all(
          req.body.map((b) => lib.updateTab(b, groupCache, windowCache))
        ),
      };
    } else {
      return {
        status: 200,
        body: await lib.updateTab(req.body, groupCache, windowCache),
      };
    }
  },
  async get(req) {
    return {
      status: 200,
      body: await lib.tabsFromWindows(await browser.windows.getAll()),
    };
  },
};

Routes["/tabs/#TAB_ID"] = {
  async get({ tabId }) {
    return {
      status: 200,
      body: await browser.tabs.get(parseInt(tabId)),
    };
  },
  async delete({ tabId }) {
    await browser.tabs.remove(tabId);

    return {
      status: 204,
    };
  },
  async patch(req) {
    const groupCache = {};
    const windowCache = {};

    if (Array.isArray(req.body)) {
      return {
        status: 200,
        body: await Promise.all(
          req.body.map((b) => lib.updateTab(b, groupCache, windowCache))
        ),
      };
    } else {
      // req.body.id = req.tabId;
      let res = await browser.tabs.update(parseInt(req.tabId), req.body);

      return {
        status: 200,
        body: res,
      };
    }
  },
};

Routes["/tabs/#TAB_ID/open"] = {
  async post({ tabId }) {
    await lib.openTab(tabId);

    return {
      status: 204,
    };
  },
};

Routes["/extensions"] = {
  async get() {
    return {
      status: 200,
      body: await browser.management.getAll(),
    };
  },
};

Routes["/runtime/reload"] = {
  async get() {
    return {
      status: 200,
      body: await browser.runtime.getManifest(),
    };
  },
  async post() {
    await browser.runtime.reload();
    return { status: 204 };
  },
};

Routes["/tabs/last-focused"] = {
  description: `Represents the most recently focused tab.
It's a symbolic link to the folder /tabs/by-id/[ID of most recently focused tab].`,
  async readlink() {
    const id = (
      await browser.tabs.query({ active: true, lastFocusedWindow: true })
    )[0].id;
    return { buf: "by-id/" + id };
  },
};

//  ____              _                         _
// | __ )  ___   ___ | | ___ __ ___   __ _ _ __| | _____
// |  _ \ / _ \ / _ \| |/ / '_ ` _ \ / _` | '__| |/ / __|
// | |_) | (_) | (_) |   <| | | | | | (_| | |  |   <\__ \
// |____/ \___/ \___/|_|\_\_| |_| |_|\__,_|_|  |_|\_\___/
//

Routes["/bookmarks"] = {
  description: ``,
  async get() {
    return {
      status: 200,
      body: await browser.bookmarks.getTree(),
    };
  },
};

//  _   _ _     _
// | | | (_)___| |_ ___  _ __ _   _
// | |_| | / __| __/ _ \| '__| | | |
// |  _  | \__ \ || (_) | |  | |_| |
// |_| |_|_|___/\__\___/|_|   \__, |
//                            |___/

Routes["/history"] = {
  description: ``,
  async get() {
    return {
      status: 200,
      body: await browser.history.search({ text: "" }),
    };
  },
};

for (let key in Routes) {
  // /tabs/by-id/#TAB_ID/url.txt -> RegExp \/tabs\/by-id\/(?<int$TAB_ID>[0-9]+)\/url.txt
  Routes[key].__matchVarCount = 0;
  Routes[key].__regex = new RegExp(
    "^" +
    key
      .split("/")
      .map((keySegment) =>
        keySegment
          .replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
          .replace(/([#:])([A-Z_]+)/g, (_, sigil, varName) => {
            console.log(key, sigil, varName);
            Routes[key].__matchVarCount++;
            return (
              `(?<${sigil === "#" ? "int$" : "string$"}${varName}>` +
              (sigil === "#" ? "[^/]+" : "[^/]+") +
              `)`
            );
          })
      )
      .join("/") +
    "$"
  );

  Routes[key].__match = function(path) {
    const result = Routes[key].__regex.exec(path);
    if (!result) {
      return;
    }

    const vars = {};
    for (let [typeAndVarName, value] of Object.entries(result.groups || {})) {
      let [type_, varName] = typeAndVarName.split("$");
      // TAB_ID -> tabId
      varName = varName.toLowerCase();
      varName = varName.replace(/_([a-z])/g, (c) => c[1].toUpperCase());
      vars[varName] = value;
      // vars[varName] = type_ === "int" ? parseInt(value) : value;
    }
    return vars;
  };
}

// most specific (lowest matchVarCount) routes should match first
export const sortedRoutes = Object.values(Routes).sort(
  (a, b) => a.__matchVarCount - b.__matchVarCount
);
