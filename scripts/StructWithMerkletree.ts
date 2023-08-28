import { typedData } from "starknet";

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
  some_felt252: string;
  some_merkletree_root: SomeLeaf[];
}

export interface SomeLeaf {
  contract_address: string;
}

function getDomain(chainId: string): typedData.StarkNetDomain {
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
function getTypedData(myStruct: StructWithMerkletree, chainId: string): typedData.TypedData {
  return {
    types,
    primaryType: "StructWithMerkletree",
    domain: getDomain(chainId),
    message: { ...myStruct },
  };
}
const someLeaves: SomeLeaf[] = [{ contract_address: "0x1" }, { contract_address: "0x2" }];

const structWithMerkletree: StructWithMerkletree = {
  some_felt252: "712",
  some_merkletree_root: someLeaves,
};

// sn_keccak('StarkNetDomain(name:felt,version:felt,chainId:felt)')
console.log(`const STARKNET_DOMAIN_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StarkNetDomain")};`);
// sn_keccak('SomeLeaf(contract_address:ContractAddress)')
console.log(`const SOME_LEAF_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "SomeLeaf")};`);
// sn_keccak('StructWithU256(some_felt252:felt,some_u256:u256)u256(low:felt,high:felt)')
console.log(
  `const STRUCT_WITH_MERKLETREE_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StructWithMerkletree")};`,
);

console.log(`test test_valid_hash ${getTypedDataHash(structWithMerkletree, "0", 420n)};`);