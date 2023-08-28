use box::BoxTrait;
use hash::LegacyHash;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};
use traits::Into;

const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

const STRUCT_WITH_ENUM_TYPE_HASH: felt252 =
    selector!("StructWithEnum(some_felt252:felt,some_enum:felt)");

const ENUM_FIRST_CHOICE_TYPE_HASH: felt252 = selector!("SomeEnum::FirstChoice()");

const ENUM_SEC_CHOICE_TYPE_HASH: felt252 = selector!("SomeEnum::SecondChoice()");

const ENUM_THIRD_CHOICE_TYPE_HASH: felt252 = selector!("SomeEnum::ThirdChoice()");

#[derive(Drop, Copy)]
struct StructWithEnum {
    some_felt252: felt252,
    some_enum: SomeEnum,
}

#[derive(Drop, Copy)]
enum SomeEnum {
    FirstChoice: (),
    SecondChoice: (),
    ThirdChoice: (),
}

#[derive(Drop, Copy)]
struct StarknetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252,
}

trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

impl OffchainMessageHashStructWithEnum of IOffchainMessageHash<StructWithEnum> {
    fn get_message_hash(self: @StructWithEnum) -> felt252 {
        let domain = StarknetDomain {
            name: 'dappName', version: 1, chain_id: get_tx_info().unbox().chain_id
        };
        let mut state = LegacyHash::hash(0, 'StarkNet Message');
        state = LegacyHash::hash(state, domain.hash_struct());
        // This can be a field within the struct, it doesn't have to be get_caller_address().
        state = LegacyHash::hash(state, get_caller_address());
        state = LegacyHash::hash(state, self.hash_struct());
        // Hashing with the amount of elements being hashed 
        state = LegacyHash::hash(state, 4);
        state
    }
}

impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
    fn hash_struct(self: @StarknetDomain) -> felt252 {
        let mut state = LegacyHash::hash(0, STARKNET_DOMAIN_TYPE_HASH);
        state = LegacyHash::hash(state, *self.name);
        state = LegacyHash::hash(state, *self.version);
        state = LegacyHash::hash(state, *self.chain_id);
        state = LegacyHash::hash(state, 4);
        state
    }
}

impl StructHashStructWithEnum of IStructHash<StructWithEnum> {
    fn hash_struct(self: @StructWithEnum) -> felt252 {
        let mut state = LegacyHash::hash(0, STRUCT_WITH_ENUM_TYPE_HASH);
        state = LegacyHash::hash(state, *self.some_felt252);
        state = LegacyHash::hash(state, self.some_enum.hash_struct());
        state = LegacyHash::hash(state, 3);
        state
    }
}

impl LegacyHashSomeEnum of IStructHash<SomeEnum> {
    fn hash_struct(self: @SomeEnum) -> felt252 {
        let enum_hash = match self {
            SomeEnum::FirstChoice(_) => ENUM_FIRST_CHOICE_TYPE_HASH,
            SomeEnum::SecondChoice(_) => ENUM_SEC_CHOICE_TYPE_HASH,
            SomeEnum::ThirdChoice(_) => ENUM_THIRD_CHOICE_TYPE_HASH,
        };
        let mut state = LegacyHash::hash(0, enum_hash);
        state = LegacyHash::hash(state, 1);
        state
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let message_hash = 0x119b85972ccef13366168acc914627db42b5e7dd146d8be034224860b84a788;
    let simple_struct = StructWithEnum { some_felt252: 712, some_enum: SomeEnum::ThirdChoice(()) };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
}
