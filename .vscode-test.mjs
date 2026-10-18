import { defineConfig } from "@vscode/test-cli";

const shared = {
  workspaceFolder: "test/fixture",
  mocha: { timeout: 120000 },
};

export default defineConfig([
  { ...shared, label: "builtin", files: "test/builtin.test.js", launchArgs: ["--disable-extensions"] },
  {
    ...shared,
    label: "servers",
    files: "test/servers.test.js",
    installExtensions: ["ms-python.python", "ms-python.vscode-pylance", "rust-lang.rust-analyzer"],
  },
]);
