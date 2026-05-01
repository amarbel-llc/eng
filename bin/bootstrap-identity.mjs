#!/usr/bin/env zx

import { existsSync, writeFileSync } from "fs";
import { execSync } from "child_process";

// gum needs direct TTY access for its TUI; inherit stdin+stderr, pipe stdout
const gum = $({ stdio: ["inherit", "pipe", "inherit"] });

const isDarwin = os.platform() === "darwin";

const identityFile = isDarwin
  ? "/etc/nix-darwin/identity.json"
  : `${os.homedir()}/.config/identity.nix`;

if (existsSync(identityFile)) {
  try {
    await $({ stdio: "inherit" })`gum confirm ${`Overwrite existing ${identityFile}?`}`;
  } catch {
    await $({ stdio: "inherit" })`gum log --level info "aborted"`;
    process.exit(0);
  }
}

const gitName = (await gum`gum input --prompt 'Git user name: '`).stdout.trim();
const gitEmail = (await gum`gum input --prompt 'Git email: '`).stdout.trim();

// Capture both the PIV card's GUID and the signing-key pubkey directly
// from the card via `piggy tool`. Reading the pubkey from the card (not
// from the SSH agent) breaks the bootstrap → home-manager switch →
// agent-running → bootstrap-again circular dependency: the only
// precondition is that the card is inserted, same as for piggyGuid.
let signingKey = "";
let piggyGuid = "";

let listOut = "";
try {
  listOut = execSync("piggy tool list", { encoding: "utf-8" });
} catch {
  await $({ stdio: "inherit" })`gum log --level warn "'piggy tool list' failed; leaving piggyGuid and gitSigningKey empty (e.g. SSH host with no card)"`;
}

if (listOut) {
  const guids = listOut
    .split("\n")
    .map((l) => l.match(/^\s*guid:\s*(\S+)/))
    .filter(Boolean)
    .map((m) => m[1]);
  if (guids.length === 1) {
    piggyGuid = guids[0];
    await $({ stdio: "inherit" })`gum log --level info ${`captured PIV GUID: ${piggyGuid}`}`;
  } else if (guids.length > 1) {
    piggyGuid = (
      await gum`echo ${guids.join("\n")} | gum choose --header 'Select PIV card GUID:'`
    ).stdout.trim();
  } else {
    await $({ stdio: "inherit" })`gum log --level error "'piggy tool list' returned output but no GUID could be parsed; aborting"`;
    process.exit(1);
  }

  const slotIds = listOut
    .split("\n")
    .map((l) => l.match(/^\s+([0-9a-f]{2})\s+\S+\s+\S+\s+\S+/))
    .filter(Boolean)
    .map((m) => m[1]);

  if (slotIds.length === 0) {
    await $({ stdio: "inherit" })`gum log --level error "card present but 'piggy tool list' shows no populated slots; cannot capture signing key. Aborting."`;
    process.exit(1);
  }

  let chosenSlot;
  if (slotIds.length === 1) {
    chosenSlot = slotIds[0];
  } else {
    chosenSlot = (
      await gum`echo ${slotIds.join("\n")} | gum choose --header 'Select signing key slot:'`
    ).stdout.trim();
  }

  let pubkey;
  try {
    pubkey = execSync(`piggy tool pubkey ${chosenSlot}`, {
      encoding: "utf-8",
    }).trim();
  } catch (e) {
    await $({ stdio: "inherit" })`gum log --level error ${`'piggy tool pubkey ${chosenSlot}' failed: ${e.message}; aborting to avoid writing empty gitSigningKey`}`;
    process.exit(1);
  }
  const parts = pubkey.split(/\s+/);
  signingKey = `key::${parts[0]} ${parts[1]}`;
  await $({ stdio: "inherit" })`gum log --level info ${`captured signing key from slot ${chosenSlot}`}`;
}

if (isDarwin) {
  const hostname = execSync("scutil --get LocalHostName", {
    encoding: "utf-8",
  }).trim();

  const identity = JSON.stringify({
    username: process.env.USER,
    homeDirectory: os.homedir(),
    hostname,
    gitUserName: gitName,
    gitUserEmail: gitEmail,
    gitSigningKey: signingKey,
    piggyGuid,
  });

  await $`sudo mkdir -p ${path.dirname(identityFile)}`;
  await $`echo ${identity} | sudo tee ${identityFile} > /dev/null`;
} else {
  const dir = path.dirname(identityFile);
  await $`mkdir -p ${dir}`;

  const piggyGuidNix = piggyGuid ? `"${piggyGuid}"` : "null";
  const nixContent = `{
  gitUserName = "${gitName}";
  gitUserEmail = "${gitEmail}";
  gitSigningKey = "${signingKey}";
  piggyGuid = ${piggyGuidNix};
}
`;
  writeFileSync(identityFile, nixContent);
}

await $({ stdio: "inherit" })`gum log --level info ${`wrote ${identityFile}`}`;
await $({ stdio: "inherit" })`gum log --level warn "you must run 'just build-home' for these changes to take effect"`;
