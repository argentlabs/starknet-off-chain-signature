use box::BoxTrait;
use hash::LegacyHash;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};

// sn_keccak('StarkNetDomain(name:felt,version:felt,chainId:felt)')
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    0x1bfc207425a47a5dfa1a50a4f5241203f50624ca5fdf5e18755765416b8e288;

// sn_keccak('StructWithU256(some_felt252:felt,some_u256:u256)u256(low:felt,high:felt)')                                                                          
const STRUCT_WITH_U256_TYPE_HASH: felt252 =
    0x35adf841dd9b75f25c756d57ff358ca550373f6b6043948ab6e34e958136016;

// sn_keccak('u256(low:felt,high:felt)')
const U256_TYPE_HASH: felt252 = 0x2ee86241508f9ca7043fb572033e45c445012a8dbb2b929391d37fc44fbfceb;

#[derive(Drop, Copy)]
struct StructWithU256 {
    some_felt252: felt252,
    some_u256: u256,
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

impl OffchainMessageHashStructWithU256 of IOffchainMessageHash<StructWithU256> {
    fn get_message_hash(self: @StructWithU256) -> felt252 {
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

impl StructHashStructWithU256 of IStructHash<StructWithU256> {
    fn hash_struct(self: @StructWithU256) -> felt252 {
        let mut state = LegacyHash::hash(0, STRUCT_WITH_U256_TYPE_HASH);
        state = LegacyHash::hash(state, *self.some_felt252);
        state = LegacyHash::hash(state, self.some_u256.hash_struct());
        state = LegacyHash::hash(state, 3);
        state
    }
}

impl StructHashU256 of IStructHash<u256> {
    fn hash_struct(self: @u256) -> felt252 {
        let mut state = LegacyHash::hash(0, U256_TYPE_HASH);
        state = LegacyHash::hash(state, *self.low);
        state = LegacyHash::hash(state, *self.high);
        state = LegacyHash::hash(state, 3);
        state
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let simple_struct_hashed = 0x24fcf47ecd5090d0dfd5e66a57e5d56d3db3478e37bb90c1b1351b4317197fd;
    let simple_struct = StructWithU256 { some_felt252: 712, some_u256: 42 };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == simple_struct_hashed, 'Hash should be valid');
}
