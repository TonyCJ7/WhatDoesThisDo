import fs from "node:fs";
import path from "node:path";
import { defineConfig } from "@vscode/test-cli";

const launchFixture = "test/fixture/launch";
const launchPage = "test/fixture/docs/whatdoesthisdo/references/launch/stale.md";
const anHourAgo = new Date(Date.now() - 3600 * 1000);

fs.mkdirSync(launchFixture, { recursive: true });
fs.mkdirSync(path.dirname(launchPage), { recursive: true });
fs.writeFileSync(launchPage, "### [stale_launch()](../../../../launch/stale.py#L1)\n\nWritten before the editor started; the source is newer.\n");
fs.utimesSync(launchPage, anHourAgo, anHourAgo);
fs.writeFileSync(path.join(launchFixture, "stale.py"), "print(stale_launch())\n\n\ndef stale_launch():\n    return 1\n");

const shared = {
  workspaceFolder: "test/fixture",
  mocha: { timeout: 120000 },
};

export default defineConfig([
  { ...shared, label: "builtin", files: ["test/builtin.test.js", "test/lines.test.js"], launchArgs: ["--disable-extensions"] },
  {
    ...shared,
    label: "servers",
    files: "test/servers.test.js",
    installExtensions: ["ms-python.python", "ms-python.vscode-pylance", "rust-lang.rust-analyzer"],
  },
]);
