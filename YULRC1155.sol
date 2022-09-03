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

            // Calldata example:
            // 0x00fdd58e0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4000000000000000000000000000000000000000000000000000000000000002a
            // Function selector: 0x00fdd58e
            // First arg (address): 0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4
            // Second arg (uint): 000000000000000000000000000000000000000000000000000000000000002a

            /**
             * @dev Dispatch to relevant function based on (calldata) function 
             * selector.
             */
            switch getFunctionSelector()
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            // // balanceOfBatch(address[],uint256[])
            // case 0x4e1273f4 {}
            // // setApprovalForAll(address,bool)
            // case 0xa22cb465 {}
            // // isApprovedForAll(address,address)
            // case 0xe985e9c5 {}
            // // safeTransferFrom(address,address,uint256,uint256,bytes)
            // case 0xf242432a {}
            // // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            // case 0x2eb2c2d6 {}
            default {
                revert(0, 0)
            }

            function balanceOf(account, id) -> accountBalance {
                accountBalance := id
            }
            // function balanceOfBatch(accounts, ids) {}
            // function setApprovalForAll(operator, approved) {}
            // function isApprovedForAll(account, operator) {}
            // function safeTransferFrom(from, to, id, amount, data) {}
            // function safeBatchTransferFrom(from, to, ids, amounts, data) {}

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
            // function decodeAsAddressArray(offset) {}
            // function decodeAsUintArray(offset) {}
            function decodeAsUint(offset) -> value {
                // Ignoring the  first 4 bytes (function selector), get the 
                // position of the word at calldata `offset`.
                let position := add(4, mul(offset, 0x20))
                // Revert if calldata contains no word at this position
                if lt(calldatasize(), add(position, 0x20)) {
                    revert(0, 0)
                }
                // Get the word at calldata `position`
                value := calldataload(position)
            }
            // function decodeAsBool(offset) {}
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

            /**
             * Utility functions
             */
        }
    }
}
