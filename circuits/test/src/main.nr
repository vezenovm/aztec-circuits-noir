use dep::notes;

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
    let j = Child2 { input_a: 0 as u30, input_b: 1 as u30, flag: true };
    let c = Child { child2: j, foo: a, bar: b };
    let p = Parent { foo: x, child: c, bar: y };

    constrain x == p.foo;

    let q = p.foo * y;

    let config = notes::bridge_call_data::bit_config { second_input_in_use: true, second_output_in_use: false };
    let b_call_data = notes::bridge_call_data::BridgeCallData { 
        bridge_address_id: 0 as u32,
        input_asset_id_a: 0 as u30,
        input_asset_id_b: 1 as u30,
        output_asset_id_a: 2 as u30,
        output_asset_id_b: 0 as u30,
        config: config,
        aux_data: 0 as u64,
    };

    let claim_note = notes::claim::ClaimNote::new(claim_note_data);
    let defi_interaction_note = notes::defi_interaction::Note::new(defi_interaction_note_data);
    // let claim_note = notes::claim::ClaimNote {
    //     deposit_value: 0,
    //     bridge_call_data: b_call_data,
    //     value_note_partial_commitment: 0,
    //     input_nullifier: 0,
    //     defi_interaction_nonce: 0,
    //     fee: 0,
    //     commitment: 0,
    // };
    let k = claim_note.value_note_partial_commitment * y;
}