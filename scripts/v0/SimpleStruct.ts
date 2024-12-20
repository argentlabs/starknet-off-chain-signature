import { StarknetDomain, TypedData, typedData } from "starknet";

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
  someFelt252: string;
  someU128: string;
}

function getDomain(chainId: string): StarknetDomain {
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
function getTypedData(myStruct: SimpleStruct, chainId: string): TypedData {
  return {
    types,
    primaryType: "SimpleStruct",
    domain: getDomain(chainId),
    message: { som_felt252: myStruct.someFelt252, some_u128: myStruct.someU128 },
  };
}

const simpleStruct: SimpleStruct = {
  someFelt252: "712",
  someU128: "42",
};

console.log(`test test_valid_hash ${getTypedDataHash(simpleStruct, "0", 420n)};`);
