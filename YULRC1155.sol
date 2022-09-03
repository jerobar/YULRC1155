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
            switch selector()
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(balanceOf(decodeAsAddress(0), 1234))
            }
            // balanceOfBatch(address[],uint256[])
            case 0x4e1273f4 {}
            // setApprovalForAll(address,bool)
            case 0xa22cb465 {}
            // isApprovedForAll(address,address)
            case 0xe985e9c5 {}
            // safeTransferFrom(address,address,uint256,uint256,bytes)
            case 0xf242432a {}
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            case 0x2eb2c2d6 {}
            default {
                revert(0, 0)
            }

            function balanceOf(account, id) {}
            function balanceOfBatch(accounts, ids) {}
            function setApprovalForAll(operator, approved) {}
            function isApprovedForAll(account, operator) {}
            function safeTransferFrom(from, to, id, amount, data) {}
            function safeBatchTransferFrom(from, to, ids, amounts, data) {}

            // Calldata decoding functions
            function selector() -> s {
                // Question: What does `div` do here?
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            // Calldata encoding functions
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
            function returnTrue() {
                returnUint(1)
            }

            // Utility functions
        }
    }
}

/*
Notes:

- Compile w/ yul option in remix
- 

*/
