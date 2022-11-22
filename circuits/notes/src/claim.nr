use dep::std;
use crate::bridge_call_data::BridgeCallData;

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
  bridge_call_data: BridgeCallData,
  value_note_partial_commitment: Field,
  input_nullifier: Field,
  defi_interaction_nonce: Field,
  fee: Field,
  commitment: Field,
}

impl ClaimNote {
  fn new(note: ClaimNoteWitnessData) -> ClaimNote {
    let partial_commitment = std::hash::pedersen(
      [
        note.deposit_value,
        note.bridge_call_data_local.to_field(),
        note.value_note_partial_commitment,
        note.input_nullifier,
      ]
    )[0];

    let commitment = std::hash::pedersen(
      [
        partial_commitment,
        note.defi_interaction_nonce,
        note.fee,
        // TODO: add GeneratorIndex constants file and use them in all of the commitments
      ]
    )[0];

    ClaimNote {
      deposit_value: note.deposit_value,
      bridge_call_data: note.bridge_call_data_local,
      value_note_partial_commitment: note.value_note_partial_commitment,
      input_nullifier: note.input_nullifier,
      defi_interaction_nonce: note.defi_interaction_nonce,
      fee: note.fee,
      commitment: commitment,
    }
  }
}

fn compute_nullifier(commitment: Field) -> Field {
  std::hash::pedersen([commitment, 9])[0] // TODO: add GeneratorIndex file
}

struct ClaimNoteWitnessData {
  deposit_value: Field,
  bridge_call_data_local: BridgeCallData,
  defi_interaction_nonce: Field,
  fee: Field,
  value_note_partial_commitment: Field,
  input_nullifier: Field,
}