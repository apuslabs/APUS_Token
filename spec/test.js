import AoLoader from "@permaweb/ao-loader";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { load } from "../vendor/aos/src/commands/load.js";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const relative = (p) => path.resolve(__dirname, p);
const importLua = (p) => ".load " + relative(relative(p));

const wasmBinary = fs.readFileSync(relative("libs/sqlite.wasm"));
const processOptions = {
  format: "wasm64-unknown-emscripten-draft_2024_02_15",
  inputEncoding: "JSON-1",
  outputEncoding: "JSON-1",
  memoryLimit: "1073741824", // 1-gb
  computeLimit: (9e12).toString(),
  extensions: [],
};

function scanSpec() {
  const files = fs.readdirSync(__dirname);
  const luaFiles = files.filter((f) => f.endsWith("_spec.lua"));
  return luaFiles;
}

async function runTestfile(path) {
  const [line] = load(importLua(path));
  const handle = await AoLoader(wasmBinary, processOptions);
  const spawnResult = await handle(null, getMsg(line), getEnv());
  console.log(spawnResult.Output.data);
}

async function main() {
  const testFile = process.argv[2];
  if (!testFile) {
    const allSpecFileList = scanSpec();
    for (const file of allSpecFileList) {
      console.group(`Running ${file}`);
      await runTestfile(file);
      console.groupEnd();
    }
  } else {
    runTestfile(testFile);
  }
}
main();

function getMsg(Data, Action = "Eval") {
  return {
    Target: "1",
    From: "FOOBAR",
    Owner: "FOOBAR",
    Module: "FOO",
    Id: "1",
    "Block-Height": "1000",
    Timestamp: Date.now(),
    Tags: [{ name: "Action", value: Action }],
    Data,
  };
}

function getEnv() {
  return {
    Process: {
      Id: "1",
      Owner: "FOOBAR",
      Tags: [
        { name: "Name", value: "TEST_PROCESS_OWNER" },
        {
          name: "Authority",
          value: "fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY",
        },
      ],
    },
  };
}
