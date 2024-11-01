import { shortString, StarknetDomain, TypedData, typedData, TypedDataRevision } from "starknet";

const types = {
  StarknetDomain: [
    { name: "name", type: "shortstring" },
    { name: "version", type: "shortstring" },
    { name: "chainId", type: "shortstring" },
    { name: "revision", type: "shortstring" },
  ],
  StructWithString: [
    { name: "some_felt252", type: "felt" },
    { name: "some_string", type: "string" },
  ],
};

interface StructWithString {
  some_felt252: string;
  some_string: string;
}

function getDomain(chainId: string): StarknetDomain {
  return {
    name: "dappName",
    version: "1",
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
    message: { ...myStruct },
  };
}

const structWithByteArray: StructWithString = {
  some_felt252: "712",
  some_string: "Some long message that exceeds 31 characters",
};

console.log(`test test_valid_hash ${getTypedDataHash(structWithByteArray, "0", 420n)};`);
