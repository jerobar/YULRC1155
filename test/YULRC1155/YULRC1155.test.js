/**
 * @todo
 *
 * - Add revert messages, revertsWith checks
 * - Add `data` arg to mint functions?
 * - ERC1155MetadataURI functionality
 * -
 */
const fs = require('fs')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')

describe('YULRC1155', function () {
  async function deployYULRC1155Fixture() {
    const [operator, tokenHolder, tokenBatchHolder, ...others] =
      await ethers.getSigners()

    const yulrc1155Abi = fs.readFileSync(
      `/home/jerobar/Projects/yulrc1155/test/YULRC1155/YULRC1155.abi.json`,
      'utf8'
    )
    const yulrc1155Bytecode = fs.readFileSync(
      `/home/jerobar/Projects/yulrc1155/test/YULRC1155/YULRC1155.bytecode.json`,
      'utf8'
    )
    const YULRC1155 = await ethers.getContractFactory(
      JSON.parse(yulrc1155Abi),
      JSON.parse(yulrc1155Bytecode).object
    )
    const yulrc1155Contract = await YULRC1155.deploy()

    return { operator, tokenHolder, tokenBatchHolder, yulrc1155Contract }
  }

  describe('internal functions', function () {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
    const tokenId = 1990
    const mintAmount = 9001
    const burnAmount = 3000

    const tokenBatchIds = [2000, 2010, 2020]
    const mintAmounts = [5000, 10000, 42195]
    const burnAmounts = [5000, 9001, 195]

    const data = '0x12345678'

    describe('_mint', function () {
      it('reverts with a zero destination address', async function () {
        const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

        await expect(yulrc1155Contract.mint(ZERO_ADDRESS, tokenId, mintAmount))
          .to.be.reverted
      })

      context('with minted tokens', function () {
        it('emits a TransferSingle event', async function () {
          const { tokenHolder, operator, yulrc1155Contract } =
            await loadFixture(deployYULRC1155Fixture)

          // Mint `mintAmount` of `tokenId` to token holder address
          // const mintTx = await yulrc1155Contract.mint(
          //   tokenHolder.address,
          //   tokenId,
          //   mintAmount
          // )
          // await mintTx.wait(1)

          // Expect a `TransferSingle` event with appropriate args
          await expect(
            await yulrc1155Contract.mint(
              tokenHolder.address,
              tokenId,
              mintAmount
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

        it('credits the minted amount of tokens', async function () {
          const { tokenHolder, yulrc1155Contract } = await loadFixture(
            deployYULRC1155Fixture
          )

          // Mint `mintAmount` of `tokenId` to token holder address
          const mintTx = await yulrc1155Contract.mint(
            tokenHolder.address,
            tokenId,
            mintAmount
          )
          await mintTx.wait(1)

          // Expect token holder's `tokenId` balance to reflect the mint
          expect(
            await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
          ).to.equal(mintAmount)
        })
      })
    })

    describe('_mintBatch', function () {
      it('reverts with a zero destination address', async function () {
        const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

        await expect(
          yulrc1155Contract.mintBatch(ZERO_ADDRESS, tokenBatchIds, mintAmounts)
        ).to.be.reverted
      })

      it('reverts if length of inputs do not match', async function () {
        const { yulrc1155Contract, tokenBatchHolder } = await loadFixture(
          deployYULRC1155Fixture
        )

        await expect(
          yulrc1155Contract.mintBatch(
            tokenBatchHolder.address,
            tokenBatchIds,
            mintAmounts.slice(1)
          )
        ).to.be.reverted

        await expect(
          yulrc1155Contract.mintBatch(
            tokenBatchHolder.address,
            tokenBatchIds.slice(1),
            mintAmounts
          )
        ).to.be.reverted
      })

      context('with minted batch of tokens', function () {
        // beforeEach(async function () {
        //   this.receipt = await this.token.mintBatch(
        //     tokenBatchHolder,
        //     tokenBatchIds,
        //     mintAmounts,
        //     data,
        //     { from: operator }
        //   )
        // })

        it('emits a TransferBatch event', async function () {
          const { yulrc1155Contract, operator, tokenBatchHolder } =
            await loadFixture(deployYULRC1155Fixture)

          // Expect a `TransferBatch` event with appropriate args
          await expect(
            await yulrc1155Contract
              .connect(operator)
              .mintBatch(tokenBatchHolder.address, tokenBatchIds, mintAmounts)
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

        it('credits the minted batch of tokens', async function () {
          const { yulrc1155Contract, tokenBatchHolder } = await loadFixture(
            deployYULRC1155Fixture
          )

          const mintBatchTx = await yulrc1155Contract.mintBatch(
            tokenBatchHolder.address,
            tokenBatchIds,
            mintAmounts
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
      })
    })

    describe('_burn', function () {
      it("reverts when burning the zero account's tokens", async function () {
        const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

        await expect(yulrc1155Contract.burn(ZERO_ADDRESS, tokenId, mintAmount))
          .to.be.reverted
      })

      it('reverts when burning a non-existent token id', async function () {
        const { yulrc1155Contract, tokenHolder } = await loadFixture(
          deployYULRC1155Fixture
        )

        await expect(
          yulrc1155Contract.burn(tokenHolder.address, tokenId, mintAmount)
        ).to.be.reverted
      })

      it('reverts when burning more than available tokens', async function () {
        const { yulrc1155Contract, tokenHolder } = await loadFixture(
          deployYULRC1155Fixture
        )

        const mintTx = await yulrc1155Contract.mint(tokenHolder.address, 1, 1)
        await mintTx.wait(1)

        await expect(yulrc1155Contract.burn(tokenHolder.address, 1, 2)).to.be
          .reverted
      })

      context('with minted-then-burnt tokens', function () {
        // beforeEach(async function () {
        //   await this.token.mint(tokenHolder, tokenId, mintAmount, data)
        //   this.receipt = await this.token.burn(
        //     tokenHolder,
        //     tokenId,
        //     burnAmount,
        //     { from: operator }
        //   )
        // })

        it('emits a TransferSingle event', async function () {
          const { yulrc1155Contract, operator, tokenHolder } =
            await loadFixture(deployYULRC1155Fixture)

          // Mint `mintAmount` of `tokenId` to token holder address
          const mintTx = await yulrc1155Contract.mint(
            tokenHolder.address,
            tokenId,
            mintAmount
          )
          await mintTx.wait(1)

          // Expect a `TransferSingle` event with appropriate args
          await expect(
            await yulrc1155Contract.burn(
              tokenHolder.address,
              tokenId,
              burnAmount
            )
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

        it('accounts for both minting and burning', async function () {
          const { yulrc1155Contract, tokenHolder } = await loadFixture(
            deployYULRC1155Fixture
          )

          // Mint `mintAmount` of `tokenId` to token holder address
          const mintTx = await yulrc1155Contract.mint(
            tokenHolder.address,
            tokenId,
            mintAmount
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
      })
    })

    describe('_burnBatch', function () {
      it("reverts when burning the zero account's tokens", async function () {
        const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture)

        await expect(
          yulrc1155Contract.burnBatch(ZERO_ADDRESS, tokenBatchIds, burnAmounts)
        ).to.be.reverted
      })

      it('reverts if length of inputs do not match', async function () {
        const { yulrc1155Contract, tokenBatchHolder } = await loadFixture(
          deployYULRC1155Fixture
        )

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
        const { yulrc1155Contract, tokenBatchHolder } = await loadFixture(
          deployYULRC1155Fixture
        )

        await expect(
          yulrc1155Contract.burnBatch(
            tokenBatchHolder.address,
            tokenBatchIds,
            burnAmounts
          )
        ).to.be.reverted
      })

      context('with minted-then-burnt tokens', function () {
        it('emits a TransferBatch event', async function () {
          const { yulrc1155Contract, operator, tokenBatchHolder } =
            await loadFixture(deployYULRC1155Fixture)

          const mintBatchTx = await yulrc1155Contract.mintBatch(
            tokenBatchHolder.address,
            tokenBatchIds,
            mintAmounts
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

        it('accounts for both minting and burning', async function () {
          const { yulrc1155Contract, tokenBatchHolder } = await loadFixture(
            deployYULRC1155Fixture
          )

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
      })
    })
  })

  // describe('ERC1155MetadataURI', function () {
  //   const firstTokenID = new BN('42')
  //   const secondTokenID = new BN('1337')

  //   it('emits no URI event in constructor', async function () {
  //     await expectEvent.notEmitted.inConstruction(this.token, 'URI')
  //   })

  //   it('sets the initial URI for all token types', async function () {
  //     expect(await this.token.uri(firstTokenID)).to.be.equal(initialURI)
  //     expect(await this.token.uri(secondTokenID)).to.be.equal(initialURI)
  //   })

  //   describe('_setURI', function () {
  //     const newURI = 'https://token-cdn-domain/{locale}/{id}.json'

  //     it('emits no URI event', async function () {
  //       const receipt = await this.token.setURI(newURI)

  //       expectEvent.notEmitted(receipt, 'URI')
  //     })

  //     it('sets the new URI for all token types', async function () {
  //       await this.token.setURI(newURI)

  //       expect(await this.token.uri(firstTokenID)).to.be.equal(newURI)
  //       expect(await this.token.uri(secondTokenID)).to.be.equal(newURI)
  //     })
  //   })
  // })
})
