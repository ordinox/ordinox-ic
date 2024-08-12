import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";

actor {
  type ApproveResult = {
    #Ok : { tx_info : Text };
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
      return #Ok({ tx_info = await generate_transaction() });
    };
    return #Ok({ tx_info = "" });
  };

  func generate_transaction() : async Text {
    // TODO: create runes transfer transaction
    return "0200000001abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890000000006b483045022100f3b9a7b7b7c3b8a3b7b7c7d8f8e9a8b7b7b9c7b9b9b9c7b9b9c7b9b9b9b9b9b022100d8e7d8e7d8e7d8e7d8e7d8e7d8e7d8e7d8e7d8e7d8e7d8e7d8e7012103b9b7c7b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9bffffffff0280f0fa02000000001976a9141d0f172a0ecb48aee1be1f2687d2963ae33f71a188ac10270000000000001976a91489abcdefabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabba88ac00000000";
  };
};
