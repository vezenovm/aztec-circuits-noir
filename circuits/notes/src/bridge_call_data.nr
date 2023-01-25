use dep::std;
use crate::constants;

// constexpr uint32_t input_asset_id_a_shift = DEFI_BRIDGE_ADDRESS_ID_LEN;
// constexpr uint32_t input_asset_id_b_shift = input_asset_id_a_shift + DEFI_BRIDGE_INPUT_A_ASSET_ID_LEN;
// constexpr uint32_t output_asset_id_a_shift = input_asset_id_b_shift + DEFI_BRIDGE_INPUT_B_ASSET_ID_LEN;
// constexpr uint32_t output_asset_id_b_shift = output_asset_id_a_shift + DEFI_BRIDGE_OUTPUT_A_ASSET_ID_LEN;
// constexpr uint32_t bitconfig_shift = output_asset_id_b_shift + DEFI_BRIDGE_OUTPUT_B_ASSET_ID_LEN;
// constexpr uint32_t aux_data_shift = bitconfig_shift + DEFI_BRIDGE_BITCONFIG_LEN;

// TODO: add const expressions to globals
global input_asset_id_a_shift = 32;
global input_asset_id_b_shift = 62;
global output_asset_id_a_shift = 92;
global output_asset_id_b_shift = 122;
global bitconfig_shift = 152;
global aux_data_shift = 184;

struct BridgeCallData {
    bridge_address_id: u32,
    input_asset_id_a: u30,
    input_asset_id_b: u30,
    output_asset_id_a: u30,
    output_asset_id_b: u30,
    config: bit_config,
    aux_data: u64,
}

impl BridgeCallData {
    fn validate_bit_config(self: Self) {
        constrain (self.input_asset_id_b == 0) | self.config.second_input_in_use;
        constrain (self.output_asset_id_a == 0) | self.config.second_output_in_use;

        constrain !(self.config.second_input_in_use) | (self.input_asset_id_a != self.input_asset_id_b);

        let first_output_virtual = get_asset_id_flag(self.output_asset_id_a);
        let second_output_virtual = get_asset_id_flag(self.output_asset_id_b);
        let both_outputs_real = !first_output_virtual & !second_output_virtual;

        // "real output asset ids must be different for the second bridge output to be in-use"
        constrain !(self.config.second_output_in_use & both_outputs_real) | 
        (self.output_asset_id_a != self.output_asset_id_b);

        // The cast will tell the compiler that the value is a u30
        // which we need as we compare the virtual asset id with the output asset id in the following lines
        let virtual_asset_id_placeholder = ((1 as u30) << 29); 
        constrain !first_output_virtual | 
        (self.output_asset_id_a == virtual_asset_id_placeholder);
        constrain !second_output_virtual | 
        (self.output_asset_id_b == virtual_asset_id_placeholder);
    } 

    // TODO: this is to_safe_uint in C++ code, our max integer is half our field though
    // so we should check how to make this accurate to write
    fn to_field(self: Self) -> Field {
        // TODO: incorporate this into Noir, requires bit shifts to be allowed on Field Elements
        // Performing the same code using bit powers of 2 instead but bit shifts should be more efficient
        // let one: comptime Field = 1;
        // let result = (self.bridge_address_id as Field) + (self.input_asset_id_a as Field * (one << input_asset_id_a_shift)) +
        //                 (self.input_asset_id_b as Field * (one << input_asset_id_b_shift)) +
        //                 (self.output_asset_id_a as Field * (one << output_asset_id_a_shift)) +
        //                 (self.output_asset_id_b as Field * (one << output_asset_id_b_shift)) + self.config.to_suint() +
        //                 (self.aux_data as Field * (one << aux_data_shift));
        let two: comptime Field = 2;
        let result = (self.bridge_address_id as Field) + (self.input_asset_id_a as Field * std::pow_32(two, input_asset_id_a_shift)) +
                (self.input_asset_id_b as Field * std::pow_32(two, input_asset_id_b_shift)) +
                (self.output_asset_id_a as Field * std::pow_32(two, output_asset_id_a_shift)) +
                (self.output_asset_id_b as Field * std::pow_32(two, output_asset_id_b_shift)) + self.config.to_suint() +
                (self.aux_data as Field * std::pow_32(two, aux_data_shift));
        result
    }  
}

struct bit_config {
    second_input_in_use: bool,
    second_output_in_use: bool,
}

impl bit_config {
    fn to_suint(self: Self) -> Field {
        // Cannot bit shift fields
        // let bitconfig_scaling_factor = 1 << bitconfig_shift;
        let bitconfig_scaling_factor = std::pow_32(2, bitconfig_shift);

        let mut result = self.second_input_in_use as Field;
        result = result + ((self.second_output_in_use as Field) * 2);
        result = result * bitconfig_scaling_factor;
        result
    }
}

fn get_asset_id_flag(asset_id: u30) -> bool {
    let (is_virtual, _deflagged_asset_id) = deflag_asset_id(asset_id);
    is_virtual
}

fn deflag_asset_id(asset_id: u30) -> (bool, u1) {
    // TODO: use masking for this rather than deconstructing into bits
    // Extract the most significant bit of the asset id: bit 29-30.
    let asset_id_bits = std::to_bits(asset_id as Field, 30 as u32); // LSB is first val in returned array

    let is_virtual = asset_id_bits[28] == 1;
    let deflagged_asset_id = asset_id_bits[29];

    (is_virtual, deflagged_asset_id)
}