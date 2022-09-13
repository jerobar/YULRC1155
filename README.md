# YULRC1155

A basic implementation of the ERC1155 token standard written entirely in Yul!

Yul contract: `contracts/YULRC1155.yul`.

Testing:

```shell
npx hardhat test test/YULRC1155.test.js
```

Note that the test will automatically compile the contract bytecode if it does not already exist in `contracts/YULRC1155.bytecode.json`.
