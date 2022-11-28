use dep::std;
use dep::notes;

// TODO: move to separate constants file
global DEFI_CLAIM: Field = 6;

fn main(
    proof_id: Field, 
    data_root: Field,
    defi_root: Field,
    claim_note_index: Field,
    claim_note_path: [Field; 32],
    defi_note_index: Field,
    claim_note_data: notes::claim::ClaimNoteWitnessData, // TODO: need separate structs for input
    defi_interaction_note_path: [Field; 32],
    defi_interaction_note_data: notes::defi_interaction::WitnessData,
    output_value_a: Field,
    output_value_b: Field,
)  -> pub [Field; 16] {
    constrain proof_id == DEFI_CLAIM;

    let claim_note = notes::claim::ClaimNote::new(claim_note_data);

    let defi_interaction_note = notes::defi_interaction::Note::new(defi_interaction_note_data);

    // TODO: add methods for bridge_call_data
    // circuit::get_asset_id_flag(claim_note_data.bridge_call_data_local.output_asset_id_a);
    let first_output_virtual = true;
    let second_output_virtual = false;
    // TODO
    // // const bool_ct& second_input_in_use = claim_note_data.bridge_call_data_local.config.second_input_in_use;
    // // const bool_ct& second_output_in_use = claim_note_data.bridge_call_data_local.config.second_output_in_use;
    let second_input_in_use = claim_note_data.bridge_call_data_local.config.second_input_in_use;
    let second_output_in_use = claim_note_data.bridge_call_data_local.config.second_output_in_use;

    constrain claim_note.deposit_value != 0;

    // TODO: Fields cannot be compared need to change the inputs here
    constrain (claim_note.deposit_value < defi_interaction_note.total_input_value) | (claim_note.deposit_value == defi_interaction_note.total_input_value);
    constrain (defi_interaction_note.total_input_value - claim_note.deposit_value) >= 0;

    constrain (defi_interaction_note.total_output_value_a - output_value_a) >= 0;

    constrain (defi_interaction_note.total_output_value_b - output_value_b) >= 0;

    // Ratio checks.
    // Note, these ratio_checks also guarantee:
    //   defi_interaction_note.total_input_value != 0
    //   defi_interaction_note.total_output_value_a != 0 (unless output_value_a == 0)
    //   defi_interaction_note.total_output_value_b != 0 (unless output_value_b == 0)

    // NOTE: when I am using the note_data structs from the main inputs, I get the correct fields, 
    // but the objects I construct from the inputs such as `claim_note`
    // seem to have mismatches. Check whether it is simply an error of my code or actually an ABI error now.
    // NOTE: Error looks like it may be here: https://github.com/noir-lang/noir/blob/829c76c04195eb2b5a70c190a90dad9cdb6ecf82/crates/noirc_evaluator/src/ssa/code_gen.rs#L445
    // We simply are not generating nested structs correctly right now in the codegen
    // let a_ratio1 = claim_note.bridge_call_data.aux_data + defi_interaction_note_data.total_input_value as u64;
    // let a_ratio1 = claim_note.value_note_partial_commitment * defi_interaction_note_data.total_input_value;
    // let b_ratio1 = (output_value_a * defi_interaction_note.total_input_value);
    // constrain a_ratio1 == b_ratio1;
    constrain (claim_note.deposit_value / defi_interaction_note.total_input_value) == (output_value_a / defi_interaction_note.total_output_value_a);
    
    constrain (claim_note.deposit_value / defi_interaction_note.total_input_value) == (output_value_b / defi_interaction_note.total_output_value_b);

    let nullifier1 = notes::claim::compute_nullifier(claim_note.commitment);

    let nullifier2 = notes::defi_interaction::compute_nullifier(defi_interaction_note.commitment, claim_note.commitment);

    // Compute output notes.
    // const auto virtual_note_flag = suint_ct(uint256_t(1) << (MAX_NUM_ASSETS_BIT_LENGTH - 1));
    let virtual_note_flag = ((1 as u64) << 29) as Field;
    // let virtual_note_flag = 1;

    // If the defi interaction was unsuccessful, refund the original defi_deposit_value (which was denominated in
    // bridge input_asset_id_a) via output note 1.
    let interaction_success = defi_interaction_note.interaction_result;
    let mut output_value_1 = claim_note_data.deposit_value;
    if interaction_success {
        output_value_1 = output_value_a;
    }
    let mut output_asset_id_1_if_success = claim_note_data.bridge_call_data_local.output_asset_id_a as Field;
    if first_output_virtual {
        output_asset_id_1_if_success = virtual_note_flag + claim_note.defi_interaction_nonce;
    }
    let mut output_asset_id_1 = claim_note_data.bridge_call_data_local.input_asset_id_a as Field;
    if interaction_success {
        output_asset_id_1 = output_asset_id_1_if_success;
    }

    output_note_commitment1 = circuit::value::complete_partial_commitment(
        claim_note.value_note_partial_commitment, output_value_1, output_asset_id_1, nullifier1);
    let output_note_commitment1 = std::hash::pedersen(
        [
            claim_note.value_note_partial_commitment,
            output_value_1,
            output_asset_id_1,
            nullifier1, // TODO add a VALUE_NOTE_COMMITMENT generator index
        ]
    )[0];

    let mut output_value_2 = claim_note_data.deposit_value;
    if interaction_success {
        output_value_2 = output_value_b;
    }
    let mut output_asset_id_2_if_success = claim_note_data.bridge_call_data_local.output_asset_id_b as Field;
    if second_output_virtual {
        output_asset_id_2_if_success = virtual_note_flag + claim_note.defi_interaction_nonce;
    }
    let mut output_asset_id_2 = claim_note_data.bridge_call_data_local.input_asset_id_b as Field;
    if interaction_success {
        output_asset_id_2 = output_asset_id_2_if_success;
    }

    let mut output_note_commitment2 = std::hash::pedersen(
        [
            claim_note.value_note_partial_commitment,
            output_value_2,
            output_asset_id_2,
            nullifier2, // Reference TODO above for first output commitment
        ]
    )[0];

    // We zero the output_note_commitment2 in two cases:
    //   - if the bridge interaction succeeded and returned a second output asset; or
    //   - if the bridge interaction failed and no second asset was ever sent to the bridge.
    let is_bridge_output_b_in_use = interaction_success & second_output_in_use;
    let was_bridge_input_b_in_use = !interaction_success & second_input_in_use;

    let output_note_2_exists = is_bridge_output_b_in_use | was_bridge_input_b_in_use;

    output_note_commitment2 = output_note_commitment2 * (output_note_2_exists as Field);

    // TODO: check which is less constraints, converting to a field with bit shifts or checking each field individually
    constrain claim_note.bridge_call_data.to_field() == defi_interaction_note.bridge_call_data.to_field();
    constrain claim_note.defi_interaction_nonce == defi_interaction_note.interaction_nonce;

    let claim_exists = std::merkle::check_membership(
        data_root,
        claim_note.commitment,
        claim_note_index,
        claim_note_path,
    );
    constrain claim_exists == 1;

    let din_exists = std::merkle::check_membership(
        data_root,
        defi_interaction_note.commitment,
        defi_note_index,
        defi_interaction_note_path,
    );
    constrain din_exists == 1;


    let public_value = 0;
    let public_owner = 0;
    let asset_id = 0;
    let defi_deposit_value = 0;
    let backward_link = 0;
    let allow_chain = 0;

    [
        proof_id,
        output_note_commitment1,
        output_note_commitment2,
        nullifier1,
        nullifier2,
        public_value,
        public_owner,
        asset_id,
        data_root,
        claim_note.fee,
        claim_note_data.bridge_call_data_local.input_asset_id_a as Field,
        claim_note.bridge_call_data.to_field(),
        defi_deposit_value,
        defi_root,
        backward_link,
        allow_chain
    ]

    // [0; 16]
}