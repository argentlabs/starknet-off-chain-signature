import { constants, selector, typedData } from "starknet";

const types = {
  StarkNetDomain: [
    { name: "name", type: "felt" },
    { name: "version", type: "felt" },
    { name: "chainId", type: "felt" },
  ],
  StructWithEnum: [
    { name: "some_felt252", type: "felt" },
    { name: "some_enum", type: "felt*" },
  ],
};

// Computed down using 'selector.getSelectorFromName()'
enum SomeEnum {
  FirstChoice = "0x28dd8cb67a18f24036cea63e72c714157cccaad60b0eede0a468612d13c1755",
  SecondChoice = "0x37b53e745a09647bd052eed3d841d034b68be6875b8ca2b6946713872920de0",
  ThirdChoice = "0x2ff25f5b6f85e646f3d741f9623a7c2098e7db51f287f5a7a9ac8b5e0437671",
}

interface StructWithEnum {
  some_felt252: string;
  some_enum: string[];
}

function getDomain(chainId: constants.NetworkName): typedData.StarkNetDomain {
  return {
    name: "dappName",
    version: "1",
    chainId,
  };
}

function getTypedDataHash(myStruct: StructWithEnum, chainId: constants.NetworkName, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithEnum, chainId: constants.NetworkName): typedData.TypedData {
  return {
    types,
    primaryType: "StructWithEnum",
    domain: getDomain(chainId),
    message: { ...myStruct },
  };
}

const structWithEnum: StructWithEnum = {
  some_felt252: "712",
  some_enum: [SomeEnum.ThirdChoice],
};

console.log(`const STARKNET_DOMAIN_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StarkNetDomain")};`);
console.log(`const STRUCT_WITH_ENUM_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StructWithEnum")};`);
console.log(`const ENUM_FIRST_CHOICE_TYPE_HASH: felt252 = ${selector.getSelectorFromName("SomeEnum::FirstChoice()")};`);
console.log(`const ENUM_SEC_CHOICE_TYPE_HASH: felt252 = ${selector.getSelectorFromName("SomeEnum::SecondChoice()")};`);
console.log(`const ENUM_THIRD_CHOICE_TYPE_HASH: felt252 = ${selector.getSelectorFromName("SomeEnum::ThirdChoice()")};`);
console.log(`test test_valid_hash ${getTypedDataHash(structWithEnum, constants.NetworkName.SN_MAIN, 420n)};`);
