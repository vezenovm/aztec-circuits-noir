use dep::std;

// TODO: move to separate constants file
global: DEFI_CLAIM: Field = 6;

fn main(
    proof_id: Field, 
    data_root: Field,
    defi_root: Field,
    claim_note_index: Field,
    claim_note_path: [Field; 32],
    defi_note_index: Field,
    claim_note_data: [Field; 6], // TODO: need separate structs for input
    defi_interaction_note_path: [Field; 32],

) {
    constrain proof_id == DEFI_CLAIM;

    // TODO: create ClaimNote struct. Separate methods for complete_partial_commitment and create_partial_commitment

    
}