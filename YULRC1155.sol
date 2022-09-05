/**
 * YULRC1155
 * 
 * An basic implementation of the ERC1155 token standard written entirely in Yul.
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
                returnUintArray(balanceOfBatch(decodeAsAddressArray(0), decodeAsUintArray(1)))
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
                safeTransferFrom(
                    decodeAsAddress(0), 
                    decodeAsAddress(1), 
                    decodeAsUint(2), 
                    decodeAsUint(3), 
                    0 // decodeAsBytes(4)
                )
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
                returnUint(43)
            }
            // TESTING - returnArray(uint256[])
            case 0x3e8bb4b7 {
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
                incrementFreeMemoryPointer(freeMemoryPointer, 0x20)

                // Store array length
                freeMemoryPointer := mload(0x40)
                mstore(freeMemoryPointer, arrayLength)
                incrementFreeMemoryPointer(freeMemoryPointer, 0x20)

                // For each item in array
                for { let i := 1 } lt(i, add(arrayLength, 1)) { i := add(i, 1) }
                {
                    freeMemoryPointer := mload(0x40)

                    let position := add(arrayLengthPosition, mul(i, 0x20))
                    let value := calldataload(position)

                    mstore(freeMemoryPointer, value)

                    incrementFreeMemoryPointer(freeMemoryPointer, 0x20)
                }

                return(arrayOffsetPointer, add(arrayOffsetPointer, mul(add(arrayLength, 2), 0x20)))
            }
            default {
                revert(0, 0)
            }

            /**
             * ERC1155 functions
             */
            function balanceOf(account, id) -> accountBalance {
                let balanceLocation := getAccountBalanceLocation(account, id)
                accountBalance := sload(balanceLocation)
            }

            function balanceOfBatch(accounts, ids) -> arrayOffsetPosition {
                let accountsArrayLength := mload(accounts)
                let idsArrayLength := mload(ids)

                revertIfNotEqual(accountsArrayLength, idsArrayLength)

                let freeMemoryPointer := mload(0x40)
                let balancesArrayOffsetPosition := freeMemoryPointer

                mstore(balancesArrayOffsetPosition, 0x20)
                // Increment `freeMemoryPointer`
                incrementFreeMemoryPointer(freeMemoryPointer, 0x20)

                let balancesArrayLengthPosition := freeMemoryPointer

                mstore(balancesArrayLengthPosition, accountsArrayLength)

                // Starting at 1, loop to `accountsArrayLength`
                for { let i := 1 } lt(i, add(accountsArrayLength, 1)) { i := add(i, 1) }
                {
                    freeMemoryPointer := mload(0x40)

                    // Get account at position
                    let account := mload(add(accounts, mul(i, 0x20)))

                    // Get id at position
                    let id := mload(add(ids, mul(i, 0x20)))

                    // Get account balance
                    let accountBalanceLocation := getAccountBalanceLocation(account, id)
                    let accountBalance := sload(accountBalanceLocation)

                    // Store account balance at `freeMemoryPointer`
                    mstore(freeMemoryPointer, accountBalance)

                    // Increment `freeMemoryPointer`
                    incrementFreeMemoryPointer(freeMemoryPointer, 0x20)
                }

                arrayOffsetPosition := balancesArrayOffsetPosition
            }

            function setApprovalForAll(operator, approved) {
                let operatorApprovalLocation := getOperatorApprovalLocation(caller(), operator)
                sstore(operatorApprovalLocation, approved)
            }

            function isApprovedForAll(account, operator) -> isApproved {
                let operatorApprovalLocation := getOperatorApprovalLocation(account, operator)
                isApproved := sload(operatorApprovalLocation)
            }

            function safeTransferFrom(from, to, id, amount, data) {
                // Decrement `from` account balance for `id` by `amount`
                let fromAccountBalanceLocation := getAccountBalanceLocation(from, id)
                let fromAccountBalance := sload(fromAccountBalanceLocation)
                revertIfBalanceInsufficient(fromAccountBalance, amount)

                sstore(fromAccountBalanceLocation, sub(fromAccountBalance, amount))

                // Increment `to` account balance for `is` by `amount`
                let toAccountBalanceLocation := getAccountBalanceLocation(to, id)
                let toAccountBalance := sload(toAccountBalanceLocation)

                sstore(toAccountBalanceLocation, add(toAccountBalance, amount))

                returnUint(41)
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
                
                let arrayLengthPosition := add(4, bitOffsetOfArray)
                let arrayLength := calldataload(arrayLengthPosition)

                // Load `freeMemoryPointer`
                let freeMemoryPointer := mload(0x40)
                arrayLengthPosition := mload(freeMemoryPointer)

                // Store array length at `arrayLengthPosition`
                mstore(arrayLengthPosition, arrayLength)

                // Increment `freeMemoryPointer`
                incrementFreeMemoryPointer(freeMemoryPointer, 0x20)

                for { let i := 1 } lt(i, add(arrayLength, 1)) { i := add(i, 1) }
                {
                    freeMemoryPointer := mload(0x40)

                    let position := add(arrayLengthPosition, mul(i, 0x20))
                    revertIfPositionNotInCalldata(position)

                    let wordAtCalldataPosition := calldataload(position)

                    mstore(freeMemoryPointer, wordAtCalldataPosition)

                    incrementFreeMemoryPointer(freeMemoryPointer, 0x20)
                }

                value := arrayLengthPosition
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
                // Save word `value` to memory at slot 0x00
                mstore(0x00, value)
                // Return word ('0x20' or 32 bits) from memory slot 0x00
                return(0x00, 0x20)
            }

            function returnBool(value) {
                revertIfNotBool(value)
                mstore(0x00, value)
                return(0x00, 0x20)
            }

            function returnUintArray(value) {
                let arrayOffsetPosition := value
                let arrayLength := mload(add(arrayOffsetPosition, 0x20))
                
                return(arrayOffsetPosition, add(arrayOffsetPosition, mul(add(arrayLength, 2), 0x20)))
            }

            /**
             * Storage access functions
             */
            function getAccountBalanceLocation(account, id) -> balanceLocation {
                // Balances: mapping uint256 tokenID => (address account => uint256 balance)
                
                // Hash `id` and `balancesSlot()`
                let hashOfIdandBalancesSlot := keccakHashTwoValues(id, balancesSlot())

                // `balanceLocation` = keccak256(`account`, keccak256(`id`, `balancesSlot()`))
                balanceLocation := keccakHashTwoValues(account, hashOfIdandBalancesSlot)
            }

            function getOperatorApprovalLocation(account, operator) -> operatorApprovalLocation {
                // Approvals: mapping address account => (address operator => bool approved)

                // Hash `operator` and `operatorApprovalsSlot()`
                let hashOfOperatorAndOperatorApprovalsSlot := keccakHashTwoValues(operator, operatorApprovalsSlot())

                // `operatorApprovalLocation` = keccak256(`account`, keccak256(`operator`, `operatorApprovalsSlot()`))
                operatorApprovalLocation := keccakHashTwoValues(account, hashOfOperatorAndOperatorApprovalsSlot)
            }

            /**
             * Gating functions
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

                if eq(value, 0) {
                    isBool := 1
                }
                if eq(value, 1) {
                    isBool := 1
                }

                // Require `value` is a bool
                if iszero(isBool) {
                    revert(0, 0)
                }
            }

            function revertIfBalanceInsufficient(accountBalance, amount) {
                // Require `accountBalance` >= `amount`
                if iszero(gt(accountBalance, amount)) {
                    revert(0, 0)
                }
            }

            function revertIfNotEqual(valueOne, valueTwo) {
                if iszero(eq(valueOne, valueTwo)) {
                    revert(0, 0)
                }
            }

            /**
             * Utility functions
             */
            function incrementFreeMemoryPointer(currentValue, incrementBy) {
                mstore(0x40, add(currentValue, incrementBy))
            }

            function keccakHashTwoValues(valueOne, valueTwo) -> keccakHash {
                // Load `freeMemoryPointer`
                let freeMemoryPointer := mload(0x40)

                // Store words `valueOne` and `valueTwo` starting at `freeMemoryPointer`
                mstore(freeMemoryPointer, valueOne)
                mstore(add(freeMemoryPointer, 0x20), valueTwo)

                mstore(0x00, keccak256(freeMemoryPointer, 0x40))

                // Increment `freeMemoryPointer` by two words
                // mstore(0x40, add(freeMemoryPointer, 0x40))

                keccakHash := mload(0x00)
            }
        }
    }
}
