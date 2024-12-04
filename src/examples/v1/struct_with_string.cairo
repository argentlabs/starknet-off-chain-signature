use starknet::{get_tx_info, get_caller_address};
use poseidon::PoseidonTrait;
use hash::{HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v1::StarknetDomain};

const STRUCT_WITH_U256_TYPE_HASH: felt252 =
    selector!("\"StructWithString\"(\"Some felt252\":\"felt\",\"Some string\":\"string\")");

#[derive(Drop)]
struct StructWithString {
    some_felt252: felt252,
    some_string: ByteArray,
}

impl OffChainMessageHashStructWithString of IOffChainMessageHash<StructWithString> {
    fn get_message_hash(self: @StructWithString) -> felt252 {
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

impl StructHashStructWithString of IStructHash<StructWithString> {
    fn get_struct_hash(self: @StructWithString) -> felt252 {
        let mut state = PoseidonTrait::new();
        state = state.update_with(STRUCT_WITH_U256_TYPE_HASH);
        state = state.update_with(*self.some_felt252);
        state = state.update_with(self.some_string.get_struct_hash());
        state.finalize()
    }
}

impl StructHashU256 of IStructHash<ByteArray> {
    fn get_struct_hash(self: @ByteArray) -> felt252 {
        let mut state = PoseidonTrait::new();
        let mut output = array![];
        Serde::serialize(self, ref output);
        for e in output.span() {
            state = state.update_with(*e);
        };
        state.finalize()
    }
}

#[cfg(test)]
mod tests {
    use super::{StructWithString, IOffChainMessageHash};
    use starknet::testing::set_caller_address;

    #[test]
    fn test_valid_hash() {
        // This value was computed using StarknetJS
        let message_hash = 0x73af00bf71d41fb165a48b8813cfa1ca29c429324ebbf5ffc732793ecfd8586;
        let simple_struct = StructWithString {
            some_felt252: 712, some_string: "Some long message that exceeds 31 characters"
        };
        set_caller_address(420.try_into().unwrap());
        assert_eq!(simple_struct.get_message_hash(), message_hash);
    }
}
