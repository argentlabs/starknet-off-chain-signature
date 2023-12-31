use array::{ArrayTrait, SpanTrait};
use box::BoxTrait;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};
use pedersen::{PedersenTrait, HashState};
use hash::{LegacyHash, HashStateTrait, HashStateExTrait};

const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

const STRUCT_WITH_ARRAY_TYPE_HASH: felt252 =
    selector!("StructWithArray(some_felt252:felt,some_array:felt*)");

#[derive(Drop, Copy)]
struct StructWithArray {
    some_felt252: felt252,
    some_array: Span<felt252>
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

impl OffchainMessageHashStructWithArray of IOffchainMessageHash<StructWithArray> {
    fn get_message_hash(self: @StructWithArray) -> felt252 {
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

impl StructHashStructWithArray of IStructHash<StructWithArray> {
    fn hash_struct(self: @StructWithArray) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(STRUCT_WITH_ARRAY_TYPE_HASH);
        state = state.update_with(*self.some_felt252);
        state = state.update_with(self.some_array.hash_struct());
        state = state.update_with(3);
        state.finalize()
    }
}

impl StructHashSpanFelt252 of IStructHash<Span<felt252>> {
    fn hash_struct(self: @Span<felt252>) -> felt252 {
        let mut call_data_state = LegacyHash::hash(0, *self);
        call_data_state = LegacyHash::hash(call_data_state, (*self).len());
        call_data_state
    }
}

impl LegacyHashSpanFelt252 of LegacyHash<Span<felt252>> {
    fn hash(mut state: felt252, mut value: Span<felt252>) -> felt252 {
        loop {
            match value.pop_front() {
                Option::Some(item) => {
                    state = LegacyHash::hash(state, *item);
                },
                Option::None(_) => {
                    break state;
                },
            };
        }
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let message_hash = 0x266b2350f2febce38581c6aa5b1afb829bb1466840400305fe51548ba32544e;
    let mut some_array = ArrayTrait::new();
    some_array.append(4);
    some_array.append(2);
    let simple_struct = StructWithArray { some_felt252: 712, some_array: some_array.span() };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
}
