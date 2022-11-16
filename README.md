# Aztec Circuits in Noir

This currently only has a complete account circuit, while a join split is in progress. Both are 

## Possible Bugs/Enhancements

### Can only multiply linear terms

FIXED in Noir PR #485

The code snippet below is from the join split circuit:
```
let no_input_notes = num_input_notes == 0;
let one_input_note = num_input_notes == 1;
let two_input_notes = num_input_notes == 2;
constrain no_input_notes | one_input_note | two_input_notes;
```
Panics with the message `'internal error: entered unreachable code: Can only multiply linear terms', crates/noirc_evaluator/src/ssa/acir_gen.rs:1015:9`. Check whether this is supposed to be an error, or if there is a way we can avoid it in the compiler. If it is unavoidable we should add better error handling either way so that is clear where is the unreachable code.

We can mock the final constrain statement with something like this:
```
if !no_input_notes {
  constrain one_input_note | two_input_notes;
}
```
This successfully compiles. Perhaps the compiler can do something similar to state that one condition implies another. TODO: Confirm whether this is actually unsafe to do and if there is another work around that is specific to circuit development.

I got the same panic message with the snippet below also from the join split circuit:
```
constrain is_deposit | is_withdraw | is_send | is_defi_deposit;
```
An altered version can be used here:
```
if !is_deposit | !is_withdraw {
  constrain is_send | is_defi_deposit;
}
```
or
```
let set = [DEPOSIT, WITHDRAW, SEND, DEFI_DEPOSIT];
let mut product = proof_id - set[0];
for i in 1..4 {
  product = product * (proof_id - set[i]);
};
constrain product == 0;
```
as performed by barretenberg's `assert_is_in_set` primitive.

Also taking note that using the `&` operator does not cause this panic:
```
constrain no_input_notes & one_input_note & two_input_notes; // Compiles as expected
```

I even got the panic for `Can only multiply linear terms` when trying to pass an OR'd expression to a function. Looking again in the join split there is a function `process_input_note`. Simply passing `input_note_1_in_use` causes the panic:
```
  let nullifier1 = process_input_note(account_private_key, 
    merkle_root,
    input_path1,
    input_note1_index,
    input_note_1,
    note1_propagated,
    input_note_1_in_use
  );
```
While if I replace `input_note_1_in_use` with simply `false` I compile successfully. Specific conditional handling as I have done above is necessary for both setting the value of `input_note_1_in_use` and any binary operations that use `input_note_1_in_use` inside of the method.

### Max value for opcode hash_to_field

Still BROKEN, reference issue #490 on main Noir repo for updates

When trying to use the Noir std lib function `hash_to_field` we panic in the SSA with this message: `thread 'main' panicked at 'not yet implemented: max value must be implemented for opcode hash_to_field ', crates/noirc_evaluator/src/ssa/integer.rs:494:22`. 

As `hash_to_field` simply returns a Field type I don't see why we couldn't easily implement the max value in SSA. Going to ask about this and implement it if there is not some blocker I am unaware of. 

