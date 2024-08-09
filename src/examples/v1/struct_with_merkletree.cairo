use starknet::{get_tx_info, get_caller_address};
use poseidon::PoseidonTrait;
use hash::{HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v1::StarknetDomain};

const STRUCT_WITH_MERKLETREE_TYPE_HASH: felt252 =
    selector!(
        "\"StructWithMerkletree\"(\"some_felt252\":\"felt\",\"some_merkletree_root\":\"merkletree\")"
    );

#[derive(Drop, Copy, Hash)]
struct StructWithMerkletree {
    some_felt252: felt252,
    some_merkletree_root: felt252,
}

impl OffChainMessageHashStructWithMerkletree of IOffChainMessageHash<StructWithMerkletree> {
    fn get_message_hash(self: @StructWithMerkletree) -> felt252 {
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

impl StructHashStructWithMerkletree of IStructHash<StructWithMerkletree> {
    fn get_struct_hash(self: @StructWithMerkletree) -> felt252 {
        let mut state = PoseidonTrait::new();
        state = state.update_with(STRUCT_WITH_MERKLETREE_TYPE_HASH);
        state = state.update_with(*self);
        state.finalize()
    }
}

#[cfg(test)]
mod tests {
    use super::{StructWithMerkletree, IOffChainMessageHash};
    use starknet::testing::set_caller_address;
    #[test]
    fn test_valid_hash() {
        // This value was computed using StarknetJS
        let message_hash = 0x2a89d9f00b3ead36ea204b956bc9ac862a5e7e0f2ad2bf790322dda9690629e;
        let simple_struct = StructWithMerkletree {
            some_felt252: 712,
            some_merkletree_root: 0x12cee444dbe3866ab527d0b89fa884d2f21b6eca0f2dfd8ecd73cb3d7297edc
        };
        set_caller_address(420.try_into().unwrap());
        assert_eq!(simple_struct.get_message_hash(), message_hash);
    }
}
