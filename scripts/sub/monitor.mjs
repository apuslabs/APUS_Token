import { readFileSync } from "node:fs";
import { createDataItemSigner, monitor } from "@permaweb/aoconnect";
import path from 'path'
import os from 'os'

export default async function monitorProcess(argv) {

  const wallet = JSON.parse(
    readFileSync(path.resolve(process.env.OWNER_JSON_LOCATION || `${os.homedir()}/.aos.json`)).toString(),
  );

  const result = await monitor({
    process: argv.process,
    signer: createDataItemSigner(wallet),
  });

  console.log(result)
}