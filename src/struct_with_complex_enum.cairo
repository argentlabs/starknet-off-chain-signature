use box::BoxTrait;
use hash::LegacyHash;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};
use traits::Into;

// h('StarkNetDomain(name:felt,version:felt,chainId:felt)')
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    0x1bfc207425a47a5dfa1a50a4f5241203f50624ca5fdf5e18755765416b8e288;

// h('StructWithEnum(some_felt252:felt,some_complex_enum:felt)')                                                                          
const STRUCT_WITH_ENUM_TYPE_HASH: felt252 =
    0x3b49852745590b48cdb4128ff17830dcbb63627fe5f1afa864e4f549e361e86;

// h('SomeEnum::FirstChoice()')
const ENUM_FIRST_CHOICE_TYPE_HASH: felt252 =
    0x28dd8cb67a18f24036cea63e72c714157cccaad60b0eede0a468612d13c1755;

// h('SomeEnum::SecondChoice(felt)')
const ENUM_SECOND_CHOICE_TYPE_HASH: felt252 =
    0x3d238c1c1f9b0bac95f99d1d30a376fb19c6447261bfce8db97fd19856fdcd3;

// h('SomeEnum::ThirdChoice(felt,felt)')
const ENUM_THIRD_CHOICE_TYPE_HASH: felt252 =
    0x3cfd38cbc44d4ec54759422dabfd051d7f20a407a53f1e6bc0fc3d9e321b952;


#[derive(Drop, Copy)]
struct StructWithEnum {
    some_felt252: felt252,
    some_complex_enum: SomeEnum,
}

#[derive(Drop, Copy)]
enum SomeEnum {
    FirstChoice: (),
    SecondChoice: (u128, ),
    ThirdChoice: (u64, u128, ),
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
        state = LegacyHash::hash(state, self.some_complex_enum.hash_struct());
        state = LegacyHash::hash(state, 3);
        state
    }
}

impl LegacyHashSomeEnum of IStructHash<SomeEnum> {
    fn hash_struct(self: @SomeEnum) -> felt252 {
        match self {
            SomeEnum::FirstChoice(_) => {
                let mut state = LegacyHash::hash(0, ENUM_FIRST_CHOICE_TYPE_HASH);
                state = LegacyHash::hash(state, 1);
                state
            },
            SomeEnum::SecondChoice((
                val
            )) => {
                let mut state = LegacyHash::hash(0, ENUM_SECOND_CHOICE_TYPE_HASH);
                state = LegacyHash::hash(state, *val);
                state = LegacyHash::hash(state, 2);
                state
            },
            SomeEnum::ThirdChoice((
                val1, val2
            )) => {
                let mut state = LegacyHash::hash(0, ENUM_THIRD_CHOICE_TYPE_HASH);
                state = LegacyHash::hash(state, *val1);
                state = LegacyHash::hash(state, *val2);
                state = LegacyHash::hash(state, 3);
                state
            },
        }
    }
}

// This could be done in a generic way, but for simplicity purposes it isn't.
impl StructHashSpanFelt252 of IStructHash<(u64, u128)> {
    fn hash_struct(self: @(u64, u128)) -> felt252 {
        let (item1, item2) = self;
        let mut call_data_state = LegacyHash::hash(0, *item1);
        call_data_state = LegacyHash::hash(call_data_state, *item2);
        call_data_state = LegacyHash::hash(call_data_state, 2);
        call_data_state
    }
}


#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let simple_struct_hashed = 0x4c376fd4cb54740092e961353ebea3e13dadf7fcdaf8eee920d82d9c80b8dca;
    let simple_struct = StructWithEnum {
        some_felt252: 712, some_complex_enum: SomeEnum::ThirdChoice((42, 128))
    };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == simple_struct_hashed, 'Hash should be valid');
}
