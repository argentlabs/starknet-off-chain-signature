# Offchain signature (à la EIP 712)

The purpose of this repository is NOT to establish a set of standard interfaces, but rather to present different cases and how to produce a hash that is compatible with StarknetJS. Although I tried to stay as close as possible to the terms used in [EIP-712](https://eips.ethereum.org/EIPS/eip-712) and in the [StarknetJS documentation](https://www.starknetjs.com/docs/guides/signature/#sign-and-verify-following-eip712)

Note that each file can be taken as a standalone, which is why there might be some code duplicates.  
The most simple case can be found [here](./src/simple_struct.cairo)

This repository is an appendix to the official discussion taking place on the official forum. Please start by reading it at this address:  
// TODO shamans link

## Future Compatibility 

Note that this implementation was done using compiler version 2.0.0.
It should be updated whenever 2.2.0 comes out. That version will include changes related to the **Hash trait** (cfr https://github.com/starkware-libs/cairo/commit/ad7f867ff1069d31103a3e3159308c392fa338db).
⚠️

## Array and Tuple

To hash an array or a tuple, just hash each of the elements starting from zero and, at last, add the length of that array.

## Struct (u256)

To hash a struct, you just first need to compute the hash from the struct: H('StructName(params1:type,...)'), then you update the state by adding each field of the struct and end with the amount of elements hashed.

## Enum

As the order of the Enum shouldn't matter, it isn't useful to take the index into consideration.
However, if you add a new member to an existing field, a different hash should be produced.
The hash computed by an enum is quite similar to the one of a struct: H('EnumName::EnumKind(type...)'), then update the state by adding each field of the tuple, and end with the amount of element hashed.

# Installation

**Prerequsite: Have scarb installed (or ASDF) and a package manager**
Check you have the correct version of Scarb installed by running:

```shell
scarb build
```

Install the modules using your favorite package manager:

```shell
yarn
```

Once this is done, you can run the scarb test to make sure it is correct:

```shell
scarb test
```

If you need to see the hash produced by StarknetJS refer to the [Scarb.tom file](./Scarb.toml):

```shell
scarb run simpleStruct
```

This should output everything you need to understand the related file

# License

This repository is released under the [MIT License](./LICENSE).
