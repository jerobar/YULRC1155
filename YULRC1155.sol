object "YULRC1155" {

    // 'constructor'
    code {
        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // Protection against sending ether
            // ?

            // Dispatcher
            switch selector()
            case 0x00 /* "balanceOf(address,uint256)" */ {}
            case 0x00 /* "balanceOfBatch(address[] calldata,uint256[] calldata)" */ {}
            case 0x00 /* "setApprovalForAll(address,bool)" */ {}
            case 0x00 /* "isApprovedForAll(address,address)" */ {}
            case 0x00 /* "safeTransferFrom(address,address,uint256,uint256,bytes calldata)" */ {}
            case 0x00 /* "safeBatchTransferFrom(address,address,uint256[] calldata,uint256[] calldata,bytes calldata)" */ {}
            
            default {
                revert(0, 0)
            }

            // function balanceOf() {}
            // function balanceOfBatch() {}
            // function setApprovalForAll() {}
            // function isApprovedForAll() {}
            // function safeTransferFrom() {}
            // function safeBatchTransferFrom() {}

            // calldata decoding functions
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }
        }
    }
}

/*
Notes:

- Compile w/ yul option in remix
- 

*/
