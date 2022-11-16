import { compile } from '@noir-lang/noir_wasm';
import {
  setup_generic_prover_and_verifier,
  create_proof,
  verify_proof,
  StandardExampleProver,
  StandardExampleVerifier,
} from '@noir-lang/barretenberg/dest/client_proofs';
import { BarretenbergWasm } from '@noir-lang/barretenberg/dest/wasm';
import { SinglePedersen } from '@noir-lang/barretenberg/dest/crypto/pedersen';
import { Schnorr } from '@noir-lang/barretenberg/dest/crypto/schnorr';
import { MerkleTree } from "../utils/MerkleTree";
import { resolve } from 'path';
import { expect } from 'chai';
import { ethers, Signer } from 'ethers';

type JoinSplitInputs = {
  proof_id: number;
  public_value: number;
  public_owner: Buffer;
  asset_id: number;
  num_inputs_notes: number;
  input_note1_index: number;
  input_note2_index: number;
  merkle_root: Buffer;
  input_note1: Buffer[];
  input_note2: Buffer[];
  output_note1: Buffer[];
  output_note2: Buffer[];
  // More inputs to put here
};

describe('Tests using typescript wrapper', function () {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let acir: any;
  let prover: StandardExampleProver;
  let verifier: StandardExampleVerifier;

  let tree: MerkleTree;
  let note_root: string;
  let barretenberg: BarretenbergWasm;
  let pedersen: SinglePedersen;

  let signers: Signer[];
  let recipient: string;
  let sender_priv_key: Buffer;
  let sender_pubkey_x;
  let sender_pubkey_y;
  let nullifier: Buffer;
  let note_commitment: Buffer;

  before(async () => {
    signers = await randomSigners(20);
    recipient = await signers[1].getAddress();

    barretenberg = await BarretenbergWasm.new();
    await barretenberg.init()

    pedersen = new SinglePedersen(barretenberg);

    let schnorr = new Schnorr(barretenberg);
    tree = new MerkleTree(32, barretenberg);

    const compiled_program = compile(resolve(__dirname, '../circuits/join_split/src/main.nr'));
    acir = compiled_program.circuit;
    [prover, verifier] = await setup_generic_prover_and_verifier(acir);
  });

  async function createAndVerifyProof(abi: JoinSplitInputs): Promise<boolean> {
    const proof = await create_proof(prover, acir, abi);

    return verify_proof(verifier, proof);
  }

  // context('when inputs are equal', () => {
  //   it('rejects the proof', async () => {
  //     const abi: JoinSplitTx = { x: 3, y: 3 };
  //     const verified = await createAndVerifyProof(abi);

  //     expect(verified).to.be.false;
  //   });
  // });

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
