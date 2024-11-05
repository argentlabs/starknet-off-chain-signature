use starknet::{get_tx_info, get_caller_address};
use poseidon::PoseidonTrait;
use hash::{HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v1::StarknetDomain};

const STRUCT_WITH_U256_TYPE_HASH: felt252 =
    selector!(
        "\"StructWithU256\"(\"Some felt252\":\"felt\",\"Some u256\":\"u256\")\"u256\"(\"low\":\"u128\",\"high\":\"u128\")"
    );

const U256_TYPE_HASH: felt252 = selector!("\"u256\"(\"low\":\"u128\",\"high\":\"u128\")");

#[derive(Drop, Copy, Hash)]
struct StructWithU256 {
    some_felt252: felt252,
    some_u256: u256,
}

impl OffChainMessageHashStructWithU256 of IOffChainMessageHash<StructWithU256> {
    fn get_message_hash(self: @StructWithU256) -> felt252 {
        let domain = StarknetDomain {
            name: 'dappName', version: '1', chain_id: get_tx_info().unbox().chain_id, revision: 1
        };
        let mut state = PoseidonTrait::new();
        state = state.update_with('StarkNet Message');
        state = state.update_with(domain.get_struct_hash());
        // This can be a field within the struct, it doesn't have to be get_caller_address().
        state = state.update_with(get_caller_address());
        state = state.update_with(self.get_struct_hash());
        // Hashing with the amount of elements being hashed
        state.finalize()
    }
}

impl StructHashStructWithU256 of IStructHash<StructWithU256> {
    fn get_struct_hash(self: @StructWithU256) -> felt252 {
        let mut state = PoseidonTrait::new();
        state = state.update_with(STRUCT_WITH_U256_TYPE_HASH);
        state = state.update_with(*self.some_felt252);
        state = state.update_with(self.some_u256.get_struct_hash());
        state.finalize()
    }
}

impl StructHashU256 of IStructHash<u256> {
    fn get_struct_hash(self: @u256) -> felt252 {
        let mut state = PoseidonTrait::new();
        state = state.update_with(U256_TYPE_HASH);
        state = state.update_with(*self);
        state.finalize()
    }
}

#[cfg(test)]
mod tests {
    use super::{StructWithU256, IOffChainMessageHash};
    use starknet::testing::set_caller_address;

    #[test]
    fn test_valid_hash() {
        // This value was computed using StarknetJS
        let message_hash = 0xb016dbeda9552a06b8fd446446aa2aa95fa887e72a0afeeac5b99567c60901;
        let simple_struct = StructWithU256 { some_felt252: 712, some_u256: 42 };
        set_caller_address(420.try_into().unwrap());
        assert_eq!(simple_struct.get_message_hash(), message_hash);
    }
}
