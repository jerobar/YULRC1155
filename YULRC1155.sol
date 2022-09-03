/**

NOTES

Calldata example:
0x00fdd58e0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4000000000000000000000000000000000000000000000000000000000000002a
Function selector:   0x00fdd58e
First arg (address): 0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4
Second arg (uint):   000000000000000000000000000000000000000000000000000000000000002a

(address[], uint256[])

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

 */

object "YULRC1155" {

    code {
        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            // Protection against sending ether
            // ?

            /**
             * @dev Dispatch to relevant function based on (calldata) function 
             * selector.
             */
            switch getFunctionSelector()
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
                // safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsBytes(4))
            }
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            case 0x2eb2c2d6 {
                // safeBatchTransferFrom(decodeAsAddressArray(0), decodeAsAddressArray(1), decodeAsUintArray(2), decodeAsUintArray(3), decodeAsBytes(4))
            }
            default {
                revert(0, 0)
            }

            function balanceOf(account, id) -> accountBalance {
                accountBalance := id
            }
            // function balanceOfBatch(accounts, ids) -> accountBalanceArray {}
            function setApprovalForAll(operator, approved) {
                // isApproved := approved
            }
            function isApprovedForAll(account, operator) -> isApproved {
                isApproved := 1
            }
            function safeTransferFrom(from, to, id, amount, data) {}
            function safeBatchTransferFrom(from, to, ids, amounts, data) {}

            /**
             * Calldata decoding functions
             */
            function getFunctionSelector() -> functionSelector {
                // Question: What does `div` do here?
                functionSelector := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }
            function decodeAsAddress(offset) -> value {
                value := decodeAsUint(offset)
            }
            // function decodeAsAddressArray(offset) -> value {}
            // function decodeAsUintArray(offset) -> value {}
            function decodeAsArray(offset) -> value {
                // 
                let bitOffsetOfArrayPosition := add(4, mul(offset, 0x20))
                let bitOffsetOfArray := calldataload(bitOffsetOfArrayPosition)
                let arrayLength := calldataload(bitOffsetOfArray)

                // Starting at bitOffsetOfArray + 1, loop to bitOffsetOfArray + arrayLength
                // if arrayLength is zero, return an empty array

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
                revertIfValueNotBool(valueAtPosition)
                value := valueAtPosition
            }
            // function decodeAsBytes(offset) {}

            /**
             * Calldata encoding functions
             */
            function returnUint(value) {
                // Save word `value` to memory at offset 0
                mstore(0, value)
                // Return word ('0x20' or 32 bits) from memory offset 0
                return(0, 0x20)
            }
            function returnBool(value) {
                revertIfValueNotBool(value)
                mstore(0, value)
                return(0, 0x20)
            }

            /**
             * Utility functions
             */
            function revertIfPositionNotInCalldata(position) {
                if lt(calldatasize(), add(position, 0x20)) {
                    revert(0, 0)
                }
            }
            function revertIfValueNotBool(value) {
                let isBool := 0

                if eq(value, 0x0000000000000000000000000000000000000000000000000000000000000000) {
                    isBool := 1
                }
                if eq(value, 0x0000000000000000000000000000000000000000000000000000000000000001) {
                    isBool := 1
                }

                if iszero(isBool) {
                    revert(0, 0)
                }
            }
        }
    }
}
