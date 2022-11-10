use dep::std;
use dep::utils;

fn main(x : Field) -> pub [u8; 4] {
    let byte_array = utils::field_first_four_bytes(x);
    byte_array
}