# Off-chain signature (à la EIP 712)

This repository is an appendix to the official discussion taking place on the official forum. Please start by reading it at this address:
https://community.starknet.io/t/snip-off-chain-signatures-a-la-eip712
This repository might not be up-to-date, which is why, in doubt, always refer to the official discussion and feel free to open an Issue/PR.

The purpose of this repository is NOT to establish a set of standard interfaces but rather to present different cases and how to produce a hash that is compatible with StarknetJS. Although I tried to stay as close as possible to the terms used in [EIP-712](https://eips.ethereum.org/EIPS/eip-712) and in the [StarknetJS documentation](https://www.starknetjs.com/docs/guides/signature/#sign-and-verify-following-eip712)

Note that each file can be taken as a standalone, which is why there some code is duplicated.
The most simple case can be found [here](./src/simple_struct.cairo)

# Installation

**Prerequisite: Have scarb installed through ASDF, a package manager, and node version <20**  
Check that you have the correct version of Scarb installed by running:

```shell
scarb build
```

Install the modules:

```shell
yarn
```

Once this is done, you can run the scarb test to make sure it is correct.

```shell
scarb test
```

If you need to see the hash produced by StarknetJS, refer to the [Scarb.tom file](./Scarb.toml):

```shell
scarb run SimpleStruct
```
# License

This repository is released under the [MIT License](./LICENSE).
