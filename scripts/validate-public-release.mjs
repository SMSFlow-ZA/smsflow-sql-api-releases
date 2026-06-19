import { createHash } from "node:crypto";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { dirname, extname, join, normalize, relative } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = dirname(dirname(fileURLToPath(import.meta.url)));
const releaseVersion = "0.3.0";
const releasePath = join(rootDir, "releases", releaseVersion, "README.md");
const schemaPath = join(rootDir, "examples", "sql", "sql_integration.sql");
const readmePath = join(rootDir, "README.md");
const checksumPath = join(rootDir, "releases", releaseVersion, "CHECKSUMS-SHA256.txt");

const requiredFiles = [
  ".github/workflows/ci.yml",
  "README.md",
  "LICENSE",
  "package.json",
  "docs/install-windows.md",
  "docs/install-linux.md",
  "docs/install-docker.md",
  "docs/first-install-checklist.md",
  "docs/client-implementation-guide.md",
  "docs/client-setup-guide.md",
  "docs/operator-guide.md",
  "examples/sql/sql_integration.sql",
  "examples/sql/send-one-message.sql",
  "examples/sql/send-bulk-messages.sql",
  "examples/sql/check-message-status.sql",
  "examples/sql/read-replies.sql",
  "examples/sql/health-dashboard.sql",
  "examples/sql/troubleshooting.sql",
  "deploy/demo/try-it-in-10-minutes/README.md",
  "deploy/demo/try-it-in-10-minutes/docker-compose.yml",
  "deploy/demo/try-it-in-10-minutes/config/worker/appsettings.json",
  "deploy/demo/try-it-in-10-minutes/sql/02-seed-sample-messages.sql",
  "deploy/demo/try-it-in-10-minutes/sql/03-validation-queries.sql",
  "deploy/demo/try-it-in-10-minutes/sql/04-assert-demo-processed.sql",
  "releases/0.3.0/README.md",
  "scripts/run-powershell.mjs",
  "scripts/verify-github-release.mjs",
  "scripts/smoke-test-release-assets.ps1",
  "scripts/smoke-test-demo.ps1",
];

const forbiddenTerms = [
  "Azure DevOps",
  "Palesa",
  "codex",
  "private source",
  "internal repo",
  "not open source",
];

function walk(dir, files = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if ([".git", "artifacts", "dist", "tmp"].includes(entry.name)) {
      continue;
    }

    if (entry.isDirectory()) {
      walk(path, files);
    } else if ([".md", ".sql", ".yml", ".yaml", ".json", ".bicep"].includes(extname(entry.name).toLowerCase())) {
      files.push(path);
    }
  }

  return files;
}

function fail(message) {
  failures.push(message);
}

const failures = [];

for (const file of requiredFiles) {
  if (!existsSync(join(rootDir, file))) {
    fail(`Missing required public file: ${file}`);
  }
}

const readme = readFileSync(readmePath, "utf8");
if (!readme.includes(`Current release: \`${releaseVersion}\``)) {
  fail(`README.md does not advertise the current ${releaseVersion} release.`);
}

if (!readme.includes("https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases")) {
  fail("README.md must link customers to GitHub Releases.");
}

if (!readme.includes("CHECKSUMS-SHA256.txt")) {
  fail("README.md must tell customers to verify downloads with CHECKSUMS-SHA256.txt.");
}

if (!readme.includes("deploy/demo/try-it-in-10-minutes/README.md")) {
  fail("README.md must link to the 10-minute SQL API demo.");
}

const releaseNotes = readFileSync(releasePath, "utf8");
for (const asset of [
  "smsflow-sql-api-0.3.0-windows-host.zip",
  "smsflow-sql-api-0.3.0-linux-host.zip",
  "smsflow-sql-api-0.3.0-docker-host.zip",
]) {
  if (!releaseNotes.includes(asset)) {
    fail(`Release notes do not mention ${asset}`);
  }
}

const schema = readFileSync(schemaPath, "utf8");
if (!schema.includes("N'0.2.0'") || !schema.includes("[sms_flow].[SchemaVersion_Get]")) {
  fail("Public SQL schema must expose schema version 0.2.0 and SchemaVersion_Get.");
}

const checksumLines = releaseNotes
  .split(/\r?\n/)
  .map((line) => line.trim())
  .filter((line) => new RegExp(`^[a-f0-9]{64}\\s+smsflow-sql-api-${releaseVersion.replaceAll(".", "\\.")}-.+\\.zip$`, "i").test(line));

if (checksumLines.length < 4) {
  fail("Release notes must include SHA-256 checksums for the published ZIP assets.");
}

if (existsSync(checksumPath)) {
  fail("Do not commit generated CHECKSUMS-SHA256.txt into the public docs repo; publish it as a GitHub release asset.");
}

const relativeLinkPattern = /\[[^\]]+\]\((?!https?:\/\/|mailto:|#)([^)#]+)(?:#[^)]+)?\)/g;
for (const file of walk(rootDir)) {
  const text = readFileSync(file, "utf8");
  const relPath = relative(rootDir, file).replaceAll("\\", "/");
  const lowerText = text.toLowerCase();

  for (const term of forbiddenTerms) {
    if (lowerText.includes(term.toLowerCase())) {
      fail(`${relPath} contains public-release forbidden term: ${term}`);
    }
  }

  if (extname(file).toLowerCase() !== ".md") {
    continue;
  }

  for (const match of text.matchAll(relativeLinkPattern)) {
    const target = decodeURIComponent(match[1].trim());
    if (!target || target.startsWith("<") || target.startsWith("/")) {
      continue;
    }

    const resolved = normalize(join(dirname(file), target));
    if (!resolved.startsWith(rootDir) || !existsSync(resolved)) {
      fail(`${relPath} has broken relative link: ${target}`);
    }
  }
}

if (failures.length > 0) {
  console.error("Public release validation failed:");
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log("Public release validation passed.");
