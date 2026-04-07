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

let signingKey = "";

const sshSocket = process.env.SSH_AUTH_SOCK || "";
if (sshSocket) {
  try {
    const keys = execSync("ssh-add -L", {
      encoding: "utf-8",
    }).trim();

    const keyLines = keys.split("\n").filter((l) => l.length > 0);

    if (keyLines.length === 0) {
      await $({ stdio: "inherit" })`gum log --level warn "no keys found on SSH agent, skipping signing key"`;
    } else {
      let chosen;
      if (keyLines.length === 1) {
        chosen = keyLines[0];
      } else {
        chosen = (
          await gum`echo ${keyLines.join("\n")} | gum choose --header 'Select signing key from SSH agent:'`
        ).stdout.trim();
      }
      const parts = chosen.split(" ");
      signingKey = `key::${parts[0]} ${parts[1]}`;
    }
  } catch {
    await $({ stdio: "inherit" })`gum log --level warn "no keys found on SSH agent, skipping signing key"`;
  }
} else {
  await $({ stdio: "inherit" })`gum log --level warn "SSH_AUTH_SOCK not set, skipping signing key"`;
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
  });

  await $`sudo mkdir -p ${path.dirname(identityFile)}`;
  await $`echo ${identity} | sudo tee ${identityFile} > /dev/null`;
} else {
  const dir = path.dirname(identityFile);
  await $`mkdir -p ${dir}`;

  const nixContent = `{
  gitUserName = "${gitName}";
  gitUserEmail = "${gitEmail}";
  gitSigningKey = "${signingKey}";
}
`;
  writeFileSync(identityFile, nixContent);
}

await $({ stdio: "inherit" })`gum log --level info ${`wrote ${identityFile}`}`;
