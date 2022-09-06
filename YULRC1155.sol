/**
 * YULRC1155
 * 
 * A basic implementation of the ERC1155 token standard written entirely in Yul.
 * 
 * Note that the approach below prioritizes readability over efficiency and 
 * adopts a convention of prefixing calldata-related variables with `cd`, 
 * storage with `s` and memory with `m`.
 */
object "YULRC1155" {

    code {
        // Store the contract owner in slot zero
        sstore(0, caller())

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {

        code {
            // Initialize free memory pointer to 0x80
            mstore(0x40, 0x80)

            /**
             * Storage slots
             */
            // 0: address owner
            function ownerSlot() -> slot { slot := 0 }

            // 1: mapping uint256 tokenID => (address account => uint256 balance)
            function balancesSlot() -> slot { slot := 1 }

            // 2: mapping address account => (address operator => bool approved)
            function operatorApprovalsSlot() -> slot { slot := 2 }

            /**
             * Dispatcher
             * 
             * Dispatches to relevant function based on calldata's function 
             * selector (the first 4 bytes of keccak256(functionSignature)).
             */
            switch functionSelector()
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            // balanceOfBatch(address[],uint256[])
            case 0x4e1273f4 {
                returnArray(balanceOfBatch(decodeAsAddressArray(0), decodeAsUintArray(1)))
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
                safeBatchTransferFrom(
                    decodeAsAddress(0), 
                    decodeAsAddress(1), 
                    decodeAsUintArray(2), 
                    decodeAsUintArray(3), 
                    0 // decodeAsBytes(4)
                )
            }
            // mint(address,uint256,uint256)
            case 0x156e29f6 {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            // mintBatch(address,uint256[],uint256[])
            case 0xd81d0a15 {
                mintBatch(decodeAsAddress(0), decodeAsUintArray(1), decodeAsUintArray(2))
            }
            // burn(address,uint256,uint256)
            case 0xf5298aca {
                burn(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            // burnBatch(address,uint256[],uint256[])
            case 0x6b20c454 {
                burnBatch(decodeAsAddress(0), decodeAsUintArray(1), decodeAsUintArray(2))
            }
            default {
                revert(0, 0)
            }

            /**
             * ERC1155 functions
             */
            function balanceOf(account, id) -> accountBalance {
                let sBalanceKey := getAccountBalanceKey(account, id)

                accountBalance := sload(sBalanceKey)
            }

            function balanceOfBatch(mAccountsArrayLengthPointer, mIdsArrayLengthPointer) -> mBalancesArrayLengthPosition {
                let accountsArrayLength := mload(mAccountsArrayLengthPointer)
                let idsArrayLength := mload(mIdsArrayLengthPointer)

                revertIfNotEqual(accountsArrayLength, idsArrayLength)

                // Store length of balances array to return at free memory pointer
                let mFreeMemoryPointer := mload(0x40)
                let mBalancesArrayLengthPosition_ := mFreeMemoryPointer
                mstore(mBalancesArrayLengthPosition_, accountsArrayLength)
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // For each account, load its token id balance into balances array
                for { let i := 1 } lt(i, add(accountsArrayLength, 1)) { i := add(i, 1) }
                {
                    mFreeMemoryPointer := mload(0x40)

                    // Get account and id at this index position
                    let account := mload(add(mAccountsArrayLengthPointer, mul(i, 0x20)))
                    let id := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))

                    // Get account balance from storage
                    let sAccountBalanceKey := getAccountBalanceKey(account, id)
                    let accountBalance := sload(sAccountBalanceKey)

                    mstore(mFreeMemoryPointer, accountBalance)

                    incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                }

                mBalancesArrayLengthPosition := mBalancesArrayLengthPosition_
            }

            function setApprovalForAll(operator, approved) {
                let sOperatorApprovalKey := getOperatorApprovalKey(caller(), operator)

                sstore(sOperatorApprovalKey, approved)

                emitApprovalForAllEvent(caller(), operator, approved)
            }

            function isApprovedForAll(account, operator) -> isApproved {
                let sOperatorApprovalKey := getOperatorApprovalKey(account, operator)

                isApproved := sload(sOperatorApprovalKey)
            }

            function safeTransferFrom(from, to, id, amount, data) {
                transfer(from, to, id, amount)

                emitTransferSingleEvent(caller(), from, to, id, amount)
            }

            function safeBatchTransferFrom(
                fromAccount, 
                toAccount, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer, 
                data
            ) {
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := mload(mAmountsArrayLengthPointer)

                revertIfNotEqual(idsArrayLength, amountsArrayLength)

                // For each token id, transfer to 'to' account
                for { let i := 1 } lt(i, add(idsArrayLength, 1)) { i := add(i, 1) }
                {
                    let id := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))
                    let amount := mload(add(mAmountsArrayLengthPointer, mul(i, 0x20)))

                    transfer(fromAccount, toAccount, id, amount)
                }

                emitTransferBatchEvent(
                    caller(), 
                    fromAccount, 
                    toAccount, 
                    mIdsArrayLengthPointer,
                    mAmountsArrayLengthPointer 
                )
            }

            // function getURI() {}
            
            // function setURI(newuri) {}
            
            function mint(to, id, amount) {
                let sAccountBalanceKey := getAccountBalanceKey(to, id)
                let accountBalance := sload(sAccountBalanceKey)

                sstore(sAccountBalanceKey, add(accountBalance, amount))
            }

            function mintBatch(
                toAccount, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer
            ) {
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := mload(mAmountsArrayLengthPointer)

                revertIfNotEqual(idsArrayLength, amountsArrayLength)

                // For each token id, mint to address
                for { let i := 1 } lt(i, add(idsArrayLength, 1)) { i := add(i, 1) }
                {
                    let id := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))
                    let amount := mload(add(mAmountsArrayLengthPointer, mul(i, 0x20)))

                    mint(toAccount, id, amount)
                }
            }

            function burn(from, id, amount) {
                let sAccountBalanceKey := getAccountBalanceKey(from, id)
                let accountBalance := sload(sAccountBalanceKey)

                revertIfBalanceInsufficient(accountBalance, amount)

                sstore(sAccountBalanceKey, sub(accountBalance, amount))
            }

            function burnBatch(from, mIdsArrayLengthPointer, mAmountsArrayLengthPointer) {
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := mload(mAmountsArrayLengthPointer)

                revertIfNotEqual(idsArrayLength, amountsArrayLength)

                // For each token id, burn requested amount
                for { let i := 1 } lt(i, add(idsArrayLength, 1)) { i := add(i, 1) }
                {
                    let id := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))
                    let amount := mload(add(mAmountsArrayLengthPointer, mul(i, 0x20)))

                    burn(from, id, amount)
                }
            }

            /**
             * ERC1155 Events
             */
            function emitTransferSingleEvent(operator, from, to, id, value) {
                // keccak256("TransferSingle(address,address,address,uint256,uint256)")
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62

                mstore(0x00, id)
                mstore(0x20, value)
                log4(0x00, 0x40, signatureHash, operator, from, to)
            }

            function emitTransferBatchEvent(
                operator, 
                from, 
                to, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer
            ) {
                // keccak256("TransferBatch(address,address,address,uint256[],uint256[])")
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb

                let mFreeMemoryPointer := mload(0x40)
                let mIdsArrayOffsetPointer := mFreeMemoryPointer
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := mload(mAmountsArrayLengthPointer)
                
                // Store bit offset of id's array
                mstore(mFreeMemoryPointer, 0x40) 
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                
                // Store bit offset of amounts array
                mstore(mFreeMemoryPointer, add(0x40, mul(idsArrayLength, 0x20))) 
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // Store id's array length
                mstore(mFreeMemoryPointer, idsArrayLength)
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // Store copy of id's array items
                for { let i := 1 } lt(i, add(idsArrayLength, 1)) { i := add(i, 1) }
                {
                    let value := mload(add(mIdsArrayLengthPointer, i))
                    mstore(mFreeMemoryPointer, value)

                    incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                }

                // Store amounts array length
                mstore(mFreeMemoryPointer, amountsArrayLength)
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // Store copy of amounts array items
                for { let i := 1 } lt(i, add(amountsArrayLength, 1)) { i := add(i, 1) }
                {
                    let value := mload(add(mAmountsArrayLengthPointer, i))
                    mstore(mFreeMemoryPointer, value)

                    incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                }

                log4(mIdsArrayOffsetPointer, sub(mFreeMemoryPointer, mIdsArrayOffsetPointer), signatureHash, operator, from, to)
            }

            function emitApprovalForAllEvent(owner, operator, approved) {
                // keccak256("ApprovalForAll(address,address,bool)")
                let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31

                mstore(0x00, approved)
                log3(0x00, 0x20, signatureHash, owner, operator)
            }

            function emitURIEvent(value, id) {
                // keccak256("URI(string,uint256)")
                let signatureHash := 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b

                // store value in memory
                // log2(0x00, 0x20, signatureHash, id)
            }

            /**
             * Calldata decoding functions
             */
            function functionSelector() -> selector {
                // `div` shifts right by 224 bits leaving the first 4 bytes
                selector := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
                // Note: shr would be preferrable as it costs less gas
            }

            function decodeAsAddress(cdOffset) -> value {
                let uintAtOffset := decodeAsUint(cdOffset)
                revertIfNotValidAddress(uintAtOffset)

                value := uintAtOffset
            }

            function decodeAsAddressArray(cdOffset) -> value {
                value := decodeAsArray(cdOffset, 1)
            }

            function decodeAsUintArray(cdOffset) -> value {
                value := decodeAsArray(cdOffset, 0)
            }

            function decodeAsArray(cdOffset, isAddressArray) -> mArrayLengthPointer {
                // Get position and length of array from calldata
                let cdBitOffsetOfArrayPosition := add(4, mul(cdOffset, 0x20))
                let cdBitOffsetOfArray := calldataload(cdBitOffsetOfArrayPosition)
                let cdArrayLengthPosition := add(4, cdBitOffsetOfArray)
                let arrayLength := calldataload(cdArrayLengthPosition)

                // Load free memory pointer
                let mFreeMemoryPointer := mload(0x40)

                // Store array length
                mFreeMemoryPointer := mload(0x40)
                let mArrayLengthPointer_ := mFreeMemoryPointer
                mstore(mArrayLengthPointer_, arrayLength)
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // Load each array item into free memory
                for { let i := 1 } lt(i, add(arrayLength, 1)) { i := add(i, 1) }
                {
                    mFreeMemoryPointer := mload(0x40)

                    let cdPosition := add(cdArrayLengthPosition, mul(i, 0x20))
                    let cdValue := calldataload(cdPosition)

                    if isAddressArray {
                        revertIfNotValidAddress(cdValue)
                    }

                    mstore(mFreeMemoryPointer, cdValue)

                    incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                }

                mArrayLengthPointer := mArrayLengthPointer_
            }

            function decodeAsUint(cdOffset) -> value {
                let cdPosition := add(4, mul(cdOffset, 0x20))
                revertIfPositionNotInCalldata(cdPosition)

                value := calldataload(cdPosition)
            }

            function decodeAsBool(cdOffset) -> value {
                let cdPosition := add(4, mul(cdOffset, 0x20))
                revertIfPositionNotInCalldata(cdPosition)

                let valueAtPosition := calldataload(cdPosition)
                revertIfNotBool(valueAtPosition)

                value := valueAtPosition
            }

            function decodeAsBytes(cdOffset) {

            }

            /**
             * Calldata encoding functions
             */
            function returnUint(value) {
                mstore(0x00, value)

                return(0x00, 0x20)
            }

            function returnBool(value) {
                revertIfNotBool(value)
                mstore(0x00, value)

                return(0x00, 0x20)
            }

            function returnArray(mArrayLengthPointer) {
                let mArrayBitOffsetPointer := sub(mArrayLengthPointer, 0x20)
                // Bit offset of array in response
                mstore(mArrayBitOffsetPointer, 0x20)
                let arrayLength := mload(mArrayLengthPointer)

                // Return memory from array bit offset to the last item
                return(mArrayBitOffsetPointer, add(mArrayBitOffsetPointer, mul(add(arrayLength, 2), 0x20)))
            }

            /**
             * Storage access functions
             */
            function getAccountBalanceKey(account, id) -> sBalanceKey {
                // Balances: mapping uint256 tokenID => (address account => uint256 balance)
                
                // Hash `id` and `balancesSlot()`
                let hashOfIdandBalancesSlot := keccakHashTwoValues(id, balancesSlot())

                // `sBalanceKey` = keccak256(`account`, keccak256(`id`, `balancesSlot()`))
                sBalanceKey := keccakHashTwoValues(account, hashOfIdandBalancesSlot)
            }

            function getOperatorApprovalKey(account, operator) -> sOperatorApprovalKey {
                // Approvals: mapping address account => (address operator => bool approved)

                // Hash `operator` and `operatorApprovalsSlot()`
                let hashOfAccountAndOperatorApprovalsSlot := keccakHashTwoValues(account, operatorApprovalsSlot())

                // `sOperatorApprovalKey` = keccak256(`operator`, keccak256(`account`, `operatorApprovalsSlot()`))
                sOperatorApprovalKey := keccakHashTwoValues(operator, hashOfAccountAndOperatorApprovalsSlot)
            }

            function transfer(from, to, id, amount) {
                // Decrement `from` account balance for `id` by `amount`
                let sFromAccountBalanceKey := getAccountBalanceKey(from, id)
                let fromAccountBalance := sload(sFromAccountBalanceKey)

                revertIfOperatorNotApproved(from, caller())
                revertIfBalanceInsufficient(fromAccountBalance, amount)

                sstore(sFromAccountBalanceKey, sub(fromAccountBalance, amount))

                // Increment `to` account balance for `is` by `amount`
                let sToAccountBalanceKey := getAccountBalanceKey(to, id)
                let toAccountBalance := sload(sToAccountBalanceKey)

                sstore(sToAccountBalanceKey, add(toAccountBalance, amount))

                // If `to` address is a contract
                let toSize := extcodesize(to)
                if gt(toSize, 0) {
                    // Call `onERC1155Received` on `to` with `data`

                }
            }

            /**
             * Gating functions
             */
            function revertIfPositionNotInCalldata(cdPosition) {
                // Require `cdPosition` exists within calldata
                if lt(calldatasize(), add(cdPosition, 0x20)) {
                    revert(0, 0)
                }
            }

            function revertIfCallerNotContractOwner() {
                let owner := sload(ownerSlot())

                // Require `caller()` is contract owner
                if iszero(eq(caller(), owner)) {
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

            function revertIfOperatorNotApproved(account, operator) {
                let sOperatorApprovalKey := getOperatorApprovalKey(account, operator)
                let operatorIsApproved := sload(sOperatorApprovalKey)

                if iszero(operatorIsApproved) {
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
                let mFreeMemoryPointer := mload(0x40)

                // Store words `valueOne` and `valueTwo` starting at `mFreeMemoryPointer`
                mstore(mFreeMemoryPointer, valueOne)
                mstore(add(mFreeMemoryPointer, 0x20), valueTwo)

                mstore(0x00, keccak256(mFreeMemoryPointer, 0x40))

                // Increment `mFreeMemoryPointer` by two words
                // mstore(0x40, add(mFreeMemoryPointer, 0x40))

                keccakHash := mload(0x00)
            }
        }
    }
}
