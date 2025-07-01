import { shortString, StarknetDomain, TypedData, typedData, TypedDataRevision } from "starknet";

const types = {
  StarknetDomain: [
    { name: "name", type: "shortstring" },
    { name: "version", type: "shortstring" },
    { name: "chainId", type: "shortstring" },
    { name: "revision", type: "shortstring" },
  ],
  // In V1 we privilege user friendly names
  StructWithMerkletree: [
    { name: "Some felt252", type: "felt" },
    { name: "Some merkletree root", type: "merkletree", contains: "SomeLeaf" },
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
    version: shortString.encodeShortString("1"),
    chainId,
    revision: TypedDataRevision.ACTIVE,
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
    message: { "Some felt252": myStruct.someFelt252, "Some merkletree root": myStruct.someMerkletreeRoot },
  };
}

const structWithMerkletree: StructWithMerkletree = {
  someFelt252: "712",
  someMerkletreeRoot: [{ contract_address: "0x1" }, { contract_address: "0x2" }],
};

console.log(`test test_valid_hash ${getTypedDataHash(structWithMerkletree, "0", 420n)};`);
