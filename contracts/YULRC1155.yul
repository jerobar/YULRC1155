/**
 * YULRC1155
 * 
 * A basic implementation of the ERC1155 token standard written entirely in Yul.
 * 
 * Note that the approach below prioritizes readability over efficiency and 
 * adopts a convention of prefixing calldata-related variables with `cd`, 
 * storage with `s` and memory with `m` where it aids clarity.
 * 
 * @todos
 * - calldatasize/calldatacopy approach for decodeAsBytesArray
 * - uri event code ? even though it's not being used ? 
 * 
 * - copyBytesArrayIntoMemory(at, to)
 * - 
 */
object "YULRC1155" {

    /**
     * Constructor
     * 
     * Stores the caller as contract owner, stores the uri string passed in 
     * constructor and deploys the contract.
     */
    code {
        // Store the contract owner in slot 0
        sstore(0, caller())

        // Dev: hardcode storage for uri 'https://token-cdn-domain/{id}.json'
        sstore(3, 0x22)
        sstore(4, 0x68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2f7b69647d2e6a73)
        sstore(5, 0x6f6e000000000000000000000000000000000000000000000000000000000000)

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {

        code {
            // Initialize a free memory pointer at 0x00
            mstore(0x00, 0x20)

            /**
             * Storage slots
             */
            // 0: address owner
            function ownerSlot() -> slot { slot := 0 }

            // 1: mapping uint256 tokenID => (address account => uint256 balance)
            function balancesSlot() -> slot { slot := 1 }

            // 2: mapping address account => (address operator => bool approved)
            function operatorApprovalsSlot() -> slot { slot := 2 }

            // 3: uint256 uri length
            function uriLengthSlot() -> slot { slot := 3 }

            /**
             * Dispatcher
             * 
             * Dispatches to relevant function based on calldata's function 
             * selector (the first 4 bytes of keccak256(functionSignature)).
             */
            switch functionSelector()
            // uri(uint256)
            case 0x0e89341c {
                uri(0) // Token id isn't used so don't bother decoding it
            }
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
                    decodeAsBytesArray(4)
                )
            }
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            case 0x2eb2c2d6 {
                safeBatchTransferFrom(
                    decodeAsAddress(0), 
                    decodeAsAddress(1), 
                    decodeAsUintArray(2), 
                    decodeAsUintArray(3), 
                    decodeAsBytesArray(4)
                )
            }
            // mint(address,uint256,uint256,bytes)
            case 0x731133e9 {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsBytesArray(3))
            }
            // mintBatch(address,uint256[],uint256[],bytes)
            case 0x1f7fdffa {
                mintBatch(decodeAsAddress(0), decodeAsUintArray(1), decodeAsUintArray(2), decodeAsBytesArray(3))
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
             * Calldata decoding functions
             */
            function functionSelector() -> selector {
                // Shift right by 224 bits leaving the first 4 bytes
                selector := shr(0xE0, calldataload(0))
            }

            function decodeAsAddress(cdOffset) -> value {
                let uintAtOffset := decodeAsUint(cdOffset)
                revertIfNotValidAddress(uintAtOffset)

                value := uintAtOffset
            }

            function decodeAsAddressArray(cdOffset) -> value {
                value := decodeAsBytesArray(cdOffset)
            }

            function decodeAsUintArray(cdOffset) -> value {
                value := decodeAsBytesArray(cdOffset)
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

            function decodeAsBytesArray(cdOffset) -> mBytesArrayLengthPointer {
                // Get position and length of bytes from calldata
                let cdOffsetOfBytesPosition := add(4, mul(cdOffset, 0x20))
                let cdOffsetOfBytes := calldataload(cdOffsetOfBytesPosition)
                let cdBytesLengthPosition := add(4, cdOffsetOfBytes)
                let bytesLength := calldataload(cdBytesLengthPosition)

                // Store bytes length in free memory
                let mFreeMemoryPointer := mload(0x00)
                let mBytesArrayLengthPointer_ := mFreeMemoryPointer
                mstore(mBytesArrayLengthPointer_, bytesLength)

                // Copy bytes data into free memory after length
                calldatacopy(add(mFreeMemoryPointer, 0x20), add(cdBytesLengthPosition, 0x20), mul(bytesLength, 0x20))
                
                // Increment free memory pointer to after bytes array
                incrementFreeMemoryPointer(mFreeMemoryPointer, add(0x20, mul(bytesLength, 0x20)))
                
                mBytesArrayLengthPointer := mBytesArrayLengthPointer_
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
                let mArrayOffsetPointer := sub(mArrayLengthPointer, 0x20)

                // Offset of array in response
                mstore(mArrayOffsetPointer, 0x20)
                let arrayLength := mload(mArrayLengthPointer)

                // Return memory from array's offset to its last item
                return(mArrayOffsetPointer, add(mArrayOffsetPointer, mul(add(arrayLength, 2), 0x20)))
            }

            /**
             * ERC1155 functions
             */
            function uri(id) {
                let uriLength := sload(uriLengthSlot())

                // Store uri string offset within response
                mstore(0x00, 0x20)
                // Store uri string length
                mstore(0x20, uriLength)

                // Store uri string data
                for { let i := 1 } lt(i, add(2, div(uriLength, 0x20))) { i := add(i, 1) }
                {
                    let dataSlot := add(uriLengthSlot(), i)
                    let uriData := sload(dataSlot)

                    mstore(add(0x20, mul(i, 0x20)), uriData)
                }

                // Return uri string offset, length, and data
                return(0x00, add(0x40, mul(uriLength, 0x20)))
            }
            
            function balanceOf(account, id) -> accountBalance {
                revertIfZeroAddress(account)

                let sBalanceKey := getAccountBalanceKey(account, id)

                accountBalance := sload(sBalanceKey)
            }

            function balanceOfBatch(mAccountsArrayLengthPointer, mIdsArrayLengthPointer) -> mBalancesArrayLengthPosition {
                let accountsArrayLength := mload(mAccountsArrayLengthPointer)
                let idsArrayLength := mload(mIdsArrayLengthPointer)

                revertIfNotEqual(accountsArrayLength, idsArrayLength)

                // Store length of balances array to return at free memory pointer
                let mFreeMemoryPointer := mload(0x00)
                let mBalancesArrayLengthPosition_ := mFreeMemoryPointer
                mstore(mBalancesArrayLengthPosition_, accountsArrayLength)
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // For each account, load its token id balance into balances array
                for { let i := 1 } lt(i, add(accountsArrayLength, 1)) { i := add(i, 1) }
                {
                    mFreeMemoryPointer := mload(0x00)

                    // Get account and id at this index position
                    let account := mload(add(mAccountsArrayLengthPointer, mul(i, 0x20)))
                    revertIfNotValidAddress(account)
                    let id := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))

                    // Get account balance
                    let accountBalance := balanceOf(account, id)

                    mstore(mFreeMemoryPointer, accountBalance)

                    incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                }

                mBalancesArrayLengthPosition := mBalancesArrayLengthPosition_
            }

            function setApprovalForAll(operator, approved) {
                revertIfEqual(caller(), operator)

                let sOperatorApprovalKey := getOperatorApprovalKey(caller(), operator)

                sstore(sOperatorApprovalKey, approved)

                emitApprovalForAllEvent(caller(), operator, approved)
            }

            function isApprovedForAll(account, operator) -> isApproved {
                let sOperatorApprovalKey := getOperatorApprovalKey(account, operator)

                isApproved := sload(sOperatorApprovalKey)
            }

            function _transfer(from, to, id, amount) {
                revertIfZeroAddress(to)

                // If `from` not equal to `caller()`
                if iszero(eq(from, caller())) {
                    revertIfOperatorNotApproved(from, caller())
                }

                // Decrement `from` account balance for `id` by `amount`
                let sFromAccountBalanceKey := getAccountBalanceKey(from, id)
                let fromAccountBalance := sload(sFromAccountBalanceKey)
                
                revertIfBalanceInsufficient(fromAccountBalance, amount)

                sstore(sFromAccountBalanceKey, sub(fromAccountBalance, amount))

                // Increment `to` account balance for `is` by `amount`
                let sToAccountBalanceKey := getAccountBalanceKey(to, id)
                let toAccountBalance := sload(sToAccountBalanceKey)

                sstore(sToAccountBalanceKey, add(toAccountBalance, amount))
            }

            function safeTransferFrom(from, to, id, amount, data) {
                _transfer(from, to, id, amount)
                
                if addressIsContract(to) {
                    callOnERC1155Received(from, to, id, amount, data)
                }

                emitTransferSingleEvent(caller(), from, to, id, amount)
            }

            function safeBatchTransferFrom(
                from, 
                to, 
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

                    _transfer(from, to, id, amount)
                }

                if addressIsContract(to) {
                    callOnERC1155BatchReceived(
                        from, 
                        to, 
                        mIdsArrayLengthPointer, 
                        mAmountsArrayLengthPointer, 
                        data
                    )
                }

                emitTransferBatchEvent(
                    caller(), 
                    from, 
                    to, 
                    mIdsArrayLengthPointer,
                    mAmountsArrayLengthPointer 
                )
            }

            function _mint(to, id, amount) {
                revertIfZeroAddress(to)

                let sAccountBalanceKey := getAccountBalanceKey(to, id)
                let accountBalance := sload(sAccountBalanceKey)

                sstore(sAccountBalanceKey, add(accountBalance, amount))
            }
            
            function mint(to, id, amount, data) {
                _mint(to, id, amount)

                emitTransferSingleEvent(caller(), 0x00, to, id, amount)
            }

            function mintBatch(
                toAccount, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer,
                data
            ) {
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := mload(mAmountsArrayLengthPointer)

                revertIfNotEqual(idsArrayLength, amountsArrayLength)

                // For each token id, mint to address
                for { let i := 1 } lt(i, add(idsArrayLength, 1)) { i := add(i, 1) }
                {
                    let id := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))
                    let amount := mload(add(mAmountsArrayLengthPointer, mul(i, 0x20)))

                    _mint(toAccount, id, amount)
                }

                emitTransferBatchEvent(
                    caller(), 
                    0x00, 
                    toAccount, 
                    mIdsArrayLengthPointer, 
                    mAmountsArrayLengthPointer
                )
            }

            function _burn(from, id, amount) {
                revertIfZeroAddress(from)

                let sAccountBalanceKey := getAccountBalanceKey(from, id)
                let accountBalance := sload(sAccountBalanceKey)

                revertIfBalanceInsufficient(accountBalance, amount)

                sstore(sAccountBalanceKey, sub(accountBalance, amount))
            }

            function burn(from, id, amount) {
                _burn(from, id, amount)

                emitTransferSingleEvent(caller(), from, 0x00, id, amount)
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

                    _burn(from, id, amount)
                }

                emitTransferBatchEvent(
                    caller(), 
                    from, 
                    0x00, 
                    mIdsArrayLengthPointer,
                    mAmountsArrayLengthPointer 
                )
            }

            function callOnERC1155Received(from, to, id, amount, data) {
                // Build `onERC1155Received` calldata
                let mFreeMemoryPointer := mload(0x00)
                let mInputPointer := mFreeMemoryPointer
                let onERC1155ReceivedSelector := shl(0xE0, 0xf23a6e61)

                // Function selector
                mstore(mInputPointer, onERC1155ReceivedSelector)
                // address `operator`
                mstore(add(mInputPointer, 0x04), caller())
                // address `from`
                mstore(add(mInputPointer, 0x24), from)
                // uint256 `id`
                mstore(add(mInputPointer, 0x44), id)
                // uint256 `value`
                mstore(add(mInputPointer, 0x64), amount)
                // bytes `data` offset
                mstore(add(mInputPointer, 0x84), 0xa0)
                // bytes `data` length
                let dataLength := 1
                mstore(add(mInputPointer, 0xa4), dataLength)
                // bytes `data` data
                if dataLength {
                    for { let i := 1 } lt(i, add(dataLength, 1)) { i := add(i, 1) }
                    {
                        let bytesData := mload(add(data, mul(i, 0x20)))
                        mstore(add(mInputPointer, add(0xa4, mul(i, 0x20))), bytesData)
                    }
                }

                // Call `onERC1155Received` on `to` contract
                let success := call(
                    gas(), // gas
                    to, // contract address
                    0, // wei to include
                    mInputPointer, // input start
                    add(0xc4, mul(dataLength, 0x20)), // input size
                    mFreeMemoryPointer, // output start
                    0x20 // output size
                )

                if iszero(success) {
                    revert(0, 0)
                }

                let response := mload(mFreeMemoryPointer)

                if iszero(eq(response, onERC1155ReceivedSelector)) {
                    revert(0, 0)
                }
            }

            function callOnERC1155BatchReceived(
                from, 
                to, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer, 
                data
            ) {
                // Build `onERC1155Received` calldata
                let mFreeMemoryPointer := mload(0x00)
                let mInputPointer := mFreeMemoryPointer
                let onERC1155BatchReceivedSelector := shl(0xE0, 0xbc197c81)
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := idsArrayLength

                // Function selector
                mstore(mInputPointer, onERC1155BatchReceivedSelector)
                // address `operator`
                mstore(add(mInputPointer, 0x04), caller())
                // address `from`
                mstore(add(mInputPointer, 0x24), from)
                // uint256[] `ids` offset
                let idsArrayOffset := 0xa0
                mstore(add(mInputPointer, 0x44), idsArrayOffset)
                // uint256[] `values` offset
                let valuesArrayOffset := add(add(idsArrayOffset, 0x20), mul(idsArrayLength, 0x20))
                mstore(add(mInputPointer, 0x64), valuesArrayOffset)
                // bytes `data` offset
                let dataArrayOffset := add(add(valuesArrayOffset, 0x20), mul(amountsArrayLength, 0x20))
                mstore(add(mInputPointer, 0x84), dataArrayOffset)
                // uint256[] `ids` length
                mstore(add(mInputPointer, 0xa4), idsArrayLength)
                // uint256[] `ids` data
                if idsArrayLength {
                    for { let i := 1 } lt(i, add(idsArrayLength, 1)) { i := add(i, 1) }
                    {
                        let idData := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))
                        mstore(add(mInputPointer, add(0xa4, mul(i, 0x20))), idData)
                    }
                }
                // uint256[] `values` length
                // uint256[] `values` data
                
                // bytes `data` length
                // bytes `data` data

                // Call `onERC1155BatchReceived` on `to` contract
                let success := call(
                    gas(), // gas
                    to, // contract address
                    0, // wei to include
                    mInputPointer, // input start
                    add(0xc4, mul(0x20, 0x20)), // input size
                    mFreeMemoryPointer, // output start
                    0x20 // output size
                )

                if iszero(success) {
                    revert(0, 0)
                }

                let response := mload(mFreeMemoryPointer)

                if iszero(eq(response, onERC1155BatchReceivedSelector)) {
                    revert(0, 0)
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

                let mFreeMemoryPointer := mload(0x00)
                let mIdsArrayOffsetPointer := mFreeMemoryPointer
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := mload(mAmountsArrayLengthPointer)
                
                // Store offset of id's array
                mstore(mIdsArrayOffsetPointer, 0x40) 
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                
                // Store offset of amounts array
                mFreeMemoryPointer := mload(0x00)
                let amountsArrayOffset := add(mul(idsArrayLength, 0x20), 0x60)
                mstore(mFreeMemoryPointer, amountsArrayOffset) 
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // Store id's array length
                mFreeMemoryPointer := mload(0x00)
                mstore(mFreeMemoryPointer, idsArrayLength)
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // Store copy of id's array items
                for { let i := 1 } lt(i, add(idsArrayLength, 1)) { i := add(i, 1) }
                {
                    mFreeMemoryPointer := mload(0x00)

                    let value := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))
                    mstore(mFreeMemoryPointer, value)

                    incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                }

                // Store amounts array length
                mFreeMemoryPointer := mload(0x00)
                mstore(mFreeMemoryPointer, amountsArrayLength)
                incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)

                // Store copy of amounts array items
                for { let i := 1 } lt(i, add(amountsArrayLength, 1)) { i := add(i, 1) }
                {
                    mFreeMemoryPointer := mload(0x00)

                    let value := mload(add(mAmountsArrayLengthPointer, mul(i, 0x20)))
                    mstore(mFreeMemoryPointer, value)

                    incrementFreeMemoryPointer(mFreeMemoryPointer, 0x20)
                }

                log4(
                    mIdsArrayOffsetPointer, 
                    add(add(amountsArrayOffset, 0x20), mul(amountsArrayLength, 0x20)), 
                    signatureHash, 
                    operator,
                    from, 
                    to
                )
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

                // let uriLength := sload(uriLengthSlot())

                // Store uri string offset within response
                // mstore(0x00, 0x20)
                // Store uri string length
                // mstore(0x20, uriLength)

                // // Store uri string data
                // for { let i := 1 } lt(i, add(2, div(uriLength, 0x20))) { i := add(i, 1) }
                // {
                //     let dataSlot := add(uriLengthSlot(), i)
                //     let uriData := sload(dataSlot)

                //     mstore(add(0x20, mul(i, 0x20)), uriData)
                // }

                // store value in memory
                // log2(0x00, 0x20, signatureHash, id)
            }

            /**
             * Storage access functions
             */
            function getAccountBalanceKey(account, tokenId) -> sBalanceKey {
                // Balances: mapping uint256 tokenID => (address account => uint256 balance)
                
                // Hash `tokenId` and `balancesSlot()`
                let hashOfIdandBalancesSlot := keccakHashTwoValues(tokenId, balancesSlot())

                // `sBalanceKey` = keccak256(`account`, keccak256(`tokenId`, `balancesSlot()`))
                sBalanceKey := keccakHashTwoValues(account, hashOfIdandBalancesSlot)
            }

            function getOperatorApprovalKey(account, operator) -> sOperatorApprovalKey {
                // Approvals: mapping address account => (address operator => bool approved)

                // Hash `operator` and `operatorApprovalsSlot()`
                let hashOfAccountAndOperatorApprovalsSlot := keccakHashTwoValues(account, operatorApprovalsSlot())

                // `sOperatorApprovalKey` = keccak256(`operator`, keccak256(`account`, `operatorApprovalsSlot()`))
                sOperatorApprovalKey := keccakHashTwoValues(operator, hashOfAccountAndOperatorApprovalsSlot)
            }

            /**
             * Gating functions
             */
            function revertIfPositionNotInCalldata(cdPosition) {
                if lt(calldatasize(), add(cdPosition, 0x20)) {
                    revert(0, 0)
                }
            }

            function revertIfCallerNotOwner() {
                let owner := sload(ownerSlot())

                if iszero(eq(caller(), owner)) {
                    revert(0, 0)
                }
            }

            function revertIfNotValidAddress(address_) {
                if iszero(iszero(and(address_, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            function revertIfZeroAddress(address_) {
                if iszero(address_) {
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

                if iszero(isBool) {
                    revert(0, 0)
                }
            }

            function revertIfBalanceInsufficient(accountBalance, amount) {
                let gte := 0

                if gt(accountBalance, amount) {
                    gte := 1
                }

                if eq(accountBalance, amount) {
                    gte := 1
                }
                
                if iszero(gte) {
                    revert(0, 0)
                }
            }

            function revertIfEqual(valueOne, valueTwo) {
                if eq(valueOne, valueTwo) {
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
                mstore(0x00, add(currentValue, incrementBy))
            }

            function keccakHashTwoValues(valueOne, valueTwo) -> keccakHash {
                let mFreeMemoryPointer := mload(0x00)

                // Store words `valueOne` and `valueTwo` in free memory
                mstore(mFreeMemoryPointer, valueOne)
                mstore(add(mFreeMemoryPointer, 0x20), valueTwo)

                // Store hash of `valueOne` and `valueTwo` in free memory
                mstore(mFreeMemoryPointer, keccak256(mFreeMemoryPointer, 0x40))

                keccakHash := mload(mFreeMemoryPointer)
            }

            function addressIsContract(address_) -> isContract {
                isContract := extcodesize(address_)
            }
        }
    }
}
