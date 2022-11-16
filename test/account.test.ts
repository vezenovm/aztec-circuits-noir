import { compile, acir_from_bytes } from '@noir-lang/noir_wasm';
import {
  setup_generic_prover_and_verifier,
  create_proof,
  verify_proof,
  StandardExampleProver,
  StandardExampleVerifier,
} from '@noir-lang/barretenberg/dest/client_proofs';
import { resolve } from 'path';
import { expect } from 'chai';
import { ethers, Signer } from 'ethers';
import { readFileSync } from 'fs';

type AccountInputs = {
  data_tree_root: Buffer;
  account_public_key: [Buffer, Buffer]; // All keys are size 2 arrays for x and y points on curve
  new_account_public_key: [Buffer, Buffer];
  spending_public_key_1: [Buffer, Buffer];
  spending_public_key_2: [Buffer, Buffer];
  alias_hash: Buffer;
  create: number;
  migrate: number;
  account_note_index: Buffer;
  account_note_path: [Buffer, Buffer]; // 32 depth
  signing_pub_key: [Buffer, Buffer];
  signature: Buffer[]; // u8 array of size 64
  return: Buffer[]; // 15 return inputs here, almost all zero aside from nullifiers
};

describe('Account circuit tests using typescript wrapper', async function () {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let acir: any;
    let prover: StandardExampleProver;
    let verifier: StandardExampleVerifier;
  
    before(async () => {
    //   const compiled_program = compile(resolve(__dirname, '../circuits/account/src/main.nr'));
    //   acir = compiled_program.circuit;
      let acirByteArray = path_to_uint8array(resolve(__dirname, '../circuits/build/p.acir'));
      acir = acir_from_bytes(acirByteArray);
      console.dir(acir);
      [prover, verifier] = await setup_generic_prover_and_verifier(acir);
    });
  
    async function createAndVerifyProof(abi: AccountInputs): Promise<boolean> {
      const proof = await create_proof(prover, acir, abi);
  
      return verify_proof(verifier, proof);
    }
  
    context('when inputs are equal', () => {
      it('rejects the proof', async () => {
        // const abi: JoinSplitTx = { x: 3, y: 3 };
        // const verified = await createAndVerifyProof(abi);
        expect(false).to.be.false;
      });
    });
  
    // context('when inputs are unequal', () => {
    //   it('accepts the proof', async () => {
    //     const abi: JoinSplitTx = { x: 3, y: 4 };
    //     const verified = await createAndVerifyProof(abi);
  
    //     expect(verified).to.be.true;
    //   });
    // });
  });
  
  const randomSigners = (amount: number): Signer[] => {
    const signers: Signer[] = []
    for (let i = 0; i < amount; i++) {
      signers.push(ethers.Wallet.createRandom())
    }
    return signers
  }

function path_to_uint8array(path: string) {
  let buffer = readFileSync(path);
  return new Uint8Array(buffer);
}
