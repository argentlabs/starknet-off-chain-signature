use array::{ArrayTrait, SpanTrait};
use starknet::{get_tx_info, get_caller_address};
use poseidon::PoseidonTrait;
use hash::{LegacyHash, HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v1::StarknetDomain};

const STRUCT_WITH_ARRAY_TYPE_HASH: felt252 =
    selector!("StructWithArray(some_felt252:felt,some_array:felt*)");

#[derive(Drop, Copy)]
struct StructWithArray {
    some_felt252: felt252,
    some_array: Span<felt252>
}


impl OffChainMessageHashStructWithArray of IOffChainMessageHash<StructWithArray> {
    fn get_message_hash(self: @StructWithArray) -> felt252 {
        let domain = StarknetDomain {
            name: 'dappName', version: '1', chain_id: get_tx_info().unbox().chain_id, revision: 1
        };
        let mut state = PoseidonTrait::new();
        state = state.update_with('StarkNet Message');
        state = state.update_with(domain.get_struct_hash());
        // This can be a field within the struct, it doesn't have to be get_caller_address().
        state = state.update_with(get_caller_address());
        state = state.update_with(self.get_struct_hash());
        state.finalize()
    }
}

impl StructHashStructWithArray of IStructHash<StructWithArray> {
    fn get_struct_hash(self: @StructWithArray) -> felt252 {
        let mut state = PoseidonTrait::new();
        state = state.update_with(STRUCT_WITH_ARRAY_TYPE_HASH);
        state = state.update_with(*self.some_felt252);
        state = state.update_with(self.some_array.get_struct_hash());
        state.finalize()
    }
}

impl StructHashSpanFelt252 of IStructHash<Span<felt252>> {
    fn get_struct_hash(self: @Span<felt252>) -> felt252 {
        let mut call_data_state = LegacyHash::hash(0, *self);
        call_data_state = LegacyHash::hash(call_data_state, (*self).len());
        call_data_state
    }
}

impl LegacyHashSpanFelt252 of LegacyHash<Span<felt252>> {
    fn hash(mut state: felt252, mut value: Span<felt252>) -> felt252 {
        loop {
            match value.pop_front() {
                Option::Some(item) => { state = LegacyHash::hash(state, *item); },
                Option::None(_) => { break state; },
            };
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{StructWithArray, IOffChainMessageHash};
    use starknet::testing::set_caller_address;
    #[test]
    fn test_valid_hash() {
        // This value was computed using StarknetJS
        let message_hash = 0x266b2350f2febce38581c6aa5b1afb829bb1466840400305fe51548ba32544e;
        let mut some_array = ArrayTrait::new();
        some_array.append(4);
        some_array.append(2);
        let simple_struct = StructWithArray { some_felt252: 712, some_array: some_array.span() };
        set_caller_address(420.try_into().unwrap());
        assert_eq!(simple_struct.get_message_hash(), message_hash);
    }
}
