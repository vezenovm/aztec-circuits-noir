use dep::std;

fn main(
  account_public_key: [Field; 2],
  new_account_public_key: [Field; 2],
  spending_public_key_1: [Field; 2],
  spending_public_key_2: [Field; 2],
  alias_hash: Field,
  create: u1,
  migrate: u1,
  signing_pub_key: [Field; 2],
  signature: [u8; 64]
) -> pub [Field; 5] {
    let proof_id = 4;

    // 3 modes
    // 1: create (create from scratch)
    // 2: update (add a spending_public_key to an existing account)
    // 3: migrate (change account_public_key linked to an alias_hash)

    // 1: create: create == 1 && migrate == 0
    // 2: update = create == 0 && migrate == 0
    // 3: migrate = create == 0 && migrate == 1

    let output_note_1_commitment = std::hash::pedersen([
        alias_hash, 
        new_account_public_key[0],
        new_account_public_key[1],
        spending_public_key_1[0],
        spending_public_key_1[1]
    ])[0];

    let output_note_2_commitment = std::hash::pedersen([
        alias_hash,
        new_account_public_key[0],
        new_account_public_key[1],
        spending_public_key_2[0],
        spending_public_key_2[1]
    ])[0];

    // @dev unlimited zero-valued nullifiers are permitted by the rollup circuit (e.g. if create == 0).
    let mut nullifier_1 = 0;
    if create == 1 {
        nullifier_1 = std::hash::pedersen([alias_hash])[0];
    }

    // If create or migrate, nullifier_2 = nullifier of the account_public_key being registered.
    let mut nullifier_2 = 0;
    if (create == 1) | (migrate == 1) {
        nullifier_2 = std::hash::pedersen([new_account_public_key[0], new_account_public_key[1]])[0];
    }

    // If creating an account from scratch, sign against the account private key, else sign with the spending key of the
    // input note
    let mut signer: [Field; 2] = [0 as Field; 2];
    if create == 1 {
        signer[0] = account_public_key[0];
        signer[1] = account_public_key[1];
    } else {
        signer[0] = signing_pub_key[0];
        signer[1] = signing_pub_key[1];
    }

    constrain new_account_public_key != spending_public_key_1;
    constrain new_account_public_key != spending_public_key_2;

    constrain (create & migrate) == 0;
    // Check signature.
    let message = std::hash::pedersen(
        [
            alias_hash,
            account_public_key[0],
            new_account_public_key[0],
            spending_public_key_1[0],
            spending_public_key_2[0],
            nullifier_1,
            nullifier_2
        ]
    )[0];
    constrain message != 0;
    //let m = 5;
    let q = [0 as u8; 32];
    // signer causing errors
    let sig_res = std::schnorr::verify_signature(signer[0], signer[1], signature, q);
    constrain sig_res == 1;

    [
        proof_id, 
        output_note_1_commitment, 
        output_note_2_commitment,
        nullifier_1,
        nullifier_2,
    ]
}

fn field_to_u8_array(input: Field) -> [u8; 32] {
    let input_bits = std::to_bits(input, 128 as u32);

    let mut byte_array: [u8; 32] = [0 as u8; 32];
    for i in 0..16 {
        let index = i * 8;
        let mut byte: u8 = 0;
        //for j in 0..8 {
            //if index + j < 128 {
              //  byte = (byte * 2) | (input_bits[index+j] as u8);
            //}
        //};
        byte_array[i] = input_bits[index] as u8;
        byte_array[i] = byte;

    };
    byte_array
}