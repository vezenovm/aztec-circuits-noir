use dep::std;

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
  input_note1: Field, // TODO: all the notes contain way more data and need to be expanded 
  input_note2: Field,
  output_note1: Field,
  output_note2: Field,
  // partial_claim_note: [Field; 4] maybe handle this one later
  signing_pub_key: [Field; 2],
  signature: [u8; 64],
  merkle_root: Field,
  input_path1: [Field; 32],
  input_path2: [Field; 32],
  account_note_index: Field,
  account_note_path: Field,
  account_private_key: Field,
  alias_hash: Field,
  account_required: u1,
  backward_link: Field,
  allow_chain: Field
) -> pub [Field; 2] {
  let is_deposit = proof_id == DEPOSIT;
  let is_withdraw = proof_id == WITHDRAW;
  let is_send = proof_id == SEND;
  let is_defi_deposit = proof_id == DEFI_DEPOSIT;
  let not_defi_deposit = !is_defi_deposit;
  let is_public_tx = is_deposit | is_withdraw;

  let mut public_asset_id = 1;
  if !is_public_tx {
    public_asset_id = 0;
  }
  // TODO: test whether this is less constraints
  // let public_asset_id = asset_id * is_public_tx;
  let public_input = public_value * is_deposit;
  let public_output = public_value * is_withdraw;

  

}
