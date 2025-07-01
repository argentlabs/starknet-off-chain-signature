/// Reference to SNIP-12: https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-12.md

/// @notice Defines the function to generate the SNIP-12
pub trait IOffChainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

/// @notice Defines the function to generates the SNIP-12
pub trait IStructHash<T> {
    fn get_struct_hash(self: @T) -> felt252;
}

pub mod v1 {
    use core::poseidon::poseidon_hash_span;

    /// @notice StarknetDomain using SNIP 12
    #[derive(Hash, Drop, Copy)]
    pub struct StarknetDomain {
        pub name: felt252,
        pub version: felt252,
        pub chain_id: felt252,
        pub revision: felt252,
    }

    const STARKNET_DOMAIN_TYPE_HASH: felt252 = selector!(
        "\"StarknetDomain\"(\"name\":\"shortstring\",\"version\":\"shortstring\",\"chainId\":\"shortstring\",\"revision\":\"shortstring\")",
    );

    impl StructHashStarknetDomain of super::IStructHash<StarknetDomain> {
        fn get_struct_hash(self: @StarknetDomain) -> felt252 {
            poseidon_hash_span(
                array![
                    STARKNET_DOMAIN_TYPE_HASH,
                    *self.name,
                    *self.version,
                    *self.chain_id,
                    *self.revision,
                ]
                    .span(),
            )
        }
    }
}
