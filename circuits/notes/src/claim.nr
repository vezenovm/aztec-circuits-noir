use dep::std;

struct PartialClaimNote {
  deposit_value: Field,
  bridge_call_data: Field,
  value_note_partial_commitment: Field,
  input_nullifier: Field,
  partial_commitment: Field,
}

impl PartialClaimNote {
  fn new(
    note: [Field; 4],
    owner: [Field; 2],
    owner_account_required: Field
  ) -> PartialClaimNote {
    let value_note_partial_commitment = std::hash::pedersen(
      [
        note[2],
        owner[0],
        owner[1],
        owner_account_required
      ]
    )[0];

    let partial_commitment = std::hash::pedersen(
      [
        note[0],
        note[1],
        value_note_partial_commitment,
        note[3]
      ]
    )[0];

    PartialClaimNote {
      deposit_value: note[0],
      bridge_call_data: note[1],
      value_note_partial_commitment: value_note_partial_commitment,
      input_nullifier: note[3],
      partial_commitment: partial_commitment
    }
  }
}