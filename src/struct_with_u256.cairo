use box::BoxTrait;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};
use pedersen::PedersenTrait;
use hash::{HashStateTrait, HashStateExTrait};

const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

const STRUCT_WITH_U256_TYPE_HASH: felt252 =
    selector!("StructWithU256(some_felt252:felt,some_u256:u256)u256(low:felt,high:felt)");

const U256_TYPE_HASH: felt252 = selector!("u256(low:felt,high:felt)");

#[derive(Drop, Copy, Hash)]
struct StructWithU256 {
    some_felt252: felt252,
    some_u256: u256,
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

impl OffchainMessageHashStructWithU256 of IOffchainMessageHash<StructWithU256> {
    fn get_message_hash(self: @StructWithU256) -> felt252 {
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

impl StructHashStructWithU256 of IStructHash<StructWithU256> {
    fn hash_struct(self: @StructWithU256) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(STRUCT_WITH_U256_TYPE_HASH);
        state = state.update_with(*self.some_felt252);
        state = state.update_with(self.some_u256.hash_struct());
        state = state.update_with(3);
        state.finalize()
    }
}

impl StructHashU256 of IStructHash<u256> {
    fn hash_struct(self: @u256) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(U256_TYPE_HASH);
        state = state.update_with(*self);
        state = state.update_with(3);
        state.finalize()
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let message_hash = 0x24fcf47ecd5090d0dfd5e66a57e5d56d3db3478e37bb90c1b1351b4317197fd;
    let simple_struct = StructWithU256 { some_felt252: 712, some_u256: 42 };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
}
