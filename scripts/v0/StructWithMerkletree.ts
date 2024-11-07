import { StarknetDomain, TypedData, typedData } from "starknet";

const types = {
  StarkNetDomain: [
    { name: "name", type: "felt" },
    { name: "version", type: "felt" },
    { name: "chainId", type: "felt" },
  ],
  StructWithMerkletree: [
    { name: "some_felt252", type: "felt" },
    { name: "some_merkletree_root", type: "merkletree", contains: "SomeLeaf" },
  ],
  SomeLeaf: [{ name: "contract_address", type: "ContractAddress" }],
};

interface StructWithMerkletree {
  someFelt252: string;
  someMerkletreeRoot: SomeLeaf[];
}

export interface SomeLeaf {
  contract_address: string;
}

function getDomain(chainId: string): StarknetDomain {
  return {
    name: "dappName",
    version: "1",
    chainId,
  };
}

function getTypedDataHash(myStruct: StructWithMerkletree, chainId: string, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithMerkletree, chainId: string): TypedData {
  return {
    types,
    primaryType: "StructWithMerkletree",
    domain: getDomain(chainId),
    message: { some_felt252: myStruct.someFelt252, some_merkletree_root: myStruct.someMerkletreeRoot },
  };
}

const structWithMerkletree: StructWithMerkletree = {
  someFelt252: "712",
  someMerkletreeRoot: [{ contract_address: "0x1" }, { contract_address: "0x2" }],
};

console.log(`test test_valid_hash ${getTypedDataHash(structWithMerkletree, "0", 420n)};`);
