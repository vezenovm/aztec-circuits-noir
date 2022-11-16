use dep::std;
use dep::utils;

fn main(x : Field) -> pub [u8; 4] {
    let byte_array = utils::field_to_bytes(x);
    [byte_array[0], byte_array[1], byte_array[2], byte_array[3]]
}
