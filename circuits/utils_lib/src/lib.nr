use dep::std;

fn field_first_four_bytes(input: Field) -> [u8; 4] {
    let bit_size: comptime Field = 32;
    let input_bits = std::to_bits(input, bit_size as u32); // Bit size must be 253 or less as this is restricted in Noir for safety

    let mut byte_array: [u8; 4] = [0; 4];
    for i in 0..4 {
        let index = i * 8;
        let mut byte: u8 = 0;
        for j in 0..8 {
            if index + j < bit_size {
                byte = (byte << 1) | (input_bits[index+(7-j)] as u8);
            }
        };
        //byte_array[4 - i - 1] = byte;
        byte_array[i] = byte;
    };
    byte_array
}

fn half_of_field_to_bytes(input: Field) -> [u8; 16] {
    let bit_size: comptime Field = 128;
    let input_bits = std::to_bits(input, bit_size as u32); // Bit size must be 253 or less as this is restricted in Noir for safety

    let mut byte_array: [u8; 16] = [0; 16];
    for i in 0..16 {
        let index = i * 8;
        let mut byte: u8 = 0;
        for j in 0..8 {
            byte = (byte << 1) | (input_bits[index+(7-j)] as u8);
        };
        byte_array[i] = byte;

    };
    byte_array
}

fn field_to_bytes(input: Field) -> [u8; 32] {
    let bit_size: comptime Field = 253;
    let input_bits = std::to_bits(input, bit_size as u32); // Bit size must be 253 or less as this is restricted in Noir for safety

    let mut byte_array: [u8; 32] = [0; 32];
    for i in 0..31 { // Change back to 32 once short circuit PR is merged
        let index = i * 8;
        let mut byte: u8 = 0;
        for j in 0..8 {
            if index + j < 253 {
                byte = (byte << 1) | (input_bits[index+(7-j)] as u8);
            }
        };
        byte_array[i] = byte;

    };
    byte_array
}