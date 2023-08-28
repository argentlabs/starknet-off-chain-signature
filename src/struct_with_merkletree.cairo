use box::BoxTrait;
use hash::LegacyHash;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};

const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

const STRUCT_WITH_MERKLETREE_TYPE_HASH: felt252 =
    selector!("StructWithMerkletree(some_felt252:felt,some_merkletree_root:merkletree)");

#[derive(Drop, Copy)]
struct StructWithMerkletree {
    some_felt252: felt252,
    some_merkletree_root: felt252,
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

impl OffchainMessageHashStructWithMerkletree of IOffchainMessageHash<StructWithMerkletree> {
    fn get_message_hash(self: @StructWithMerkletree) -> felt252 {
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

impl StructHashStructWithMerkletree of IStructHash<StructWithMerkletree> {
    fn hash_struct(self: @StructWithMerkletree) -> felt252 {
        let mut state = LegacyHash::hash(0, STRUCT_WITH_MERKLETREE_TYPE_HASH);
        state = LegacyHash::hash(state, *self.some_felt252);
        state = LegacyHash::hash(state, *self.some_merkletree_root);
        state = LegacyHash::hash(state, 3);
        state
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let message_hash = 0x4e4aa6e92e1250e5277a99686aa17c411b28b83fc948df78c10f848f1b0ad30;
    let simple_struct = StructWithMerkletree {
        some_felt252: 712,
        some_merkletree_root: 0x1e3fb24d6eeb2fdf4308dd358adfb0169dcdb21b3c6bac8ca223a9af6a2bbd9
    };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
}
