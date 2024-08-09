import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";

import Hex "./utils/Hex";
import SHA256 "./utils/SHA256";

actor {
  // Only the ecdsa methods in the IC management canister is required here.
  type IC = actor {
    ecdsa_public_key : ({
      canister_id : ?Principal;
      derivation_path : [Blob];
      key_id : { curve : { #secp256k1 }; name : Text };
    }) -> async ({ public_key : Blob; chain_code : Blob });
    sign_with_ecdsa : ({
      message_hash : Blob;
      derivation_path : [Blob];
      key_id : { curve : { #secp256k1 }; name : Text };
    }) -> async ({ signature : Blob });
  };

  type SignResult = {
    #Ok : { signature_hex : Text };
    #Err : Text;
  };

  type ApproveResult = {
    #Ok : { signature_hex : Text };
    #Err : Text;
  };

  let ic : IC = actor ("aaaaa-aa");
  private stable var threshold : Nat = 0;
  private stable var signers : [Text] = [];
  private var requests = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);

  public func register_signers(new_signers : [Text]) : async Nat {
    for (signer in new_signers.vals()) {
      let exists = Array.find<Text>(signers, func x = x == signer);
      if (exists == null) {
        signers := Array.append(signers, [signer]);
      };
    };
    return signers.size();
  };

  public func reset_signers() : async () {
    signers := [];
  };

  public query func get_signers() : async [Text] {
    return signers;
  };

  public func set_threshold(new_threshold : Nat) : async () {
    threshold := new_threshold;
  };

  public query func get_threshold() : async Nat {
    return threshold;
  };

  public func reset_requests() : async () {
    requests := HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  };

  public func signer_approve(signer : Text, request_id : Text) : async ApproveResult {
    let exists = Array.find<Text>(signers, func x = x == signer);
    if (exists == null) {
      return #Err("Signer does not exist");
    };
    let request = requests.get(request_id);
    let num_approved = switch request {
      case null 0;
      case (?nat) nat;
    };
    requests.put(request_id, num_approved + 1);
    if (num_approved + 1 >= threshold) {
      let signResult = await sign(request_id);
      switch (signResult) {
        case (#Err(signError)) {
          return #Err(signError);
        };
        case (#Ok(signature)) {
          return #Ok({
            signature_hex = signature.signature_hex;
          });
        };
      };
    };
    return #Ok({ signature_hex = "" });
  };

  public shared (msg) func public_key() : async {
    #Ok : { public_key_hex : Text };
    #Err : Text;
  } {
    let caller = Principal.toBlob(msg.caller);
    try {
      let { public_key } = await ic.ecdsa_public_key({
        canister_id = null;
        derivation_path = [caller];
        key_id = { curve = #secp256k1; name = "dfx_test_key" };
      });
      #Ok({ public_key_hex = Hex.encode(Blob.toArray(public_key)) });
    } catch (err) {
      #Err(Error.message(err));
    };
  };

  public shared (msg) func sign(message : Text) : async SignResult {
    let caller = Principal.toBlob(msg.caller);
    try {
      let message_hash : Blob = Blob.fromArray(SHA256.sha256(Blob.toArray(Text.encodeUtf8(message))));
      Cycles.add(25_000_000_000);
      let { signature } = await ic.sign_with_ecdsa({
        message_hash;
        derivation_path = [caller];
        key_id = { curve = #secp256k1; name = "dfx_test_key" };
      });
      #Ok({ signature_hex = Hex.encode(Blob.toArray(signature)) });
    } catch (err) {
      #Err(Error.message(err));
    };
  };
};
