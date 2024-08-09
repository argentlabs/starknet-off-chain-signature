use starknet::{get_tx_info, get_caller_address};
use pedersen::PedersenTrait;
use hash::{HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v0::StarkNetDomain};

const SIMPLE_STRUCT_TYPE_HASH: felt252 =
    selector!("SimpleStruct(some_felt252:felt,some_u128:u128)");

#[derive(Drop, Copy, Hash)]
struct SimpleStruct {
    some_felt252: felt252,
    some_u128: u128,
}

impl OffChainMessageHashSimpleStruct of IOffChainMessageHash<SimpleStruct> {
    fn get_message_hash(self: @SimpleStruct) -> felt252 {
        let domain = StarkNetDomain {
            name: 'dappName', version: 1, chain_id: get_tx_info().unbox().chain_id
        };
        let mut state = PedersenTrait::new(0);
        state = state.update_with('StarkNet Message');
        state = state.update_with(domain.get_struct_hash());
        // This can be a field within the struct, it doesn't have to be get_caller_address().
        state = state.update_with(get_caller_address());
        state = state.update_with(self.get_struct_hash());
        // Hashing with the amount of elements being hashed
        state = state.update_with(4);
        state.finalize()
    }
}

impl StructHashSimpleStruct of IStructHash<SimpleStruct> {
    fn get_struct_hash(self: @SimpleStruct) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(SIMPLE_STRUCT_TYPE_HASH);
        state = state.update_with(*self);
        state = state.update_with(3);
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
        let message_hash = 0x1e739b39f83b38f182edaed69f730f18eff802d3ef44be91c3733cdcab6de2f;
        let simple_struct = SimpleStruct { some_felt252: 712, some_u128: 42 };
        set_caller_address(420.try_into().unwrap());
        assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
    }
}
