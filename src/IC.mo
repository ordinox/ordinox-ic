import Text "mo:base/Text";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";

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

  private var signatures = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
  let ic : IC = actor ("aaaaa-aa");

  public query func get_signature(req_id : Text) : async Text {
    let signature = signatures.get(req_id);
    let ret = switch signature {
      case null "";
      case (?text) text;
    };
    return ret;
  };

  public func reset_signature(req_id : Text) : async () {
    signatures.delete(req_id);
  };

  public func reset_signatures() : async () {
    signatures := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
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

  public shared (msg) func sign(req_id : Text, message : Text) : async SignResult {
    let caller = Principal.toBlob(msg.caller);
    try {
      let message_hash : Blob = Blob.fromArray(SHA256.sha256(Blob.toArray(Text.encodeUtf8(message))));
      ExperimentalCycles.add(25_000_000_000);
      let { signature } = await ic.sign_with_ecdsa({
        message_hash;
        derivation_path = [caller];
        key_id = { curve = #secp256k1; name = "dfx_test_key" };
      });
      let signature_hex = Hex.encode(Blob.toArray(signature));
      signatures.put(req_id, signature_hex);
      #Ok({ signature_hex });
    } catch (err) {
      #Err(Error.message(err));
    };
  };
};
