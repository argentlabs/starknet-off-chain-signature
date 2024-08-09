import { shortString, StarknetDomain, TypedData, typedData, TypedDataRevision } from "starknet";

const types = {
  StarknetDomain: [
    { name: "name", type: "shortstring" },
    { name: "version", type: "shortstring" },
    { name: "chainId", type: "shortstring" },
    { name: "revision", type: "shortstring" },
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
    message: { ...myStruct },
  };
}

const simpleStruct: SimpleStruct = {
  some_felt252: "712",
  some_u128: "42",
};

console.log(`test test_valid_hash ${getTypedDataHash(simpleStruct, "0", 420n)};`);
