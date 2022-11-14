use dep::std;
use dep::utils;

fn main(x : Field) -> pub [u8; 16] {
    let byte_array = utils::half_of_field_to_bytes(x);
    byte_array
}