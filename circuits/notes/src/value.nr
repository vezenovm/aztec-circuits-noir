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
      data: WitnessData
  ) -> ValueNote {
    let partial_commitment = std::hash::pedersen(
      [
        data.secret,
        data.owner[0],
        data.owner[1],
        data.account_required as Field,
        data.creator_pubkey,
        1 // TODO: constants file for GeneratorIndex::VALUE_NOTE_PARTIAL_COMMITMENT
      ]
    )[0];

    let commitment = std::hash::pedersen(
      [
        partial_commitment,
        data.value,
        data.asset_id as Field,
        data.input_nullifier
      ]
    )[0];

    ValueNote {
      owner: data.owner,
      value: data.value,
      secret: data.secret,
      asset_id: data.asset_id,
      account_required: data.account_required as u1,
      input_nullifier: data.input_nullifier,
      commitment: commitment,
      creator_pubkey: data.creator_pubkey,
    }
  }
}

struct WitnessData {
  owner: [Field; 2],
  value: Field,
  secret: Field,
  asset_id: u30,
  account_required: bool,
  creator_pubkey: Field,
  input_nullifier: Field,
}