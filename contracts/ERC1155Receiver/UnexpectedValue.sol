// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "hardhat/console.sol";

/**
 * An ERC1155Receiver that returns an unexpected value.
 */
contract UnexpectedValue {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("foobar"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("foobar"));
    }
}
