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
    const cnt = Math.floor(Math.random() * 10);
    console.log(`${cnt} node(signer)s approve this withdrawal request`);
    for (let j = 0; j < cnt; j++) {
      await runCommand(
        `dfx canister call ordinox_canister approve_request '("${
          signers[j]
        }","${i + 1}")'`
      );
    }
  }
};

main(5)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
