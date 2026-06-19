import { spawnSync } from "node:child_process";
import { platform } from "node:os";

const [, , scriptPath, ...scriptArgs] = process.argv;

if (!scriptPath) {
  console.error("Usage: node scripts/run-powershell.mjs <script.ps1> [args...]");
  process.exit(1);
}

const shell = platform() === "win32" ? "powershell.exe" : "pwsh";
const args =
  platform() === "win32"
    ? ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, ...scriptArgs]
    : ["-NoProfile", "-File", scriptPath, ...scriptArgs];

const result = spawnSync(shell, args, { stdio: "inherit" });

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);
