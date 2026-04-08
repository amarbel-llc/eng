#!/usr/bin/env zx

// Returns nixpkgs commit SHAs and versions for a given package by searching
// the nixpkgs git history via the GitHub API.
//
// Usage:
//   nix-package-versions <package> [--limit=20]
//
// Examples:
//   nix-package-versions claude-code
//   nix-package-versions claude-code --limit=5

const pkg = argv._[0];

if (!pkg) {
  console.error("Usage: nix-package-versions <package> [--limit=20]");
  process.exit(1);
}

const limit = parseInt(argv.limit || "20", 10);
const prefix = pkg.slice(0, 2);
const pkgFile = `pkgs/by-name/${prefix}/${pkg}/package.nix`;

// Fetch commits that touched the package file
const commitsJson =
  await $`gh api ${"repos/NixOS/nixpkgs/commits?path=" + pkgFile + "&per_page=100"} --paginate --jq '.[].sha'`.quiet();

const shas = commitsJson.stdout.trim().split("\n").filter(Boolean);

if (shas.length === 0) {
  console.error(`No commits found touching ${pkgFile}`);
  process.exit(1);
}

// For each commit, fetch the file content and extract the version
const versions = [];

for (const sha of shas) {
  if (versions.length >= limit) break;

  const fileJson =
    await $`gh api repos/NixOS/nixpkgs/contents/${pkgFile}?ref=${sha} -q .content`.nothrow().quiet();

  if (fileJson.exitCode !== 0) continue;

  const content = Buffer.from(fileJson.stdout.trim(), "base64").toString("utf8");
  const m = content.match(/version\s*=\s*"([^"]+)"/);

  if (m) {
    const version = m[1];
    // Skip if we've already seen this version (only show first commit per version)
    if (!versions.some((v) => v.version === version)) {
      versions.push({ version, sha });
    }
  }
}

if (versions.length === 0) {
  console.error(`No version history found for '${pkg}'`);
  process.exit(1);
}

console.log("VERSION\tNIXPKGS_SHA");
for (const e of versions) {
  console.log(`${e.version}\t${e.sha}`);
}
