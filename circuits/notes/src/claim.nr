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

struct ClaimNote {
  deposit_value: Field,
  bridge_call_data: Field,
  value_note_partial_commitment: Field,
  input_nullifier: Field,
  defi_interaction_nonce: Field,
  fee: Field,
  commitment: Field,
}

impl ClaimNote {
  fn new(
    note: [Field; 6],
    owner: [Field; 2],
    owner_account_required: Field
  ) -> ClaimNote {
    let partial_commitment = std::hash::pedersen(
      [
        note[0],
        note[1],
        note[4], // value_note_partial_commitment
        note[5],
      ]
    )[0];

    let commitment = std::hash::pedersen(
      [
        partial_commitment,
        note[2],
        note[3],
        // TODO: add GeneratorIndex constants file and use them in all of the commitments
      ]
    )

    ClaimNote {
      deposit_value: note[0],
      bridge_call_data: note[1],
      value_note_partial_commitment: value_note_partial_commitment,
      input_nullifier: note[5],
      fee: note[3],
      commitment: commitment
    }
  }
}