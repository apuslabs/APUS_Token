import AoLoader from "@permaweb/ao-loader";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { load } from "../vendor/aos/src/commands/load.js";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const relative = (p) => path.resolve(__dirname, p);
const importLua = (p) => ".load " + relative(relative(p));

const [line, modules] = load(importLua("entry.lua"));

const env = {
  Process: {
    Id: "2",
    Tags: [
      {
        name: "Authority",
        value: "fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY",
      },
    ],
  },
};

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

const wasmBinary = fs.readFileSync(relative("sqlite.wasm"));
const handle = await AoLoader(wasmBinary, {
  format: "wasm64-unknown-emscripten-draft_2024_02_15",
  inputEncoding: "JSON-1",
  outputEncoding: "JSON-1",
  memoryLimit: "1073741824", // 1-gb
  computeLimit: (9e12).toString(),
  extensions: [],
});

const spawnResult = await handle(null, getMsg(line), getEnv());

console.log(spawnResult.Output.data);
