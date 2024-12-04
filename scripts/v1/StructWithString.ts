import { shortString, StarknetDomain, TypedData, typedData, TypedDataRevision } from "starknet";

const types = {
  StarknetDomain: [
    { name: "name", type: "shortstring" },
    { name: "version", type: "shortstring" },
    { name: "chainId", type: "shortstring" },
    { name: "revision", type: "shortstring" },
  ],
  // In V1 we privilege user friendly names
  StructWithString: [
    { name: "Some felt252", type: "felt" },
    { name: "Some string", type: "string" },
  ],
};

interface StructWithString {
  someFelt252: string;
  someString: string;
}

function getDomain(chainId: string): StarknetDomain {
  return {
    name: "dappName",
    version: shortString.encodeShortString("1"),
    chainId,
    revision: TypedDataRevision.ACTIVE,
  };
}

function getTypedDataHash(myStruct: StructWithString, chainId: string, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithString, chainId: string): TypedData {
  return {
    types,
    primaryType: "StructWithString",
    domain: getDomain(chainId),
    message: { "Some felt252": myStruct.someFelt252, "Some string": myStruct.someString },
  };
}

const structWithByteArray: StructWithString = {
  someFelt252: "712",
  someString: "Some long message that exceeds 31 characters",
};

console.log(`test test_valid_hash ${getTypedDataHash(structWithByteArray, "0", 420n)};`);
