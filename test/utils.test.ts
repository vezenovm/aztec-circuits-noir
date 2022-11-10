import { compile, acir_from_bytes } from '@noir-lang/noir_wasm';
import {
  setup_generic_prover_and_verifier,
  create_proof,
  verify_proof,
  StandardExampleProver,
  StandardExampleVerifier
} from '@noir-lang/barretenberg/dest/client_proofs';
// import {
//   getCircuitSizeNoRounding
// } from '@noir-lang/barretenberg/src/client_proofs';
// import { BarretenbergWasm } from '@noir-lang/barretenberg/src/wasm';
// import { serialise_acir_to_barrtenberg_circuit } from '@noir-lang/aztec_backend';
import { resolve } from 'path';
import { expect } from 'chai';
import { ethers, Signer } from 'ethers';
import { readFileSync } from 'fs';

type FieldToU8Input = {
    field: string,
    return: string[]
};

describe('Field to u8 array circuit tests using typescript wrapper', function () {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let acir: any;
    let prover: StandardExampleProver;
    let verifier: StandardExampleVerifier;
    // let barretenberg: BarretenbergWasm;

    before(async () => {
      // barretenberg = await BarretenbergWasm.new();
      // await barretenberg.init()


      let acirByteArray = path_to_uint8array(resolve(__dirname, './test_circuits/field_to_u8_arr/build/p.acir'));
      acir = acir_from_bytes(acirByteArray);
      console.dir(acir);
      [prover, verifier] = await setup_generic_prover_and_verifier(acir);
    });
  
    async function createAndVerifyProof(abi: FieldToU8Input): Promise<boolean> {
      const proof = await create_proof(prover, acir, abi);
  
      return verify_proof(verifier, proof);
    }
  
    context('when return value is correct', () => {
      it('accepts the proof', async () => {
        const abi: FieldToU8Input = { 
            field: toFixedHex(2040124, true),
            return: ["0x3c", "0x21", "0x1f", "0x00"]
        };
        // TODO: get these methods into barretenberg 
        
        // let serialised_circuit = serialise_acir_to_barrtenberg_circuit(acir);
        // let circuit_size = getCircuitSizeNoRounding(barretenberg, serialised_circuit);
        // console.log(circuit_size);
        const verified = await createAndVerifyProof(abi);
        expect(verified).to.be.true;
      });
    });
  
    context('when return value is incorrect', () => {
      it('rejects the proof', async () => {
        const abi: FieldToU8Input = { 
          field: toFixedHex(2040124, true),
          return: ["0x00", "0x1f", "0x21", "0x3c"]
        };        
      
        const verified = await createAndVerifyProof(abi);
  
        expect(verified).to.be.false;
      });
    });
});

function path_to_uint8array(path: string) {
  let buffer = readFileSync(path);
  return new Uint8Array(buffer);
}

const toFixedHex = (number: number, pad0x: boolean, length = 32) => {
    let hexString = number.toString(16).padStart(length * 2, '0');
    return (pad0x ? `0x` + hexString : hexString);
  }
