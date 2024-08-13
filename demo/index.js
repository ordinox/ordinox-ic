const util = require("util");
const { exec } = require("child_process");
const execAsync = util.promisify(exec);
const signers = require("./signers");

const runCommand = async (command) => {
  try {
    const { stdout, stderr } = await execAsync(command);
    if (stderr) console.error("Canister error:", stderr);
    else return stdout;
  } catch (err) {
    console.error(err.message);
  }
};

const extractValue = (str, key = undefined) => {
  str ||= "";
  if (key) {
    const keyIndex = str.indexOf(key);
    if (keyIndex >= 0) str = str.slice(keyIndex + key.length);
  }

  let quoteIndex = str.indexOf('"');
  if (quoteIndex >= 0) {
    str = str.slice(quoteIndex + 1);
    quoteIndex = str.indexOf('"');
    if (quoteIndex >= 0) str = str.slice(0, quoteIndex);
  }
  return str;
};

const signByECDSA = async (reqId, txInfo) => {
  let publicKey = await runCommand("dfx canister call ic_canister public_key");
  publicKey = extractValue(publicKey);

  let signature1 = await runCommand(
    `dfx canister call ic_canister sign '("${reqId}","${txInfo}")'`
  );
  signature1 = extractValue(signature1);

  let signature2 = await runCommand(
    `dfx canister call ic_canister get_signature ${reqId}`
  );
  signature2 = extractValue(signature2);
  if (signature1 === signature2) return signature1;
  return null;
};

const main = async (count) => {
  console.log(`register ${signers.length} signers to canister`);
  let signerStr = "";
  for (const signer of signers) {
    signerStr += `"${signer}";`;
  }
  await runCommand(
    `dfx canister call ordinox_canister register_signers '(vec {${signerStr}})'`
  );
  console.log("set threshold to canister");
  await runCommand("dfx canister call ordinox_canister set_threshold 5");
  console.log("reset requests approval state");
  await runCommand("dfx canister call ordinox_canister reset_requests");

  console.log(`demo ${count} number of withdrawals`);
  for (let i = 0; i < count; i++) {
    const reqId = i + 1;
    const cnt = Math.floor(Math.random() * 10);
    console.log(`${cnt} node(signer)s approve this withdrawal request`);
    for (let j = 0; j < cnt; j++) {
      let resp = await runCommand(
        `dfx canister call ordinox_canister approve_request '("${signers[j]}","${reqId}")'`
      );
      resp = extractValue(resp);
      if (resp.length > 0) {
        const signature = await signByECDSA(reqId, resp);
        console.log(`>> Signature for request ${reqId}: ${signature}`);
        break;
      }
    }
  }
};

main(5)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
