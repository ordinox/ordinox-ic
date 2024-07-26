const { exec } = require("child_process");
const signers = require("./signers");

const runCommand = (command) => {
  exec(command, (err, stdout, stderr) => {
    if (err || stderr) {
      if (err) {
        console.error(err.message);
      } else {
        console.error(`Canister error: ${stderr}`);
      }
    } else {
      console.log(stdout);
    }
  });
};

const main = (count) => {
  // console.log(`register ${signers.length} signers to canister`);
  // let signerStr = "";
  // for (const signer of signers) {
  //   signerStr += `"${signer}";`;
  // }
  // runCommand(
  //   `dfx canister call ordinox_tss_canister register_signers '(vec {${signerStr}})'`
  // );
  // console.log("set threshold to canister");
  // runCommand("dfx canister call ordinox_tss_canister set_threshold 5");

  console.log(`demo ${count} number of withdrawals`);
  for (let i = 0; i < count; i++) {
    const cnt = Math.floor(Math.random() * 10);
    console.log(`${cnt} node(signer)s approve this withdrawal request`);
    for (let j = 0; j < cnt; j++) {
      runCommand(
        `dfx canister call ordinox_tss_canister signer_approve '("${
          signers[j]
        }","${j + 1}")'`
      );
    }
  }
};

main(5);
