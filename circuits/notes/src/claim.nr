use dep::std;
use crate::bridge_call_data::BridgeCallData;

struct PartialClaimNote {
  deposit_value: u126,
  bridge_call_data: Field,
  value_note_partial_commitment: Field,
  input_nullifier: Field,
  partial_commitment: Field,
}

impl PartialClaimNote {
  fn new(
    data: PartialClaimNoteWitnessData,
    owner: [Field; 2],
    owner_account_required: bool
  ) -> PartialClaimNote {
    let value_note_partial_commitment = std::hash::pedersen(
      [
        data.note_secret,
        owner[0],
        owner[1],
        owner_account_required as Field,
        0
      ]
    )[0];

    let partial_commitment = std::hash::pedersen(
      [
        data.deposit_value as Field,
        data.bridge_call_data_local.to_field(),
        value_note_partial_commitment,
        data.input_nullifier,
      ]
    )[0];

    PartialClaimNote {
      deposit_value: data.deposit_value,
      bridge_call_data: data.bridge_call_data_local.to_field(),
      value_note_partial_commitment: value_note_partial_commitment,
      input_nullifier: data.input_nullifier,
      partial_commitment: partial_commitment,
    }
  }
}

struct ClaimNote {
  deposit_value: u126,
  bridge_call_data: BridgeCallData, // TODO, change these to be Fields
  value_note_partial_commitment: Field,
  input_nullifier: Field,
  defi_interaction_nonce: Field,
  fee: Field,
  commitment: Field,
}

impl ClaimNote {
  fn new(data: ClaimNoteWitnessData) -> ClaimNote {
    let partial_commitment = std::hash::pedersen(
      [
        data.deposit_value as Field,
        data.bridge_call_data_local.to_field(),
        data.value_note_partial_commitment,
        data.input_nullifier,
      ]
    )[0];

    let commitment = std::hash::pedersen(
      [
        partial_commitment,
        data.defi_interaction_nonce,
        data.fee,
        // TODO: add GeneratorIndex constants file and use them in all of the commitments
      ]
    )[0];

    ClaimNote {
      deposit_value: data.deposit_value,
      bridge_call_data: data.bridge_call_data_local,
      value_note_partial_commitment: data.value_note_partial_commitment,
      input_nullifier: data.input_nullifier,
      defi_interaction_nonce: data.defi_interaction_nonce,
      fee: data.fee,
      commitment: commitment,
    }
  }
}

fn compute_nullifier(commitment: Field) -> Field {
  std::hash::pedersen([commitment, 9])[0] // TODO: add GeneratorIndex file
}

struct ClaimNoteWitnessData {
  deposit_value: u126,
  bridge_call_data_local: BridgeCallData,
  defi_interaction_nonce: Field,
  fee: Field,
  value_note_partial_commitment: Field,
  input_nullifier: Field,
}

struct PartialClaimNoteWitnessData {
  deposit_value: u126,
  bridge_call_data_local: BridgeCallData,
  note_secret: Field,
  input_nullifier: Field,
}