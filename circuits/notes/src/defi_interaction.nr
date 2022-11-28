use dep::std;
use crate::bridge_call_data;

struct Note {
  bridge_call_data: bridge_call_data::BridgeCallData,
  interaction_nonce: Field,
  total_input_value: Field,
  total_output_value_a: Field,
  total_output_value_b: Field,
  interaction_result: u1,
  commitment: Field,
}

impl Note {
  fn new(
    data: WitnessData
  ) -> Note {
    let commitment = std::hash::pedersen(
      [
        data.bridge_call_data_local.to_field(),
        data.total_input_value,
        data.total_output_value_a,
        data.total_output_value_b,
        data.interaction_nonce,
        data.interaction_result as Field,
      ]
    )[0];

    Note {
      bridge_call_data: data.bridge_call_data_local,
      interaction_nonce: data.interaction_nonce,
      total_input_value: data.total_input_value,
      total_output_value_a: data.total_output_value_a,
      total_output_value_b: data.total_output_value_b,
      interaction_result: data.interaction_result,
      commitment: commitment,
    }
  }
}

fn compute_nullifier(
  defi_interaction_note_commitment: Field,
  nonce: Field,
) -> Field {
  std::hash::pedersen([defi_interaction_note_commitment, nonce, 11])[0] // TODO: add GeneratorIndex file
}

struct WitnessData {
    bridge_call_data_local: bridge_call_data::BridgeCallData,
    interaction_nonce: Field,
    total_input_value: Field,
    total_output_value_a: Field,
    total_output_value_b: Field,
    interaction_result: u1,
}