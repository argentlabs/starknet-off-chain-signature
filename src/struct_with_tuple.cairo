use box::BoxTrait;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};
use pedersen::{PedersenTrait, HashState};
use hash::{LegacyHash, HashStateTrait, HashStateExTrait};

const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

const STRUCT_WITH_TUPLE_TYPE_HASH: felt252 =
    selector!("StructWithTuple(some_felt252:felt,some_tuple_len:felt,some_tuple:felt*)");

#[derive(Drop, Copy)]
struct StructWithTuple {
    some_felt252: felt252,
    some_tuple: (felt252, u64, u128),
}

#[derive(Drop, Copy, Hash)]
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

impl OffchainMessageHashStructWithTuple of IOffchainMessageHash<StructWithTuple> {
    fn get_message_hash(self: @StructWithTuple) -> felt252 {
        let domain = StarknetDomain {
            name: 'dappName', version: 1, chain_id: get_tx_info().unbox().chain_id
        };
        let mut state = PedersenTrait::new(0);
        state = state.update_with('StarkNet Message');
        state = state.update_with(domain.hash_struct());
        // This can be a field within the struct, it doesn't have to be get_caller_address().
        state = state.update_with(get_caller_address());
        state = state.update_with(self.hash_struct());
        // Hashing with the amount of elements being hashed 
        state = state.update_with(4);
        state.finalize()
    }
}

impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
    fn hash_struct(self: @StarknetDomain) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(STARKNET_DOMAIN_TYPE_HASH);
        state = state.update_with(*self);
        state = state.update_with(4);
        state.finalize()
    }
}

// This could be done in a generic way, but for simplicity purposes it isn't.
impl StructHashSpanFelt252 of IStructHash<(felt252, u64, u128)> {
    fn hash_struct(self: @(felt252, u64, u128)) -> felt252 {
        let (item1, item2, item3) = self;
        let mut call_data_state = LegacyHash::hash(0, *item1);
        call_data_state = LegacyHash::hash(call_data_state, *item2);
        call_data_state = LegacyHash::hash(call_data_state, *item3);
        call_data_state = LegacyHash::hash(call_data_state, 3);
        call_data_state
    }
}

impl StructHashStructWithTuple of IStructHash<StructWithTuple> {
    fn hash_struct(self: @StructWithTuple) -> felt252 {
        let mut state = LegacyHash::hash(0, STRUCT_WITH_TUPLE_TYPE_HASH);
        state = LegacyHash::hash(state, *self.some_felt252);
        // Amount of items in the tuple
        state = LegacyHash::hash(state, 3);
        state = LegacyHash::hash(state, self.some_tuple.hash_struct());
        state = LegacyHash::hash(state, 4);
        state
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let message_hash = 0x3de2027ea81a253fe02932d4210bc21b0378d3b100ea5df62dc133b259193de;
    let simple_struct = StructWithTuple { some_felt252: 712, some_tuple: (42, 64, 128) };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
}
