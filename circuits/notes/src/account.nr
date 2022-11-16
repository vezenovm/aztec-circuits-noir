use dep::std;

struct AccountNote {
  account_alias_hash: Field,
  account_public_key: [Field; 2],
  signing_pub_key: [Field; 2],
  commitment: Field
}

impl AccountNote {
  fn new(
    account_alias_hash: Field,
    account_public_key: [Field; 2],
    signing_pub_key: [Field; 2]
  ) -> AccountNote {
    AccountNote {
      account_alias_hash: account_alias_hash,
      account_public_key: account_public_key,
      signing_pub_key: signing_pub_key,
      commitment: std::hash::pedersen(
        [
          account_alias_hash, 
          account_public_key[0], 
          account_public_key[1], 
          signing_pub_key[0], 
          signing_pub_key[1]
        ]
      )[0]
    }
  }
}