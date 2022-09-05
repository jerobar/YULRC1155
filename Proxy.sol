// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IYULRC1155 {
    function balanceOf(address, uint256) external returns (uint256);

    function balanceOfBatch(address[] calldata, uint256[] calldata)
        external
        returns (uint256[] memory);

    function setApprovalForAll(address, bool) external;

    function isApprovedForAll(address, address) external;

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (uint256);

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external;

    function mint(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function returnArray(uint256[] calldata)
        external
        returns (uint256[] memory);
}

contract Proxy {
    IYULRC1155 public yulContract;

    constructor(address contractAddress) {
        yulContract = IYULRC1155(contractAddress);
    }

    function returnArraySolidity(uint256[] calldata array)
        external
        pure
        returns (uint256[] memory)
    {
        assembly {
            // Get length of array from calldata
            let offset := 0
            let bitOffsetOfArrayPosition := add(4, mul(offset, 0x20))
            let bitOffsetOfArray := calldataload(bitOffsetOfArrayPosition)
            let arrayLengthPosition := add(4, bitOffsetOfArray)
            let arrayLength := calldataload(arrayLengthPosition)

            // Load free memory pointer
            let freeMemoryPointer := mload(0x40)
            let arrayOffsetPointer := freeMemoryPointer

            // Store array offset in response (0x20)
            mstore(freeMemoryPointer, 0x20)
            mstore(0x40, add(freeMemoryPointer, 0x20))

            // Store array length
            freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, arrayLength)
            mstore(0x40, add(freeMemoryPointer, 0x20))

            // For each item in array
            for {
                let i := 1
            } lt(i, add(arrayLength, 1)) {
                i := add(i, 1)
            } {
                freeMemoryPointer := mload(0x40)

                // let position := add(arrayLengthPosition, mul(i, 0x20))
                // let value := calldataload(position)

                mstore(freeMemoryPointer, 0x2a) // store 42

                mstore(0x40, add(freeMemoryPointer, 0x20))
            }

            return(
                arrayOffsetPointer,
                add(arrayOffsetPointer, mul(add(arrayLength, 2), 0x20))
            )
        }
    }

    function returnArray(uint256[] calldata array)
        external
        returns (uint256[] memory)
    {
        return yulContract.returnArray(array);
    }

    function balanceOf(address account, uint256 id) external returns (uint256) {
        return yulContract.balanceOf(account, id);
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        returns (uint256[] memory)
    {
        return yulContract.balanceOfBatch(accounts, ids);
    }

    function setApprovalForAll(address operator, bool approved) external {
        return yulContract.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address account, address operator) external {
        return yulContract.isApprovedForAll(account, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256) {
        return yulContract.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        return yulContract.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external returns (uint256) {
        return yulContract.mint(to, id, amount);
    }
}
