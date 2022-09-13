const fs = require('fs')
const path = require('path')
const solc = require('solc')

/**
 * Compiles `YULRC1155.yul`, writes a new `YULRC1155.bytecode.json` file, and
 * returns the contract bytecode.
 */
async function compileYULRC1155() {
  const input = {
    language: 'Yul',
    sources: {
      'YULRC1155.yul': {
        content: fs.readFileSync(
          path.resolve(__dirname, '..', 'contracts', 'YULRC1155.yul'),
          'utf8'
        )
      }
    },
    settings: {
      outputSelection: {
        '*': {
          '*': ['*']
        }
      }
    }
  }
  const output = solc.compile(JSON.stringify(input))
  const bytecode =
    JSON.parse(output).contracts['YULRC1155.yul'].YULRC1155.evm.bytecode

  // Write a new `YULRC1155.bytecode.json` file
  fs.writeFile(
    path.resolve(__dirname, '..', 'contracts', 'YULRC1155.bytecode.json'),
    JSON.stringify(bytecode),
    (err) => {
      if (err) console.error(err)
    }
  )

  return bytecode.object
}

/**
 * Returns YULRC1155 bytecode. Source is either `YULRC1155.bytecode.json` file
 * or the result of solc compilation.
 */
async function getYULRC1155Bytecode() {
  const bytecodePath = path.resolve(
    __dirname,
    '..',
    'contracts',
    'YULRC1155.bytecode.json'
  )
  let bytecode

  // If bytecode file exists in contracts/ dir
  if (fs.existsSync(bytecodePath)) {
    const bytecodeJson = fs.readFileSync(bytecodePath)

    bytecode = JSON.parse(bytecodeJson).object
  } else {
    // If bytecode file does not exist
    bytecode = compileYULRC1155()
  }

  return bytecode
}

module.exports = {
  getYULRC1155Bytecode
}
