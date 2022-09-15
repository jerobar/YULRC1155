// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "hardhat/console.sol";

/**
 * Working implementation of ERC1155Receiver.
 */
contract ERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        // console.log("----- onERC1155Received: ");
        // console.logBytes(msg.data);

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        // console.log("----- onERC1155BatchReceived: ");
        // console.logBytes(msg.data);

        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    // fallback() external payable {
    //     console.log("----- fallback: ");
    //     console.logBytes(msg.data);
    // }

    // receive() external payable {
    //     console.log("----- receive:", msg.value);
    // }
}
