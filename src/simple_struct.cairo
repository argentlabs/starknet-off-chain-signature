use box::BoxTrait;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};
use pedersen::{PedersenTrait, HashState};
use hash::{LegacyHash, HashStateTrait, Hash, HashStateExTrait};

const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

const SIMPLE_STRUCT_TYPE_HASH: felt252 =
    selector!("SimpleStruct(some_felt252:felt,some_u128:u128)");

#[derive(Drop, Copy, Hash)]
struct SimpleStruct {
    some_felt252: felt252,
    some_u128: u128,
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

impl OffchainMessageHashSimpleStruct of IOffchainMessageHash<SimpleStruct> {
    fn get_message_hash(self: @SimpleStruct) -> felt252 {
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

impl StructHashSimpleStruct of IStructHash<SimpleStruct> {
    fn hash_struct(self: @SimpleStruct) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(SIMPLE_STRUCT_TYPE_HASH);
        state = state.update_with(*self);
        state = state.update_with(3);
        state.finalize()
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let message_hash = 0x1e739b39f83b38f182edaed69f730f18eff802d3ef44be91c3733cdcab6de2f;
    let simple_struct = SimpleStruct { some_felt252: 712, some_u128: 42 };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
}
