import { typedData } from "starknet";

const types = {
  StarkNetDomain: [
    { name: "name", type: "felt" },
    { name: "version", type: "felt" },
    { name: "chainId", type: "felt" },
  ],
  SimpleStruct: [
    { name: "some_felt252", type: "felt" },
    { name: "some_u128", type: "u128" },
  ],
};

interface SimpleStruct {
  some_felt252: string;
  some_u128: string;
}

function getDomain(chainId: string): typedData.StarkNetDomain {
  return {
    name: "dappName",
    version: "1",
    chainId,
  };
}

function getTypedDataHash(myStruct: SimpleStruct, chainId: string, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: SimpleStruct, chainId: string): typedData.TypedData {
  return {
    types,
    primaryType: "SimpleStruct",
    domain: getDomain(chainId),
    message: { ...myStruct },
  };
}

const simpleStruct: SimpleStruct = {
  some_felt252: "712",
  some_u128: "42",
};
// TODO DELETE ALL REF TO const X = Y, can be dfone through selector!("");
// sn_keccak('StarkNetDomain(name:felt,version:felt,chainId:felt)')
console.log(`const STARKNET_DOMAIN_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StarkNetDomain")};`);
// sn_keccak('SimpleStruct(some_felt252:felt,some_u128:felt)')
console.log(`const SIMPLE_STRUCT_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "SimpleStruct")};`);

console.log(`test test_valid_hash ${getTypedDataHash(simpleStruct, "0", 420n)};`);
