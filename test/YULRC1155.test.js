const path = require('path')
const fs = require('fs')
const { getYULRC1155Bytecode } = require('./utils')
const {
  loadFixture,
  getStorageAt
} = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')

const URI = 'https://token-cdn-domain/{id}.json'
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
const DATA = '0x12345678'

/**
 * Fixture: Deploys `YULRC1155` contract from its abi and bytecode.
 */
async function deployYULRC1155Fixture() {
  const yulrc1155Abi = fs.readFileSync(
    path.resolve(__dirname, '..', 'contracts', 'YULRC1155.abi.json'),
    'utf8'
  )
  const yulrc1155Bytecode = await getYULRC1155Bytecode()
  const YULRC1155 = await ethers.getContractFactory(
    JSON.parse(yulrc1155Abi),
    yulrc1155Bytecode
  )
  const yulrc1155Contract = await YULRC1155.deploy(URI)

  return { yulrc1155Contract }
}

/**
 * Fixture: Deploys ERC1155Receiver `UnexpectedValue` contract.
 */
async function deployUnexpectedValueFixture() {
  const UnexpectedValue = await ethers.getContractFactory('UnexpectedValue')
  const unexpectedValueContract = await UnexpectedValue.deploy()

  return { unexpectedValueContract }
}

/**
 * Fixture: Deploys `ReceiverReverts` contract.
 */
async function deployReceiverRevertsFixture() {
  const ReceiverReverts = await ethers.getContractFactory('ReceiverReverts')
  const receiverRevertsContract = await ReceiverReverts.deploy()

  return { receiverRevertsContract }
}

/**
 * Fixture: Deploys `MissingFunction` contract.
 */
async function deployMissingFunctionFixture() {
  const MissingFunction = await ethers.getContractFactory('MissingFunction')
  const missingFunctionContract = await MissingFunction.deploy()

  return { missingFunctionContract }
}

/**
 * Fixture: Deploys `ERC1155Receiver` contract.
 */
async function deployERC1155ReceiverFixture() {
  const ERC1155Receiver = await ethers.getContractFactory('ERC1155Receiver')
  const erc1155ReceiverContract = await ERC1155Receiver.deploy()

  return { erc1155ReceiverContract }
}
// Hack: separate fixture function needed to avoid `FixtureSnapshotError` bug
async function deployERC1155ReceiverFixtureTwo() {
  const ERC1155Receiver = await ethers.getContractFactory('ERC1155Receiver')
  const erc1155ReceiverContract = await ERC1155Receiver.deploy()

  return { erc1155ReceiverContract }
}

/**
 * YULRC1155
 *
 * describes:
 * - uri
 * - balanceOf
 * - balanceOfBatch
 * - setApprovalForAll/isApprovedForAll
 * - safeTransferFrom
 * - safeBatchTransferFrom
 * - mint
 * - mintBatch
 * - burn
 * - burnBatch
 */
describe('YULRC1155', function () {
  /**
   * uri(uint256)
   *
   * it:
   * - sets the initial uri for all token types
   */
  describe('uri', function () {
    const tokenIdOne = 1
    const tokenIdTwo = 2

    it('sets the initial uri for all token types', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

      expect(await yulrc1155Contract.uri(tokenIdOne)).to.be.equal(URI)
      expect(await yulrc1155Contract.uri(tokenIdTwo)).to.be.equal(URI)
    })
  })

  /**
   * balanceOf(address account, uint256 id)
   *
   * it:
   * - reverts when queried about the zero address
   * - returns zero for addresses with no tokens
   * - returns the amount of tokens owned by the given addresses
   */
  describe('balanceOf', function () {
    const tokenId = 1990
    const mintAmount = 9001

    it('reverts when queried about the zero address', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

      await expect(yulrc1155Contract.balanceOf(ZERO_ADDRESS, tokenId)).to.be
        .reverted
    })

    it('returns zero for addresses with no tokens', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, nonTokenHolder] = await ethers.getSigners()

      expect(
        await yulrc1155Contract.balanceOf(nonTokenHolder.address, tokenId)
      ).to.equal(0)
    })

    it('returns the amount of tokens owned by the given addresses', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(mintAmount)
    })
  })

  /**
   * balanceOfBatch(address[] accounts, uint256[] ids)
   *
   * it:
   * - reverts when input arrays don't match up
   * - reverts when one of the addresses is the zero address
   * - returns zeros for each account with no tokens
   * - returns amounts owned by each account in order passed
   */
  describe('balanceOfBatch', function () {
    const tokenBatchIds = [2000, 2010, 2020]
    const mintAmounts = [5000, 10000, 42195]

    it("reverts when input arrays don't match up", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, signerOne, signerTwo, signerThree] = await ethers.getSigners()
      const accounts = [
        signerOne.address,
        signerTwo.address,
        signerThree.address
      ]

      await expect(
        yulrc1155Contract.balanceOfBatch(accounts.slice(1), tokenBatchIds)
      ).to.be.reverted

      await expect(
        yulrc1155Contract.balanceOfBatch(accounts, tokenBatchIds.slice(1))
      ).to.be.reverted
    })

    it('reverts when one of the addresses is the zero address', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, signerOne, signerTwo] = await ethers.getSigners()
      const accounts = [signerOne.address, ZERO_ADDRESS, signerTwo.address]

      await expect(yulrc1155Contract.balanceOfBatch(accounts, tokenBatchIds)).to
        .be.reverted
    })

    it('returns zeros for each account with no tokens', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, signerOne, signerTwo, signerThree] = await ethers.getSigners()
      const accounts = [
        signerOne.address,
        signerTwo.address,
        signerThree.address
      ]

      const holderBatchBalances = await yulrc1155Contract.balanceOfBatch(
        accounts,
        tokenBatchIds
      )

      for (let i = 0; i < holderBatchBalances.length; i++) {
        expect(holderBatchBalances[i]).to.equal(0)
      }
    })

    it('returns amounts owned by each account in order passed', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, signerOne, signerTwo, signerThree] = await ethers.getSigners()
      const accounts = [
        signerOne.address,
        signerTwo.address,
        signerThree.address
      ]
      const tokenId = 1

      // Mint tokens to each account
      for (let i = 0; i < accounts.length; i++) {
        const mintTx = await yulrc1155Contract.mint(
          accounts[i],
          tokenId,
          mintAmounts[i],
          DATA
        )
        await mintTx.wait(1)
      }

      // Confirm balanceOfBatch returns expected amounts
      const balances = await yulrc1155Contract.balanceOfBatch(accounts, [
        tokenId,
        tokenId,
        tokenId
      ])

      for (let i = 0; i < balances.length; i++) {
        expect(balances[i]).to.equal(mintAmounts[i])
      }
    })
  })

  /**
   * setApprovalForAll(address operator, bool approved)
   * isApprovedForAll(address account, address operator)
   *
   * it:
   * - reverts if attempting to approve self as an operator
   * - sets approval status which can be queried via isApprovedForAll
   * - can unset approval for an operator
   * - emits an ApprovalForAll log
   */
  describe('setApprovalForAll/isApprovedForAll', function () {
    it('reverts if attempting to approve self as an operator', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, approver] = await ethers.getSigners()

      await expect(
        yulrc1155Contract
          .connect(approver)
          .setApprovalForAll(approver.address, true)
      ).to.be.reverted
    })

    it('sets approval status which can be queried via isApprovedForAll', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, approver, operator] = await ethers.getSigners()

      // Confirm operator not yet approved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(false)

      // Approve operator
      const setApprovalForAllTx = await yulrc1155Contract
        .connect(approver)
        .setApprovalForAll(operator.address, true)
      await setApprovalForAllTx.wait(1)

      // Confirm operator now approved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(true)
    })

    it('can unset approval for an operator', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, approver, operator] = await ethers.getSigners()

      // Approve operator
      const setApprovalForAllTrueTx = await yulrc1155Contract
        .connect(approver)
        .setApprovalForAll(operator.address, true)
      await setApprovalForAllTrueTx.wait(1)

      // Confirm operator now approved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(true)

      // Disapprove operator
      const setApprovalForAllFalseTx = await yulrc1155Contract
        .connect(approver)
        .setApprovalForAll(operator.address, false)
      await setApprovalForAllFalseTx.wait(1)

      // Confirm operator now disapproved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(false)
    })

    it('emits an ApprovalForAll log', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, approver, operator] = await ethers.getSigners()

      await expect(
        await yulrc1155Contract
          .connect(approver)
          .setApprovalForAll(operator.address, true)
      )
        .to.emit(yulrc1155Contract, 'ApprovalForAll')
        .withArgs(approver.address, operator.address, true)
    })
  })

  /**
   * safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)
   *
   * it:
   * - reverts when transferring more than balance
   * - reverts when transferring to zero address
   * - reverts when operator is not approved by multiTokenHolder
   * - reverts when receiver contract returns unexpected value
   * - reverts when receiver contract reverts
   * - reverts when receiver does not implement the required function
   * - debits transferred balance from sender
   * - credits transferred balance to receiver
   * - preserves existing balances which are not transferred by multiTokenHolder
   * - succeeds when operator is approved by multiTokenHolder
   * - preserves operator's balances not involved in the transfer
   * - succeeds when calling onERC1155Received without data
   * - succeeds when calling onERC1155Received with data
   * - emits a TransferSingle log
   */
  describe.only('safeTransferFrom', function () {
    const tokenId = 1990
    const mintAmount = 9001

    it('reverts when transferring more than balance', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            tokenReceiver.address,
            tokenId,
            mintAmount + 1,
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when transferring to zero address', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            ZERO_ADDRESS,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when operator is not approved by multiTokenHolder', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenReceiver)
          .safeTransferFrom(
            tokenHolder.address,
            tokenReceiver.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when receiver contract returns unexpected value', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const { unexpectedValueContract } = await loadFixture(
        deployUnexpectedValueFixture
      )
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            unexpectedValueContract.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when receiver contract reverts', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const { receiverRevertsContract } = await loadFixture(
        deployReceiverRevertsFixture
      )
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            receiverRevertsContract.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when receiver does not implement the required function', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const { missingFunctionContract } = await loadFixture(
        deployMissingFunctionFixture
      )
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            missingFunctionContract.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted
    })

    it('debits transferred balance from sender', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      // Transfer 123 tokens to receiver
      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          123,
          DATA
        )
      await safeTransferFromTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(mintAmount - 123)
    })

    it('credits transferred balance to receiver', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      // Transfer 123 tokens to receiver
      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          123,
          DATA
        )
      await safeTransferFromTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenReceiver.address, tokenId)
      ).to.equal(123)
    })

    it('preserves existing balances which are not transferred by multiTokenHolder', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners()
      const tokenOneId = 123
      const tokenTwoId = 456

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenHolder.address,
        [tokenOneId, tokenTwoId],
        [mintAmount, mintAmount],
        DATA
      )
      await mintBatchTx.wait(1)

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenOneId,
          mintAmount,
          DATA
        )
      await safeTransferFromTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenTwoId)
      ).to.equal(mintAmount)
    })

    it('succeeds when operator is approved by multiTokenHolder', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenOperator, tokenReceiver] =
        await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      // Approve `tokenOperator` to transfer on behalf of `tokenHolder`
      const setApprovalForAllTx = await yulrc1155Contract
        .connect(tokenHolder)
        .setApprovalForAll(tokenOperator.address, true)
      await setApprovalForAllTx.wait(1)

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenOperator)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          mintAmount,
          DATA
        )
      await safeTransferFromTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(0)

      expect(
        await yulrc1155Contract.balanceOf(tokenReceiver.address, tokenId)
      ).to.equal(mintAmount)
    })

    it("preserves operator's balances not involved in the transfer", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenOperator, tokenReceiver] =
        await ethers.getSigners()

      const mintToTokenHolderTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintToTokenHolderTx.wait(1)

      const mintToOperatorTx = await yulrc1155Contract.mint(
        tokenOperator.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintToOperatorTx.wait(1)

      // Approve `tokenOperator` to transfer on behalf of `tokenHolder`
      const setApprovalForAllTx = await yulrc1155Contract
        .connect(tokenHolder)
        .setApprovalForAll(tokenOperator.address, true)
      await setApprovalForAllTx.wait(1)

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenOperator)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          mintAmount,
          DATA
        )
      await safeTransferFromTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(0)

      expect(
        await yulrc1155Contract.balanceOf(tokenReceiver.address, tokenId)
      ).to.equal(mintAmount)

      expect(
        await yulrc1155Contract.balanceOf(tokenOperator.address, tokenId)
      ).to.equal(mintAmount)
    })

    it('succeeds when calling onERC1155Received without data', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const { erc1155ReceiverContract } = await loadFixture(
        deployERC1155ReceiverFixture
      )
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          erc1155ReceiverContract.address,
          tokenId,
          mintAmount,
          '0x00'
        )
      await safeTransferFromTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(
          erc1155ReceiverContract.address,
          tokenId
        )
      ).to.equal(mintAmount)
    })

    it('succeeds when calling onERC1155Received with data', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const { erc1155ReceiverContract } = await loadFixture(
        deployERC1155ReceiverFixtureTwo
      )
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          erc1155ReceiverContract.address,
          tokenId,
          mintAmount,
          DATA
        )
      await safeTransferFromTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(
          erc1155ReceiverContract.address,
          tokenId
        )
      ).to.equal(mintAmount)
    })

    it('emits a TransferSingle log', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners()

      const mintToTokenHolderTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintToTokenHolderTx.wait(1)

      await expect(
        await yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            tokenReceiver.address,
            tokenId,
            mintAmount,
            DATA
          )
      )
        .to.emit(yulrc1155Contract, 'TransferSingle')
        .withArgs(
          tokenHolder.address,
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          mintAmount
        )
    })
  })

  /**
   * safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data)
   *
   * it:
   * - reverts when transferring amount more than any of balances
   * - reverts when ids array length doesn't match amounts array length
   * - reverts when transferring to zero address
   * - reverts when operator is not approved by multiTokenHolder
   * - reverts when receiver contract returns unexpected value
   * - reverts when receiver contract reverts
   * - reverts when receiver does not implement the required function
   * - debits transferred balances from sender
   * - credits transferred balances to receiver
   * - succeeds when operator is approved by multiTokenHolder
   * - preserves operator's balances not involved in the transfer
   * - succeeds when calling onERC1155Received without data
   * - succeeds when calling onERC1155Received with data
   * - succeeds when calling a receiver contract that reverts only on single transfers
   * - emits a TransferBatch log
   */
  describe('safeBatchTransferFrom', function () {
    const tokenBatchIds = [2000, 2010, 2020]
    const mintAmounts = [5000, 10000, 42195]

    it('reverts when transferring amount more than any of balances', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, tokenReceiver] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      await expect(
        yulrc1155Contract.connect(tokenBatchHolder).safeBatchTransferFrom(
          tokenBatchHolder.address,
          tokenReceiver.address,
          tokenBatchIds,
          // 10001 = 1 more than minted amount
          [5000, 10001, 42195],
          DATA
        )
      ).to.be.reverted
    })

    it("reverts when ids array length doesn't match amounts array length", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, tokenReceiver] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenBatchHolder)
          .safeBatchTransferFrom(
            tokenBatchHolder.address,
            tokenReceiver.address,
            tokenBatchIds.slice(1),
            mintAmounts,
            DATA
          )
      ).to.be.reverted

      await expect(
        yulrc1155Contract
          .connect(tokenBatchHolder)
          .safeBatchTransferFrom(
            tokenBatchHolder.address,
            tokenReceiver.address,
            tokenBatchIds,
            mintAmounts.slice(1),
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when transferring to zero address', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(tokenBatchHolder)
          .safeBatchTransferFrom(
            tokenBatchHolder.address,
            ZERO_ADDRESS,
            tokenBatchIds,
            mintAmounts,
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when operator is not approved by multiTokenHolder', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, operator, tokenReceiver] =
        await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(operator)
          .safeBatchTransferFrom(
            tokenBatchHolder.address,
            tokenReceiver.address,
            tokenBatchIds,
            mintAmounts,
            DATA
          )
      ).to.be.reverted
    })

    it('reverts when receiver contract returns unexpected value', async function () {
      console.log('to do')
    })

    it('reverts when receiver contract reverts', async function () {
      console.log('to do')
    })

    it('reverts when receiver does not implement the required function', async function () {
      console.log('to do')
    })

    it('debits transferred balances from sender', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, tokenReceiver] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      const transferBatchTx = await yulrc1155Contract
        .connect(tokenBatchHolder)
        .safeBatchTransferFrom(
          tokenBatchHolder.address,
          tokenReceiver.address,
          tokenBatchIds,
          mintAmounts,
          DATA
        )
      await transferBatchTx.wait(1)

      const holderBatchBalances = await yulrc1155Contract.balanceOfBatch(
        new Array(tokenBatchIds.length).fill(tokenBatchHolder.address),
        tokenBatchIds
      )

      for (let i = 0; i < holderBatchBalances.length; i++) {
        expect(holderBatchBalances[i]).to.be.bignumber.equal(0)
      }
    })

    it('credits transferred balances to receiver', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, tokenReceiver] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      const transferBatchTx = await yulrc1155Contract
        .connect(tokenBatchHolder)
        .safeBatchTransferFrom(
          tokenBatchHolder.address,
          tokenReceiver.address,
          tokenBatchIds,
          mintAmounts,
          DATA
        )
      await transferBatchTx.wait(1)

      const holderBatchBalances = await yulrc1155Contract.balanceOfBatch(
        new Array(tokenBatchIds.length).fill(tokenReceiver.address),
        tokenBatchIds
      )

      for (let i = 0; i < holderBatchBalances.length; i++) {
        expect(holderBatchBalances[i]).to.be.bignumber.equal(mintAmounts[i])
      }
    })

    it('succeeds when operator is approved by multiTokenHolder', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, operator, tokenReceiver] =
        await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      const setApprovalForAllTx = await yulrc1155Contract
        .connect(tokenBatchHolder)
        .setApprovalForAll(operator.address, true)
      await setApprovalForAllTx.wait(1)

      await expect(
        yulrc1155Contract
          .connect(operator)
          .safeBatchTransferFrom(
            tokenBatchHolder.address,
            tokenReceiver.address,
            tokenBatchIds,
            mintAmounts,
            DATA
          )
      ).to.not.be.reverted
    })

    it("preserves operator's balances not involved in the transfer", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, operator, tokenReceiver] =
        await ethers.getSigners()

      const mintBatchToTokenHolderTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchToTokenHolderTx.wait(1)

      const mintBatchToOperatorTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchToOperatorTx.wait(1)

      const setApprovalForAllTx = await yulrc1155Contract
        .connect(tokenBatchHolder)
        .setApprovalForAll(operator.address, true)
      await setApprovalForAllTx.wait(1)

      const safeBatchTransferFromTx = await yulrc1155Contract
        .connect(operator)
        .safeBatchTransferFrom(
          tokenBatchHolder.address,
          tokenReceiver.address,
          tokenBatchIds,
          mintAmounts,
          DATA
        )
      await safeBatchTransferFromTx.wait(1)

      const operatorBalances = await yulrc1155Contract.balanceOfBatch(
        new Array(tokenBatchIds.length).fill(operator.address),
        tokenBatchIds
      )

      for (let i = 0; i < operatorBalances.length; i++) {
        expect(operatorBalances[i]).to.be.bignumber.equal(mintAmounts[i])
      }
    })

    it('succeeds when calling onERC1155Received without data', async function () {
      console.log('to do')
    })

    it('succeeds when calling onERC1155Received with data', async function () {
      console.log('to do')
    })

    it('succeeds when calling a receiver contract that reverts only on single transfers', async function () {
      console.log('to do')
    })

    it('emits a TransferBatch log', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder, tokenReceiver] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      await expect(
        await yulrc1155Contract
          .connect(tokenBatchHolder)
          .safeBatchTransferFrom(
            tokenBatchHolder.address,
            tokenReceiver.address,
            tokenBatchIds,
            mintAmounts,
            DATA
          )
      )
        .to.emit(yulrc1155Contract, 'TransferBatch')
        .withArgs(
          tokenBatchHolder.address,
          tokenBatchHolder.address,
          tokenReceiver.address,
          tokenBatchIds,
          mintAmounts
        )
    })
  })

  /**
   * mint(address to, uint256 id, uint256 amount, bytes data)
   *
   * it:
   * - reverts with a zero destination address
   * - credits the minted amount of tokens
   * - emits a TransferSingle event
   */
  describe('mint', function () {
    const tokenId = 1990
    const mintAmount = 9001

    it('reverts with a zero destination address', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

      await expect(
        yulrc1155Contract.mint(ZERO_ADDRESS, tokenId, mintAmount, DATA)
      ).to.be.reverted
    })

    it('credits the minted amount of tokens', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(mintAmount)
    })

    it('emits a TransferSingle event', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [operator, tokenHolder] = await ethers.getSigners()

      await expect(
        await yulrc1155Contract.mint(
          tokenHolder.address,
          tokenId,
          mintAmount,
          DATA
        )
      )
        .to.emit(yulrc1155Contract, 'TransferSingle')
        .withArgs(
          operator.address,
          ZERO_ADDRESS,
          tokenHolder.address,
          tokenId,
          mintAmount
        )
    })
  })

  /**
   * mintBatch(address to, uint256[] ids, uint256[] amounts, bytes data)
   *
   * it:
   * - reverts with a zero destination address
   * - reverts if length of inputs do not match
   * - credits the minted batch of tokens
   * - emits a TransferBatch event
   */
  describe('mintBatch', function () {
    const tokenBatchIds = [2000, 2010, 2020]
    const mintAmounts = [5000, 10000, 42195]

    it('reverts with a zero destination address', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

      await expect(
        yulrc1155Contract.mintBatch(
          ZERO_ADDRESS,
          tokenBatchIds,
          mintAmounts,
          DATA
        )
      ).to.be.reverted
    })

    it('reverts if length of inputs do not match', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder] = await ethers.getSigners()

      await expect(
        yulrc1155Contract.mintBatch(
          tokenBatchHolder.address,
          tokenBatchIds,
          mintAmounts.slice(1),
          DATA
        )
      ).to.be.reverted

      await expect(
        yulrc1155Contract.mintBatch(
          tokenBatchHolder.address,
          tokenBatchIds.slice(1),
          mintAmounts,
          DATA
        )
      ).to.be.reverted
    })

    it('credits the minted batch of tokens', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      const holderBatchBalances = await yulrc1155Contract.balanceOfBatch(
        new Array(tokenBatchIds.length).fill(tokenBatchHolder.address),
        tokenBatchIds
      )

      for (let i = 0; i < holderBatchBalances.length; i++) {
        expect(holderBatchBalances[i]).to.be.bignumber.equal(mintAmounts[i])
      }
    })

    it('emits a TransferBatch event', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [operator, tokenBatchHolder] = await ethers.getSigners()

      await expect(
        await yulrc1155Contract.mintBatch(
          tokenBatchHolder.address,
          tokenBatchIds,
          mintAmounts,
          DATA
        )
      )
        .to.emit(yulrc1155Contract, 'TransferBatch')
        .withArgs(
          operator.address,
          ZERO_ADDRESS,
          tokenBatchHolder.address,
          tokenBatchIds,
          mintAmounts
        )
    })
  })

  /**
   * burn(address from, uint256 id, uint256 amount)
   *
   * it:
   * - reverts when burning the zero account's tokens
   * - reverts when burning a non-existent token id
   * - reverts when burning more than available tokens
   * - accounts for both minting and burning
   * - emits a TransferSingle event
   */
  describe('burn', function () {
    const tokenId = 1990
    const mintAmount = 9001
    const burnAmount = 3000

    it("reverts when burning the zero account's tokens", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

      await expect(yulrc1155Contract.burn(ZERO_ADDRESS, tokenId, burnAmount)).to
        .be.reverted
    })

    it('reverts when burning a non-existent token id', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder] = await ethers.getSigners()

      await expect(
        yulrc1155Contract.burn(tokenHolder.address, tokenId, burnAmount)
      ).to.be.reverted
    })

    it('reverts when burning more than available tokens', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        yulrc1155Contract.burn(tokenHolder.address, tokenId, mintAmount + 1)
      ).to.be.reverted
    })

    it('accounts for both minting and burning', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      const burnTx = await yulrc1155Contract.burn(
        tokenHolder.address,
        tokenId,
        burnAmount
      )
      await burnTx.wait(1)

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(mintAmount - burnAmount)
    })

    it('emits a TransferSingle event', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [operator, tokenHolder] = await ethers.getSigners()

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      )
      await mintTx.wait(1)

      await expect(
        await yulrc1155Contract.burn(tokenHolder.address, tokenId, burnAmount)
      )
        .to.emit(yulrc1155Contract, 'TransferSingle')
        .withArgs(
          operator.address,
          tokenHolder.address,
          ZERO_ADDRESS,
          tokenId,
          burnAmount
        )
    })
  })

  /**
   * burnBatch(address from, uint256[] ids, uint256[] amounts)
   *
   * it:
   * - reverts when burning the zero account's tokens
   * - reverts if length of inputs do not match
   * - reverts when burning a non-existent token id
   * - accounts for both minting and burning
   * - emits a TransferBatch event
   */
  describe('burnBatch', function () {
    const tokenBatchIds = [2000, 2010, 2020]
    const mintAmounts = [5000, 10000, 42195]
    const burnAmounts = [5000, 9001, 195]

    it("reverts when burning the zero account's tokens", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

      await expect(
        yulrc1155Contract.burnBatch(ZERO_ADDRESS, tokenBatchIds, burnAmounts)
      ).to.be.reverted
    })

    it('reverts if length of inputs do not match', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder] = await ethers.getSigners()

      await expect(
        yulrc1155Contract.burnBatch(
          tokenBatchHolder.address,
          tokenBatchIds,
          burnAmounts.slice(1)
        )
      ).to.be.reverted

      await expect(
        yulrc1155Contract.burnBatch(
          tokenBatchHolder.address,
          tokenBatchIds.slice(1),
          burnAmounts
        )
      ).to.be.reverted
    })

    it('reverts when burning a non-existent token id', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder] = await ethers.getSigners()

      await expect(
        yulrc1155Contract.burnBatch(
          tokenBatchHolder.address,
          tokenBatchIds,
          burnAmounts
        )
      ).to.be.reverted
    })

    it('accounts for both minting and burning', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [_, tokenBatchHolder] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      const burnBatchTx = await yulrc1155Contract.burnBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        burnAmounts
      )
      await burnBatchTx.wait(1)

      const holderBatchBalances = await yulrc1155Contract.balanceOfBatch(
        new Array(tokenBatchIds.length).fill(tokenBatchHolder.address),
        tokenBatchIds
      )

      for (let i = 0; i < holderBatchBalances.length; i++) {
        expect(holderBatchBalances[i]).to.be.bignumber.equal(
          mintAmounts[i].sub(burnAmounts[i])
        )
      }
    })

    it('emits a TransferBatch event', async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)
      const [operator, tokenBatchHolder] = await ethers.getSigners()

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenBatchHolder.address,
        tokenBatchIds,
        mintAmounts,
        DATA
      )
      await mintBatchTx.wait(1)

      await expect(
        yulrc1155Contract.burnBatch(
          tokenBatchHolder.address,
          tokenBatchIds,
          burnAmounts
        )
      )
        .to.emit(yulrc1155Contract, 'TransferBatch')
        .withArgs(
          operator.address,
          tokenBatchHolder.address,
          ZERO_ADDRESS,
          tokenBatchIds,
          burnAmounts
        )
    })
  })
})
