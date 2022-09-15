# YULRC1155

A basic implementation of the ERC1155 token standard written entirely in Yul!

Yul contract: `contracts/YULRC1155.yul`.

Testing:

```shell
npx hardhat test test/YULRC1155.test.js
```

Note that the test will automatically compile the contract bytecode if it does not already exist in `contracts/YULRC1155.bytecode.json`.

```shell
  YULRC1155
    uri
      ✔ sets the initial uri for all token types (7866ms)
    balanceOf
      ✔ reverts when queried about the zero address
      ✔ returns zero for addresses with no tokens
      ✔ returns the amount of tokens owned by the given addresses (55ms)
    balanceOfBatch
      ✔ reverts when input arrays don't match up (51ms)
      ✔ reverts when one of the addresses is the zero address
      ✔ returns zeros for each account with no tokens
      ✔ returns amounts owned by each account in order passed (98ms)
    setApprovalForAll/isApprovedForAll
      ✔ reverts if attempting to approve self as an operator
      ✔ sets approval status which can be queried via isApprovedForAll (52ms)
      ✔ can unset approval for an operator (61ms)
      ✔ emits an ApprovalForAll log
    safeTransferFrom
      ✔ reverts when transferring more than balance (47ms)
      ✔ reverts when transferring to zero address (45ms)
      ✔ reverts when operator is not approved by multiTokenHolder
      ✔ reverts when receiver contract returns unexpected value (79ms)
      ✔ reverts when receiver contract reverts (74ms)
      ✔ reverts when receiver does not implement the required function (65ms)
      ✔ debits transferred balance from sender (46ms)
      ✔ credits transferred balance to receiver (47ms)
      ✔ preserves existing balances which are not transferred by multiTokenHolder (67ms)
      ✔ succeeds when operator is approved by multiTokenHolder (87ms)
      ✔ preserves operator's balances not involved in the transfer (89ms)
      ✔ succeeds when calling onERC1155Received without data (69ms)
      ✔ succeeds when calling onERC1155Received with data (82ms)
      ✔ emits a TransferSingle log (47ms)
    safeBatchTransferFrom
      ✔ reverts when transferring amount more than any of balances (52ms)
      ✔ reverts when ids array length doesn't match amounts array length (50ms)
      ✔ reverts when transferring to zero address (42ms)
      ✔ reverts when operator is not approved by multiTokenHolder (42ms)
      ✔ reverts when receiver contract returns unexpected value (78ms)
      ✔ reverts when receiver contract reverts (82ms)
      ✔ reverts when receiver does not implement the required function (78ms)
      ✔ debits transferred balances from sender (75ms)
      ✔ credits transferred balances to receiver (77ms)
      ✔ succeeds when operator is approved by multiTokenHolder (83ms)
      ✔ preserves operator's balances not involved in the transfer (112ms)
      ✔ succeeds when calling onERC1155Received without data (103ms)
      ✔ succeeds when calling onERC1155Received with data (100ms)
      ✔ succeeds when calling a receiver contract that reverts only on single transfers (85ms)
      ✔ emits a TransferBatch log (81ms)
    mint
      ✔ reverts with a zero destination address
      ✔ credits the minted amount of tokens
      ✔ emits a TransferSingle event
    mintBatch
      ✔ reverts with a zero destination address
      ✔ reverts if length of inputs do not match
      ✔ credits the minted batch of tokens (38ms)
      ✔ emits a TransferBatch event
    burn
      ✔ reverts when burning the zero account's tokens
      ✔ reverts when burning a non-existent token id
      ✔ reverts when burning more than available tokens
      ✔ accounts for both minting and burning
      ✔ emits a TransferSingle event
    burnBatch
      ✔ reverts when burning the zero account's tokens
      ✔ reverts if length of inputs do not match
      ✔ reverts when burning a non-existent token id
      ✔ accounts for both minting and burning (64ms)
      ✔ emits a TransferBatch event (43ms)


  58 passing (11s)
```
