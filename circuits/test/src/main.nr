use dep::notes;
use dep::std;

struct Parent {
    foo: Field,
    child: Child,
    bar: Field,
}

struct Child {
    child2: Child2,
    foo: u32,
    bar: u32,
}

struct Child2 {
    input_a: u30,
    input_b: u30,
    flag: bool,
}


fn main(x : Field, y : pub Field, a: u32, b: u32, 
claim_note_data: notes::claim::ClaimNoteWitnessData,
defi_interaction_note_data: notes::defi_interaction::WitnessData,
) {
    let c2 = Child2 { input_a: 0 as u30, input_b: 1 as u30, flag: true };
    let c = Child { child2: c2, foo: a, bar: b };
    let p = Parent { foo: x, child: c, bar: y };

    let q = p.foo * y;
    constrain x == p.foo;

    // Failing
    let p2 = new_parent(c2, a, b);

    // Passing
    // let p2 = Parent { foo: a as Field, child: c, bar: b as Field };

    let q2 = p2.foo * y;

    // let config = notes::bridge_call_data::bit_config { second_input_in_use: true, second_output_in_use: false };
    // let b_call_data = notes::bridge_call_data::BridgeCallData { 
    //     bridge_address_id: 0 as u32,
    //     input_asset_id_a: 0 as u30,
    //     input_asset_id_b: 1 as u30,
    //     output_asset_id_a: 2 as u30,
    //     output_asset_id_b: 0 as u30,
    //     config: config,
    //     aux_data: 0 as u64,
    // };
    // let claim_note_data2 = notes::claim::ClaimNoteWitnessData {
    //     deposit_value: 0,
    //     bridge_call_data_local: b_call_data,
    //     defi_interaction_nonce: 0,
    //     fee: 0,
    //     value_note_partial_commitment: 0,
    //     input_nullifier: 1,       
    // };

    // Error when using this, either using the WitnessData struct from the ABI or the one created directly in Noir
    // let claim_note = notes::claim::ClaimNote::new(claim_note_data);
    // let claim_note = notes::claim::ClaimNote::new(claim_note_data2);
    // let claim_note = new(claim_note_data2);

    // No error when using this
    // let claim_note = notes::claim::ClaimNote {
    //   deposit_value: claim_note_data2.deposit_value,
    //   bridge_call_data: claim_note_data2.bridge_call_data_local,
    //   value_note_partial_commitment: claim_note_data2.value_note_partial_commitment,
    //   input_nullifier: claim_note_data2.input_nullifier,
    //   defi_interaction_nonce: claim_note_data2.defi_interaction_nonce,
    //   fee: claim_note_data2.fee,
    //   commitment: 1,
    // };
    // let k = claim_note.value_note_partial_commitment * y;

    // let defi_interaction_note = notes::defi_interaction::Note::new(defi_interaction_note_data);
}

fn new(note: notes::claim::ClaimNoteWitnessData) -> notes::claim::ClaimNote {
    // let partial_commitment = std::hash::pedersen(
    //   [
    //     note.deposit_value,
    //     note.bridge_call_data_local.to_field(),
    //     note.value_note_partial_commitment,
    //     note.input_nullifier,
    //   ]
    // )[0];

    // let commitment = std::hash::pedersen(
    //   [
    //     partial_commitment,
    //     note.defi_interaction_nonce,
    //     note.fee,
    //     // TODO: add GeneratorIndex constants file and use them in all of the commitments
    //   ]
    // )[0];

    notes::claim::ClaimNote {
      deposit_value: note.deposit_value,
      bridge_call_data: note.bridge_call_data_local,
      value_note_partial_commitment: note.value_note_partial_commitment,
      input_nullifier: note.input_nullifier,
      defi_interaction_nonce: note.defi_interaction_nonce,
      fee: note.fee,
      commitment: 1,
    }
  }

fn new_parent(c2: Child2, a: u32, b: u32) -> Parent {
    let c = Child { child2: c2, foo: a, bar: b };

    let p = Parent { foo: a as Field, child: c, bar: b as Field };

    p
}