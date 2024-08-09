use starknet::{get_tx_info, get_caller_address};
use pedersen::PedersenTrait;
use hash::{HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v0::StarkNetDomain};

const STRUCT_WITH_U256_TYPE_HASH: felt252 =
    selector!("StructWithU256(some_felt252:felt,some_u256:u256)u256(low:felt,high:felt)");

const U256_TYPE_HASH: felt252 = selector!("u256(low:felt,high:felt)");

#[derive(Drop, Copy, Hash)]
struct StructWithU256 {
    some_felt252: felt252,
    some_u256: u256,
}

impl OffChainMessageHashStructWithU256 of IOffChainMessageHash<StructWithU256> {
    fn get_message_hash(self: @StructWithU256) -> felt252 {
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

impl StructHashStructWithU256 of IStructHash<StructWithU256> {
    fn get_struct_hash(self: @StructWithU256) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(STRUCT_WITH_U256_TYPE_HASH);
        state = state.update_with(*self.some_felt252);
        state = state.update_with(self.some_u256.get_struct_hash());
        state = state.update_with(3);
        state.finalize()
    }
}

impl StructHashU256 of IStructHash<u256> {
    fn get_struct_hash(self: @u256) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(U256_TYPE_HASH);
        state = state.update_with(*self);
        state = state.update_with(3);
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
        let message_hash = 0x24fcf47ecd5090d0dfd5e66a57e5d56d3db3478e37bb90c1b1351b4317197fd;
        let simple_struct = StructWithU256 { some_felt252: 712, some_u256: 42 };
        set_caller_address(420.try_into().unwrap());
        assert(simple_struct.get_message_hash() == message_hash, 'Hash should be valid');
    }
}
