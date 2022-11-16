use dep::std;
use dep::utils;

fn main(
  data_tree_root: Field,
  account_public_key: [Field; 2],
  new_account_public_key: [Field; 2],
  spending_public_key_1: [Field; 2],
  spending_public_key_2: [Field; 2],
  alias_hash: Field,
  create: comptime u1,
  migrate: u1,
  account_note_index: Field,
  account_note_path: [Field; 32],
  signing_pub_key: [Field; 2],
  signature: [u8; 64]
) -> pub [Field; 15] {
    let proof_id = 4;

    // 3 modes
    // 1: create (create from scratch)
    // 2: update (add a spending_public_key to an existing account)
    // 3: migrate (change account_public_key linked to an alias_hash)

    // 1: create: create == 1 && migrate == 0
    // 2: update = create == 0 && migrate == 0
    // 3: migrate = create == 0 && migrate == 1

    let output_note_1_commitment = std::hash::pedersen([
        alias_hash, 
        new_account_public_key[0],
        new_account_public_key[1],
        spending_public_key_1[0],
        spending_public_key_1[1]
    ])[0];

    let output_note_2_commitment = std::hash::pedersen([
        alias_hash,
        new_account_public_key[0],
        new_account_public_key[1],
        spending_public_key_2[0],
        spending_public_key_2[1]
    ])[0];

    // @dev unlimited zero-valued nullifiers are permitted by the rollup circuit (e.g. if create == 0).
    let mut nullifier_1 = 0;
    if create == 1 {
        nullifier_1 = std::hash::pedersen([alias_hash])[0];
    }

    // If create or migrate, nullifier_2 = nullifier of the account_public_key being registered.
    let mut nullifier_2 = 0;
    if (create == 1) | (migrate == 1) {
        nullifier_2 = std::hash::pedersen([new_account_public_key[0], new_account_public_key[1]])[0];
    }

    // If creating an account from scratch, sign against the account private key, else sign with the spending key of the
    // input note
    let mut signer: [Field; 2] = [signing_pub_key[0], signing_pub_key[1]];
    if create == 1 {
        signer[0] = account_public_key[0];
        signer[1] = account_public_key[1];
    }

    constrain new_account_public_key != spending_public_key_1;
    constrain new_account_public_key != spending_public_key_2;

    constrain (create & migrate) == 0;
    // Check signature.
    let message = std::hash::pedersen(
        [
            alias_hash,
            account_public_key[0],
            new_account_public_key[0],
            spending_public_key_1[0],
            spending_public_key_2[0],
            nullifier_1,
            nullifier_2
        ]
    )[0];
    constrain message != 0;
    let message_byte_array = utils::field_to_bytes(message);
    let sig_res = std::schnorr::verify_signature(signer[0], signer[1], signature, message_byte_array);
    constrain sig_res == 1;

    // Check signing account note exists if create != 0.    
    let account_note_data_commitment = std::hash::pedersen([
        alias_hash,
        account_public_key[0],
        account_public_key[1],
        signer[0],
        signer[1]
    ])[0];
    //let computed_data_tree_root = std::merkle::compute_root_from_leaf(account_note_data_commitment, account_note_index, account_note_path);
    let is_member = std::merkle::check_membership(data_tree_root, account_note_data_commitment, account_note_index, account_note_path);
    if create == 0 {
        constrain is_member == 1;    
        //constrain computed_data_tree_root == data_tree_root;
    }

    // Check account public key does not change unless migrating.
    if account_public_key != new_account_public_key {
        constrain migrate == 1;
    }

    let public_value = 0;
    let public_owner = 0;
    let asset_id = 0;
    let tx_fee = 0;
    let tx_fee_asset_id = 0;
    let bridge_call_data = 0;
    let defi_deposit_value = 0;
    let defi_root = 0;
    let backward_link = 0;
    let allow_chain = 0;

    [
        proof_id, 
        output_note_1_commitment, 
        output_note_2_commitment,
        nullifier_1,
        nullifier_2,
        public_value,
        public_owner,
        asset_id,
        tx_fee,
        tx_fee_asset_id,
        bridge_call_data,
        defi_deposit_value,
        defi_root,
        backward_link,
        allow_chain
    ]
}