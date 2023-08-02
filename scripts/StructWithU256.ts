import { constants, typedData, uint256 } from "starknet";

const types = {
  StarkNetDomain: [
    { name: "name", type: "felt" },
    { name: "version", type: "felt" },
    { name: "chainId", type: "felt" },
  ],
  StructWithU256: [
    { name: "some_felt252", type: "felt" },
    { name: "some_u256", type: "u256" },
  ],
  u256: [
    { name: "low", type: "felt" },
    { name: "high", type: "felt" },
  ],
};

interface StructWithU256 {
  some_felt252: string;
  some_u256: uint256.Uint256;
}

function getDomain(chainId: constants.NetworkName): typedData.StarkNetDomain {
  return {
    name: "dappName",
    version: "1",
    chainId,
  };
}

function getTypedDataHash(myStruct: StructWithU256, chainId: constants.NetworkName, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithU256, chainId: constants.NetworkName): typedData.TypedData {
  return {
    types,
    primaryType: "StructWithU256",
    domain: getDomain(chainId),
    message: { ...myStruct },
  };
}

const structWithU256: StructWithU256 = {
  some_felt252: "712",
  some_u256: uint256.bnToUint256(42),
};

console.log(`const STARKNET_DOMAIN_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StarkNetDomain")};`);
console.log(`const STRUCT_WITH_U256_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StructWithU256")};`);
console.log(`const U256_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "u256")};`);
console.log(`test test_valid_hash ${getTypedDataHash(structWithU256, constants.NetworkName.SN_MAIN, 420n)};`);
