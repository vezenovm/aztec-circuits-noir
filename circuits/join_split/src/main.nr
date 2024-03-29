use dep::std;
use dep::utils;
use dep::notes;

// TODO: move these constants to their own constants file
global DEPOSIT: Field = 1;
global WITHDRAW: Field = 2;
global SEND: Field = 3;
global DEFI_DEPOSIT: Field = 5;

fn main(
  proof_id: Field,
  public_value: Field,
  public_owner: Field,
  asset_id: u30,
  num_input_notes: Field,
  input_note1_index: Field,
  input_note2_index: Field,
  input_note1: notes::value::WitnessData, 
  input_note2: notes::value::WitnessData,
  output_note1: notes::value::WitnessData,
  output_note2: notes::value::WitnessData,
  partial_claim_note_data: notes::claim::PartialClaimNoteWitnessData, 
  signing_pub_key: [Field; 2],
  signature: [u8; 64],
  merkle_root: Field,
  input_path1: [Field; 32],
  input_path2: [Field; 32],
  account_note_index: Field,
  account_note_path: [Field; 32],
  account_private_key: Field,
  alias_hash: Field,
  account_required: u1,
  backward_link: Field,
  allow_chain: Field
) -> pub [Field; 8] {
  let is_deposit = proof_id == DEPOSIT;
  let is_withdraw = proof_id == WITHDRAW;
  let is_send = proof_id == SEND;
  let is_defi_deposit = proof_id == DEFI_DEPOSIT;
  let not_defi_deposit = !is_defi_deposit;
  let is_public_tx = is_deposit | is_withdraw;

  let mut public_asset_id = 0;
  if is_public_tx {
    public_asset_id = 1;
  }
  // TODO: test whether this is less constraints
  //let public_asset_id = asset_id * is_public_tx;
  let public_input = public_value * (is_deposit as Field);
  let public_output = public_value * (is_withdraw as Field);

  let input_note_1 = notes::value::ValueNote::new(input_note1);
  let input_note_2 = notes::value::ValueNote::new(input_note2);
  let output_note_1 = notes::value::ValueNote::new(output_note1);
  let output_note_2 = notes::value::ValueNote::new(output_note2);

  let partial_claim_note = notes::claim::PartialClaimNote::new(partial_claim_note_data, input_note_1.owner, input_note1.account_required);
  
  let mut output_note_1_commitment = output_note_1.commitment;
  if is_defi_deposit {
    output_note_1_commitment = partial_claim_note.partial_commitment;
  }

  let mut defi_deposit_value = 0;
  let mut bridge_call_data = 0;
  if is_defi_deposit {
    defi_deposit_value = partial_claim_note.deposit_value as Field;
    bridge_call_data = partial_claim_note.bridge_call_data;
  }

  let no_input_notes = num_input_notes == 0;
  let one_input_note = num_input_notes == 1;
  let two_input_notes = num_input_notes == 2;
  constrain no_input_notes | one_input_note | two_input_notes;

  let input_note_1_in_use = one_input_note | two_input_notes;
  let input_note_2_in_use = two_input_notes;

  let equal_input_asset_ids = input_note_1.asset_id == input_note_2.asset_id;
  let different_input_asset_ids = !equal_input_asset_ids;

  let input_note_1_value = input_note_1.value;
  let mut input_note_2_value = input_note_2.value;
  let mut output_note_1_value = 0;
  if not_defi_deposit {
    output_note_1_value = output_note_2.value;
  }
  let output_note_2_value = output_note_2.value;

  constrain is_public_tx == (public_value == 0);
  constrain is_public_tx == (public_owner == 0);

  constrain is_deposit | is_withdraw | is_send | is_defi_deposit;

  constrain input_note_1.commitment != input_note_2.commitment;

  constrain !no_input_notes | is_deposit;

  constrain (asset_id == input_note_1.asset_id) & 
  (asset_id == output_note_1.asset_id) & 
  (asset_id == output_note_2.asset_id);

  constrain !(input_note_2_in_use & (is_deposit | is_send | is_withdraw)) | equal_input_asset_ids;

  constrain !(is_defi_deposit & input_note_2_in_use & different_input_asset_ids) | 
  (defi_deposit_value == input_note_2.value);

  // TODO TODO: add bridge_call_data indexing to fetch and constrain call data such as assets ids

  // Transaction chaining
  let note1_propagated = backward_link == input_note_1.commitment;
  let note2_propagated = backward_link == input_note_2.commitment;

  let backward_link_in_use = backward_link != 0;
  constrain !backward_link_in_use | (note1_propagated | note2_propagated);

  let allow_chain_1_and_2 = allow_chain == 3;
  let allow_chain_1 = (allow_chain == 1) | allow_chain_1_and_2;
  let allow_chain_2 = (allow_chain == 2) | allow_chain_1_and_2;

  constrain (allow_chain == 0) | allow_chain_1 | allow_chain_2;

  let user_self = input_note_1.owner;
  constrain !allow_chain_1 | (output_note_1.owner == user_self);
  constrain !allow_chain_2 | (output_note_2.owner == user_self);

  constrain !is_defi_deposit | !allow_chain_1;

  input_note_2_value = input_note_2_value * (!(is_defi_deposit & input_note_2_in_use & different_input_asset_ids)) as Field;

  // Derive tx fee
  let total_in_value = public_input + input_note_1_value + input_note_2_value;
  let total_out_value = public_output + output_note_1_value + output_note_2_value + defi_deposit_value;

  // TODO: need to disallows underflow and implicitly check that input_note_1_value >= input_note_2_value
  // barretenberg code uses safe_uint for these which is constraining the bits while I am using a Field
  let tx_fee = total_in_value - total_out_value;

  // Verify input notes have the same account public key and account_required.
  constrain input_note_1.owner == input_note_2.owner;
  constrain input_note_1.account_required == input_note_2.account_required;

  constrain account_private_key != 0;
  let account_public_key = std::scalar_mul::fixed_base(account_private_key);
  constrain account_public_key == input_note_1.owner;
  constrain account_required == input_note_1.account_required;

  constrain (output_note_1.creator_pubkey == 0) | (output_note_1.creator_pubkey == account_public_key[0]);
  constrain (output_note_2.creator_pubkey == 0) | (output_note_2.creator_pubkey == account_public_key[0]);

  let mut signer: [Field; 2] = account_public_key;
  if account_required == 1 {
    signer = signing_pub_key;
  }

  let account_note_data = notes::account::AccountNote::new(alias_hash, account_public_key, signer);
  let signing_key_exists = std::merkle::check_membership(
    merkle_root, 
    account_note_data.commitment,
    account_note_index,
    account_note_path);
  constrain (signing_key_exists == 1) | !(account_required as bool);

  let nullifier1 = process_input_note(account_private_key, 
    merkle_root,
    input_path1,
    input_note1_index,
    input_note_1,
    note1_propagated,
    input_note_1_in_use,
  );

  let nullifier2 = process_input_note(account_private_key, 
    merkle_root,
    input_path2,
    input_note2_index,
    input_note_2,
    note2_propagated,
    input_note_2_in_use
  );

  constrain output_note_1.input_nullifier == nullifier1;
  constrain output_note_2.input_nullifier == nullifier2;
  constrain partial_claim_note.input_nullifier == (nullifier1 * (is_defi_deposit as Field));

  let message = std::hash::pedersen(
    [
      public_value,
      public_owner,
      public_asset_id,
      output_note_1_commitment,
      output_note_2.commitment,
      nullifier1,
      nullifier2,
      backward_link,
      allow_chain
    ]
  )[0];

  let message_byte_array = std::to_bytes(message, 31);
  let sig_res = std::schnorr::verify_signature(signer[0], signer[1], signature, message_byte_array);
  constrain sig_res == 1;

  [
    nullifier1,
    nullifier2,
    output_note_1_commitment,
    output_note_2.commitment,
    public_asset_id,
    tx_fee,
    bridge_call_data,
    defi_deposit_value
  ]
}

fn process_input_note(
  account_private_key: Field,
  merkle_root: Field,
  hash_path: [Field; 32],
  index: Field,
  note: notes::value::ValueNote,
  is_propagated: bool,
  is_note_in_use: bool,
) -> Field {
  // Fixed in PR #485
  constrain (note.value == 0) | is_note_in_use;

  let exists = std::merkle::check_membership(merkle_root, note.commitment, index, hash_path) as bool;
  
  constrain exists | is_propagated | !is_note_in_use;

  compute_nullifier(note.commitment, account_private_key, is_note_in_use)
}

fn compute_nullifier(
  note_commitment: Field,
  account_private_key: Field,
  is_note_in_use: bool
) -> Field {
  // TODO: check whether we support fixed_base scalar mul with a specified generator index instead of just one element of g1
  let hashed_private_key = std::scalar_mul::fixed_base(account_private_key);

  let compressed_inputs = std::hash::pedersen(
    [
      note_commitment, 
      hashed_private_key[0], 
      hashed_private_key[1], 
      is_note_in_use as Field
    ]
  )[0];

  let blake_result = std::hash::hash_to_field([compressed_inputs]);
  blake_result
}
