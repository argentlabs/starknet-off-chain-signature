import { typedData } from "starknet";

const types = {
  StarkNetDomain: [
    { name: "name", type: "felt" },
    { name: "version", type: "felt" },
    { name: "chainId", type: "felt" },
  ],
  StructWithArray: [
    { name: "some_felt252", type: "felt" },
    { name: "some_array", type: "felt*" },
  ],
};

interface StructWithArray {
  some_felt252: string;
  some_array: string[];
}

function getDomain(chainId: string): typedData.StarkNetDomain {
  return {
    name: "dappName",
    version: "1",
    chainId,
  };
}

function getTypedDataHash(myStruct: StructWithArray, chainId: string, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithArray, chainId: string): typedData.TypedData {
  return {
    types,
    primaryType: "StructWithArray",
    domain: getDomain(chainId),
    message: { ...myStruct },
  };
}

const structWithArray: StructWithArray = {
  some_felt252: "712",
  some_array: ["4", "2"],
};

console.log(`test test_valid_hash ${getTypedDataHash(structWithArray, "0", 420n)};`);
