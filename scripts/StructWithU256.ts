import { shortString, StarknetDomain, TypedData, typedData, TypedDataRevision, Uint256, uint256 } from "starknet";

const types = {
  StarknetDomain: [
    { name: "name", type: "shortstring" },
    { name: "version", type: "shortstring" },
    { name: "chainId", type: "shortstring" },
    { name: "revision", type: "shortstring" },
  ],
  // In V1 we privilege user friendly names
  StructWithU256: [
    { name: "Some felt252", type: "felt" },
    { name: "Some u256", type: "u256" },
  ],
  u256: [
    { name: "low", type: "felt" },
    { name: "high", type: "felt" },
  ],
};

interface StructWithU256 {
  someFelt252: string;
  someU256: Uint256;
}

function getDomain(chainId: string): StarknetDomain {
  return {
    name: "dappName",
    version: shortString.encodeShortString("1"),
    chainId,
    revision: TypedDataRevision.ACTIVE,
  };
}

function getTypedDataHash(myStruct: StructWithU256, chainId: string, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithU256, chainId: string): TypedData {
  return {
    types,
    primaryType: "StructWithU256",
    domain: getDomain(chainId),
    message: { "Some felt252": myStruct.someFelt252, "Some u256": myStruct.someU256 },
  };
}

const structWithU256: StructWithU256 = {
  someFelt252: "712",
  someU256: uint256.bnToUint256(42),
};

console.log(`test test_valid_hash ${getTypedDataHash(structWithU256, "0", 420n)};`);
