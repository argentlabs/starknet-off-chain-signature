use starknet::{get_tx_info, get_caller_address};
use poseidon::PoseidonTrait;
use hash::{HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v1::StarknetDomain};

const SIMPLE_STRUCT_TYPE_HASH: felt252 =
    selector!("\"SimpleStruct\"(\"some_felt252\":\"felt\",\"some_u128\":\"u128\")");

#[derive(Drop, Copy, Hash)]
struct SimpleStruct {
    some_felt252: felt252,
    some_u128: u128,
}

impl OffChainMessageHashSimpleStruct of IOffChainMessageHash<SimpleStruct> {
    fn get_message_hash(self: @SimpleStruct) -> felt252 {
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

impl StructHashSimpleStruct of IStructHash<SimpleStruct> {
    fn get_struct_hash(self: @SimpleStruct) -> felt252 {
        let mut state = PoseidonTrait::new();
        state = state.update_with(SIMPLE_STRUCT_TYPE_HASH);
        state = state.update_with(*self);
        state.finalize()
    }
}

#[cfg(test)]
mod tests {
    use super::{SimpleStruct, IOffChainMessageHash};
    use starknet::testing::set_caller_address;
    #[test]
    fn test_valid_hash() {
        // This value was computed using StarknetJS
        let message_hash = 0x31f29d7fd9a54a5ad9219280638b91734ad8344ed46440bab683e0a3ba9b5f;
        let simple_struct = SimpleStruct { some_felt252: 712, some_u128: 42 };
        set_caller_address(420.try_into().unwrap());
        assert_eq!(simple_struct.get_message_hash(), message_hash);
    }
}