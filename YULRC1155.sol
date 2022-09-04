/**
 * YULRC1155
 * 
 * An implementation of the ERC1155 token standard written entirely in Yul.
 */
object "YULRC1155" {

    code {
        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {

        code {
            /**
             * Storage slots
             */
            // 0: mapping uint256 tokenID => (address account => uint256 balance)
            function balancesSlot() -> slot { slot := 0 }

            // 1: mapping address account => (address operator => bool approved)
            function operatorApprovalsSlot() -> slot { slot := 1 }

            /**
             * Dispatcher
             * 
             * Dispatches to relevant function based on (calldata) function 
             * selector (the first 4 bytes of keccak256(functionSignature)).
             */
            switch functionSelector()
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            // balanceOfBatch(address[],uint256[])
            case 0x4e1273f4 {
                // returnUintArray(decodeAsAddressArray(0), decodeAsUintArray(1))
            }
            // setApprovalForAll(address,bool)
            case 0xa22cb465 {
                setApprovalForAll(decodeAsAddress(0), decodeAsBool(1))
            }
            // isApprovedForAll(address,address)
            case 0xe985e9c5 {
                returnBool(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
            }
            // safeTransferFrom(address,address,uint256,uint256,bytes)
            case 0xf242432a {
                // safeTransferFrom(
                //     decodeAsAddress(0), 
                //     decodeAsAddress(1), 
                //     decodeAsUint(2), 
                //     decodeAsUint(3), 
                //     decodeAsBytes(4)
                // )
            }
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            case 0x2eb2c2d6 {
                // safeBatchTransferFrom(
                //     decodeAsAddressArray(0), 
                //     decodeAsAddressArray(1), 
                //     decodeAsUintArray(2), 
                //     decodeAsUintArray(3), 
                //     decodeAsBytes(4)
                // )
            }
            // mint(address,uint256,uint256)
            case 0x156e29f6 {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            default {
                revert(0, 0)
            }

            /**
             * ERC1155 functions
             */
            function getAccountBalanceLocation(account, id) -> balanceLocation {
                // Balances: mapping uint256 tokenID => (address account => uint256 balance)
                
                // Hash `id` and `balancesSlot()`
                let hashOfIdandBalancesSlot := keccakHashTwoValues(id, balancesSlot())

                // `balanceLocation` = keccak256(`account`, keccak256(`id`, `balancesSlot()`))
                balanceLocation := keccakHashTwoValues(account, hashOfIdandBalancesSlot)
            }
            function balanceOf(account, id) -> accountBalance {
                let balanceLocation := getAccountBalanceLocation(account, id)
                accountBalance := sload(balanceLocation)
            }
            function balanceOfBatch(accounts, ids) -> accountBalanceArray {

            }
            function setApprovalForAll(operator, approved) {
                // isApproved := approved
            }
            function isApprovedForAll(account, operator) -> isApproved {
                isApproved := 1
            }
            function safeTransferFrom(from, to, id, amount, data) {

            }
            function safeBatchTransferFrom(from, to, ids, amounts, data) {
                
            }
            // function setURI(newuri) {}
            function mint(to, id, amount) {
                let balanceLocation := getAccountBalanceLocation(to, id)
                let accountBalance := sload(balanceLocation)

                sstore(balanceLocation, add(accountBalance, amount))
            }
            // function mintBatch(to, ids, amounts) {}
            // function burn(from, id, amount) {}
            // function burnBatch(from, ids, amounts) {}

            /**
             * Calldata decoding functions
             */
            function functionSelector() -> selector {
                // `div` shifts right by 224 bits leaving the first 4 bytes
                selector := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
                // Note: shifting would be preferrable as it costs less gas
            }
            function decodeAsAddress(offset) -> value {
                value := decodeAsUint(offset)
                revertIfNotValidAddress(value)
            }
            function decodeAsAddressArray(offset) -> value {
                value := decodeAsArray(offset)
                // check address validity in array?
                // or duplicate the decodeArray logic in here?
            }
            function decodeAsUintArray(offset) -> value {
                value := decodeAsArray(offset)
            }
            function decodeAsArray(offset) -> value {
                let bitOffsetOfArrayPosition := add(4, mul(offset, 0x20))
                let bitOffsetOfArray := calldataload(bitOffsetOfArrayPosition)
                let byteOffsetOfArray := div(bitOffsetOfArray, 0x20)
                let arrayLength := calldataload(bitOffsetOfArray)

                if iszero(arrayLength) {
                    // Return empty array
                    mstore(0x00, 0)
                    return(0x00, 0x20)
                }

                // Starting at byteOffsetOfArray + 1, loop to offsetOfArry + arrayLength
                for { let i := add(byteOffsetOfArray, 1) } lt(i, add(byteOffsetOfArray, arrayLength)) { i := add(i, 1) }
                {
                    // 
                }

                // mstore(0x00, data1)
                // mstore(0x20, data2)
                // return (0x00, 0x40)

                // revertIfPositionNotInCalldata(position)
            }
            function decodeAsUint(offset) -> value {
                // Ignoring the  first 4 bytes (function selector), get the 
                // position of the word at calldata `offset`.
                let position := add(4, mul(offset, 0x20))
                // Revert if calldata contains no word at this position
                revertIfPositionNotInCalldata(position)
                // Get the word at calldata `position`
                value := calldataload(position)
            }
            function decodeAsBool(offset) -> value {
                let position := add(4, mul(offset, 0x20))
                revertIfPositionNotInCalldata(position)

                let valueAtPosition := calldataload(position)
                revertIfNotBool(valueAtPosition)

                value := valueAtPosition
            }
            function decodeAsBytes(offset) {

            }

            /**
             * Calldata encoding functions
             */
            function returnUint(value) {
                // Save word `value` to memory at slot 0
                mstore(0, value)
                // Return word ('0x20' or 32 bits) from memory slot 0
                return(0, 0x20)
            }
            function returnBool(value) {
                revertIfNotBool(value)
                mstore(0, value)
                return(0, 0x20)
            }

            /**
             * Storage access functions
             */
            // function 

            /**
             * Gating functions
             * 
             * @note if iszero(eq(a, b)) revert pattern
             */
            function revertIfPositionNotInCalldata(position) {
                // Require `position` exists within calldata
                if lt(calldatasize(), add(position, 0x20)) {
                    revert(0, 0)
                }
            }
            function revertIfNotValidAddress(value) {
                // Require `value` is valid address (and not the zero address)
                if iszero(iszero(and(value, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
            function revertIfNotBool(value) {
                let isBool := 0

                if eq(value, 0x0000000000000000000000000000000000000000000000000000000000000000) {
                    isBool := 1
                }
                if eq(value, 0x0000000000000000000000000000000000000000000000000000000000000001) {
                    isBool := 1
                }

                // Require `value` is a bool
                if iszero(isBool) {
                    revert(0, 0)
                }
            }

            /**
             * Utility functions
             */
            function keccakHashTwoValues(valueOne, valueTwo) -> keccakHash {
                // Load `freeMemoryPointer`
                let freeMemoryPointer := mload(0x40)

                // Store words `valueOne` and `valueTwo` at `freeMemoryPointer`
                mstore(freeMemoryPointer, valueOne)
                mstore(add(freeMemoryPointer, 0x20), valueTwo)

                // Increment `freeMemoryPointer` by two words ?
                // mstore(0x40, add(freeMemoryPointer, 0x40))

                mstore(0x00, keccak256(freeMemoryPointer, 0x40))

                keccakHash := mload(0x00)
            }
        }
    }
}

/**
NOTES

Calldata example:
0x00fdd58e0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4000000000000000000000000000000000000000000000000000000000000002a
Function selector:   0x00fdd58e
First arg (address): 0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4
Second arg (uint):   000000000000000000000000000000000000000000000000000000000000002a

Calldata with array args (address[], uint256[]):
0x
4e1273f4 // selector
0000000000000000000000000000000000000000000000000000000000000040 0 //  64 (32 * 2) // bit offset of first arg?
00000000000000000000000000000000000000000000000000000000000000a0 1 // 160 (32 * 5) // bit offset of second arg?

0000000000000000000000000000000000000000000000000000000000000002 2 //   2
0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4 3
0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4 4

0000000000000000000000000000000000000000000000000000000000000002 5 //  2
000000000000000000000000000000000000000000000000000000000000002a 6
000000000000000000000000000000000000000000000000000000000000002a 7

uint256 x
sload(x.slot), sstore(slot, value)
.slot - actual memory location
.offset - within packed slot (bytes to the left)
  - bitshifting and masking
  - e.g if offset 28, shift slot to right shr by 28 bytes
  E uint8
  let vaue := sload(E.slot)
  let shifted := shr(mul(E.offset, 8), value)
  e := and(0xffff, shifted) // notes leading 0's inplied before fs

*write to packed slot fn eg at 25:24

fixed arrays stored in slots like other vars:
[1,2,3]
sload(add(fixedArray.slot, index)) // index 0 ->1

dynamic arrays store their length in their first storage slot
[1,2,3]
let dynamicArrayLength := sload(dynamicArray.slot) // 3
its items are not stored sequentially but rather are stored starting at the slot:
location = keccak256(abi.encode(dynamicArray.slot)) // index 0
- then: plus 1, 2, 3, etc. ret := sload(add(location, index))

mappings behave quite similar
- concatenates key with the storage slot to get the storage location:
  location = keccak256(abi.encode(key, uint256(slot)))
  sload(location)

nested mapping are just hashes of hashes
  nestedMapping[2][4] = 7
  keccak256(abi.encode(uint256(4), keccak256(abi.encode(uint256(2), uint256(slot))))) // 7

  34:15 mapping onto dynamic array e.g

memory is equivelant to the heap in other langs, laid out in 32 byte sequences addressable by byte
- distinct from storage above!!

mstore(p, v) stores value v in slot p
mload(p) retrives 32 bytes from slot p [p...0x20]
mstore8(p, v) like mstore but for one byte
msize() largest accessed memory index in that tx

mstore(0x00, 0xff..ff) // 32 bytes of 1's
0x00 - 0x19 = ff, 0x20 = 00
// note that mstore0x01 only shifts us forward 1 byte not a full 32 bytes like storage
// so it writes 32 bytes starting at the second slot

  ) = not inclusive
- solidity allocates slots 0x00-0x20), 0x20-0x40) for "scratch space"
- reserves slot 0x40-0x60) as the "free memory pointer"
- keeps slot 0x60-0x80) open
  - action begins in slot 0x80

solidity uses memory for:
- abi.encode or abi.encodePacked
- structs and arrays

in yul to access a dynamic array you have to add 0x20 to skip the length

function args(uint256[] memory arr)
  location := arr
  len := mload(arr)
  valueAtIndex0 = mload(add(arr, 0x20)
  valueAtIndex1 = mload(add(arr, 0x40)

*evm memory does not pack data types like storage


function hash() (53:43) (> 64 bytes = can't just use scratch space)

let freeMemoryPointer := mload(0x40)

mstore(freeMemoryPointer, 1)
mstore(add(freeMemoryPointer, 0x20), 2)
mstore(add(freeMemoryPointer, 0x40), 3)

mstore(0x40, add(freeMemoryPointer, 0x60))

mstore(0x00, keccak256(freeMemoryPointer, 0x60))
return(0x00, 0x20)



*can deploy a normal sol contract to call this one for testing


datacopy(0x00, dataoffset("Foo"), datasize("message")
data "Foo" "Bar"

*note the cheat that an account is already the hash of a private key so it is random 
and will not collide (accountToStorageOffset)

 */
