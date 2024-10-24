import { byteArray, shortString, StarknetDomain, TypedData, typedData, TypedDataRevision } from "starknet";

const types = {
  StarknetDomain: [
    { name: "name", type: "shortstring" },
    { name: "version", type: "shortstring" },
    { name: "chainId", type: "shortstring" },
    { name: "revision", type: "shortstring" },
  ],
  StructWithByteArray: [
    { name: "some_felt252", type: "felt" },
    { name: "some_byte_array", type: "string" },
  ],
};

interface StructWithByteArray {
  some_felt252: string;
  some_byte_array: string;
}


function getDomain(chainId: string): StarknetDomain {
  return {
    name: "dappName",
    version: shortString.encodeShortString("1"),
    chainId,
    revision: TypedDataRevision.ACTIVE,
  };
}

function getTypedDataHash(myStruct: StructWithByteArray, chainId: string, owner: bigint): string {
  console.log(JSON.stringify(getTypedData(myStruct, chainId)));
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithByteArray, chainId: string): TypedData {
  return {
    types,
    primaryType: "StructWithByteArray",
    domain: getDomain(chainId),
    message: { ...myStruct },
  };
}

console.log(byteArray.byteArrayFromString("Some long message that exceeds 31 characters"));
const structWithByteArray: StructWithByteArray = {
  some_felt252: "712",
  some_byte_array: "Some long message that exceeds 31 characters",
};

console.log(`test test_valid_hash ${getTypedDataHash(structWithByteArray, "0", 420n)};`);
