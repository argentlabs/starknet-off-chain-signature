import {  typedData } from "starknet";

const types = {
  StarkNetDomain: [
    { name: "name", type: "felt" },
    { name: "version", type: "felt" },
    { name: "chainId", type: "felt" },
  ],
  StructWithTuple: [
    { name: "some_felt252", type: "felt" },
    { name: "some_tuple_len", type: "felt" },
    { name: "some_tuple", type: "felt*" },
  ],
};

interface StructWithTuple {
  some_felt252: string;
  some_tuple: [string, string, string];
}
function getDomain(chainId: string): typedData.StarkNetDomain {
  return {
    name: "dappName",
    version: "1",
    chainId,
  };
}

function getTypedDataHash(myStruct: StructWithTuple, chainId: string, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithTuple, chainId: string): typedData.TypedData {
  return {
    types,
    primaryType: "StructWithTuple",
    domain: getDomain(chainId),
    message: { ...myStruct, some_tuple_len: myStruct.some_tuple.length },
  };
}

const structWithTuple: StructWithTuple = {
  some_felt252: "712",
  some_tuple: ["42", "64", "128"],
};

console.log(`const STARKNET_DOMAIN_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StarkNetDomain")};`);
console.log(`const STRUCT_WITH_TUPLE_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StructWithTuple")};`);
console.log(`test test_valid_hash ${getTypedDataHash(structWithTuple, "0", 420n)};`);
