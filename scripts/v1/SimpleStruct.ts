import { shortString, StarknetDomain, TypedData, typedData, TypedDataRevision } from "starknet";

const types = {
  StarknetDomain: [
    { name: "name", type: "shortstring" },
    { name: "version", type: "shortstring" },
    { name: "chainId", type: "shortstring" },
    { name: "revision", type: "shortstring" },
  ],
  // In V1 we privilege user friendly names
  SimpleStruct: [
    { name: "Some felt252", type: "felt" },
    { name: "Some u128", type: "u128" },
  ],
};

interface SimpleStruct {
  someFelt252: string;
  someU128: string;
}

function getDomain(chainId: string): StarknetDomain {
  return {
    name: "dappName",
    version: shortString.encodeShortString("1"),
    chainId,
    revision: TypedDataRevision.ACTIVE,
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
    message: { "Some felt252": myStruct.someFelt252, "Some u128": myStruct.someU128 },
  };
}

const simpleStruct: SimpleStruct = {
  someFelt252: "712",
  someU128: "42",
};

console.log(`test test_valid_hash ${getTypedDataHash(simpleStruct, "0", 420n)};`);
