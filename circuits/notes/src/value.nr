use dep::std;

struct ValueNote {
  owner: [Field; 2],
  value: Field,
  secret: Field,
  asset_id: u30,
  account_required: u1,
  input_nullifier: Field,
  commitment: Field,
  creator_pubkey: Field,
}

impl ValueNote {

  fn new(
      note: [Field; 9] // TODO: make a witness_data struct to avoid this gross array
  ) -> ValueNote {
    let partial_commitment = std::hash::pedersen(
      [
        note[3],
        note[0],
        note[1],
        note[5],
        note[8],
        1
      ]
    )[0];
    let commitment = std::hash::pedersen(
      [
        partial_commitment,
        note[2],
        note[4],
        note[6]
      ]
    )[0];
    ValueNote {
      owner: [note[0], note[1]],
      value: note[2],
      secret: note[3],
      asset_id: note[4] as u30,
      account_required: note[5] as u1,
      input_nullifier: note[6],
      commitment: commitment,
      creator_pubkey: note[8],
    }
  }

}