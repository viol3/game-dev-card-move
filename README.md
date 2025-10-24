# Sui 101 - Introduction to Sui

During this module we will see how easy it is to interact with the Sui network.

Some common commands:

```zsh
# Creating a new keypair for the cli
sui client new-address <encryption-scheme> <name>

# Provides the link to the Sui faucet
sui client faucet

# Transfer object to different address
sui client transfer --to <new-owner> --object-id <object-identifier>

# Building the contracts
sui move build

# Publishing contracts
sui client publish
```

All the commands can be found in the [docs](https://docs.sui.io/references/cli/cheatsheet) or listed with:

```zsh
sui --help
```
