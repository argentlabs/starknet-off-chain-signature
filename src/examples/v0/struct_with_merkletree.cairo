use starknet::{get_tx_info, get_caller_address};
use pedersen::PedersenTrait;
use hash::{HashStateTrait, HashStateExTrait};
use off_chain_signature::interfaces::{IOffChainMessageHash, IStructHash, v0::StarkNetDomain};

const STRUCT_WITH_MERKLETREE_TYPE_HASH: felt252 =
    selector!("StructWithMerkletree(some_felt252:felt,some_merkletree_root:merkletree)");

#[derive(Drop, Copy, Hash)]
struct StructWithMerkletree {
    some_felt252: felt252,
    some_merkletree_root: felt252,
}

impl OffChainMessageHashStructWithMerkletree of IOffChainMessageHash<StructWithMerkletree> {
    fn get_message_hash(self: @StructWithMerkletree) -> felt252 {
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

impl StructHashStructWithMerkletree of IStructHash<StructWithMerkletree> {
    fn get_struct_hash(self: @StructWithMerkletree) -> felt252 {
        let mut state = PedersenTrait::new(0);
        state = state.update_with(STRUCT_WITH_MERKLETREE_TYPE_HASH);
        state = state.update_with(*self);
        state = state.update_with(3);
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
        let message_hash = 0x4e4aa6e92e1250e5277a99686aa17c411b28b83fc948df78c10f848f1b0ad30;
        let simple_struct = StructWithMerkletree {
            some_felt252: 712,
            some_merkletree_root: 0x1e3fb24d6eeb2fdf4308dd358adfb0169dcdb21b3c6bac8ca223a9af6a2bbd9
        };
        set_caller_address(420.try_into().unwrap());
        assert_eq!(simple_struct.get_message_hash(), message_hash);
    }
}
