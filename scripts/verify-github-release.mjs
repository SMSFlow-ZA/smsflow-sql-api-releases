const version = process.argv[2] ?? "0.3.0";
const repository = process.argv[3] ?? "SMSFlow-ZA/smsflow-sql-api-releases";
const tagName = `v${version}`;

const requiredAssets = [
  `smsflow-sql-api-${version}-windows-host.zip`,
  `smsflow-sql-api-${version}-windows-manager.zip`,
  `smsflow-sql-api-${version}-linux-host.zip`,
  `smsflow-sql-api-${version}-docker-host.zip`,
  "CHECKSUMS-SHA256.txt",
];

const minimumSizes = new Map([
  [`smsflow-sql-api-${version}-windows-host.zip`, 100_000_000],
  [`smsflow-sql-api-${version}-windows-manager.zip`, 25_000_000],
  [`smsflow-sql-api-${version}-linux-host.zip`, 75_000_000],
  [`smsflow-sql-api-${version}-docker-host.zip`, 5_000_000],
  ["CHECKSUMS-SHA256.txt", 100],
]);

function fail(message) {
  console.error(message);
  process.exit(1);
}

const releaseUrl = `https://api.github.com/repos/${repository}/releases/tags/${tagName}`;
const response = await fetch(releaseUrl, {
  headers: {
    "Accept": "application/vnd.github+json",
    "User-Agent": "smsflow-release-verifier",
  },
});

if (!response.ok) {
  fail(`GitHub release ${repository}@${tagName} could not be read: ${response.status} ${response.statusText}`);
}

const release = await response.json();
if (release.draft) {
  fail(`GitHub release ${tagName} is still a draft.`);
}

if (release.prerelease) {
  fail(`GitHub release ${tagName} is marked as a prerelease.`);
}

const assets = new Map((release.assets ?? []).map((asset) => [asset.name, asset]));
for (const assetName of requiredAssets) {
  const asset = assets.get(assetName);
  if (!asset) {
    fail(`Missing GitHub release asset: ${assetName}`);
  }

  const minimumSize = minimumSizes.get(assetName) ?? 1;
  if (asset.size < minimumSize) {
    fail(`GitHub release asset ${assetName} is unexpectedly small: ${asset.size} bytes`);
  }

  if (asset.state !== "uploaded") {
    fail(`GitHub release asset ${assetName} is not fully uploaded. State: ${asset.state}`);
  }
}

console.log(`GitHub release ${repository}@${tagName} passed metadata verification.`);
for (const assetName of requiredAssets) {
  const asset = assets.get(assetName);
  console.log(`- ${asset.name}: ${asset.size} bytes`);
}
