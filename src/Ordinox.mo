import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";

import BitcoinApi "./bitcoin/BitcoinApi";
import Constants "./utils/Constants";

actor {
  type ApproveResult = {
    #Ok : {};
    #Err : Text;
  };

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

  public func approve_request(signer : Text, request_id : Text) : async ApproveResult {
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
      await generate_transaction();
    };
    return #Ok({ signature_hex = "" });
  };

  func generate_transaction() : async () {
    // TODO: generate tx
    await BitcoinApi.send_transaction(Constants.NETWORK, []);
  };
};
