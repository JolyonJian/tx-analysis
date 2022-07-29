{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "petersburg",
    "libraries": {},
    "metadata": {
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 2000
    },
    "remappings": [],
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  },
  "sources": {
    "contracts_common/src/BaseWithStorage/Admin.sol": {
      "content": "pragma solidity ^0.5.2;\n\ncontract Admin {\n\n    address internal _admin;\n\n    event AdminChanged(address oldAdmin, address newAdmin);\n\n    /// @notice gives the current administrator of this contract.\n    /// @return the current administrator of this contract.\n    function getAdmin() external view returns (address) {\n        return _admin;\n    }\n\n    /// @notice change the administrator to be `newAdmin`.\n    /// @param newAdmin address of the new administrator.\n    function changeAdmin(address newAdmin) external {\n        require(msg.sender == _admin, \"only admin can change admin\");\n        emit AdminChanged(_admin, newAdmin);\n        _admin = newAdmin;\n    }\n}\n",
      "keccak256": "0x74418caab05cca3fe5b9309ab069a9bfe327ff96f593a347e1f1cc0c02f25693"
    },
    "contracts_common/src/BaseWithStorage/SuperOperators.sol": {
      "content": "pragma solidity ^0.5.2;\n\nimport \"./Admin.sol\";\n\ncontract SuperOperators is Admin {\n\n    mapping(address => bool) internal _superOperators;\n\n    event SuperOperator(address superOperator, bool enabled);\n\n    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).\n    /// @param superOperator address that will be given/removed superOperator right.\n    /// @param enabled set whether the superOperator is enabled or disabled.\n    function setSuperOperator(address superOperator, bool enabled) external {\n        require(\n            msg.sender == _admin,\n            \"only admin is allowed to add super operators\"\n        );\n        _superOperators[superOperator] = enabled;\n        emit SuperOperator(superOperator, enabled);\n    }\n\n    /// @notice check whether address `who` is given superOperator rights.\n    /// @param who The address to query.\n    /// @return whether the address has superOperator rights.\n    function isSuperOperator(address who) public view returns (bool) {\n        return _superOperators[who];\n    }\n}\n",
      "keccak256": "0x22354cf60ccf77a6de61c13bdaf4e3094d115b960ae563b0527622c846a12abb"
    },
    "contracts_common/src/Interfaces/ERC20Events.sol": {
      "content": "pragma solidity ^0.5.2;\n\n/* interface */\ncontract ERC20Events {\n    event Transfer(address indexed from, address indexed to, uint256 value);\n    event Approval(\n        address indexed owner,\n        address indexed spender,\n        uint256 value\n    );\n}\n",
      "keccak256": "0xee09c10a3f9adc913227efdcd94ce44e05b59b04717f8f868153d356bd03f5d2"
    },
    "contracts_common/src/Libraries/BytesUtil.sol": {
      "content": "pragma solidity ^0.5.2;\n\nlibrary BytesUtil {\n    function memcpy(uint256 dest, uint256 src, uint256 len) internal pure {\n        // Copy word-length chunks while possible\n        for (; len >= 32; len -= 32) {\n            assembly {\n                mstore(dest, mload(src))\n            }\n            dest += 32;\n            src += 32;\n        }\n\n        // Copy remaining bytes\n        uint256 mask = 256**(32 - len) - 1;\n        assembly {\n            let srcpart := and(mload(src), not(mask))\n            let destpart := and(mload(dest), mask)\n            mstore(dest, or(destpart, srcpart))\n        }\n    }\n\n    function pointerToBytes(uint256 src, uint256 len)\n        internal\n        pure\n        returns (bytes memory)\n    {\n        bytes memory ret = new bytes(len);\n        uint256 retptr;\n        assembly {\n            retptr := add(ret, 32)\n        }\n\n        memcpy(retptr, src, len);\n        return ret;\n    }\n\n    function addressToBytes(address a) internal pure returns (bytes memory b) {\n        assembly {\n            let m := mload(0x40)\n            mstore(\n                add(m, 20),\n                xor(0x140000000000000000000000000000000000000000, a)\n            )\n            mstore(0x40, add(m, 52))\n            b := m\n        }\n    }\n\n    function uint256ToBytes(uint256 a) internal pure returns (bytes memory b) {\n        assembly {\n            let m := mload(0x40)\n            mstore(add(m, 32), a)\n            mstore(0x40, add(m, 64))\n            b := m\n        }\n    }\n\n    function doFirstParamEqualsAddress(bytes memory data, address _address)\n        internal\n        pure\n        returns (bool)\n    {\n        if (data.length < (36 + 32)) {\n            return false;\n        }\n        uint256 value;\n        assembly {\n            value := mload(add(data, 36))\n        }\n        return value == uint256(_address);\n    }\n\n    function doParamEqualsUInt256(bytes memory data, uint256 i, uint256 value)\n        internal\n        pure\n        returns (bool)\n    {\n        if (data.length < (36 + (i + 1) * 32)) {\n            return false;\n        }\n        uint256 offset = 36 + i * 32;\n        uint256 valuePresent;\n        assembly {\n            valuePresent := mload(add(data, offset))\n        }\n        return valuePresent == value;\n    }\n\n    function overrideFirst32BytesWithAddress(\n        bytes memory data,\n        address _address\n    ) internal pure returns (bytes memory) {\n        uint256 dest;\n        assembly {\n            dest := add(data, 48)\n        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)\n\n        bytes memory addressBytes = addressToBytes(_address);\n        uint256 src;\n        assembly {\n            src := add(addressBytes, 32)\n        }\n\n        memcpy(dest, src, 20);\n        return data;\n    }\n\n    function overrideFirstTwo32BytesWithAddressAndInt(\n        bytes memory data,\n        address _address,\n        uint256 _value\n    ) internal pure returns (bytes memory) {\n        uint256 dest;\n        uint256 src;\n\n        assembly {\n            dest := add(data, 48)\n        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)\n        bytes memory bbytes = addressToBytes(_address);\n        assembly {\n            src := add(bbytes, 32)\n        }\n        memcpy(dest, src, 20);\n\n        assembly {\n            dest := add(data, 68)\n        } // 48 = 32 (offset) + 4 (func sig) + 32 (next slot)\n        bbytes = uint256ToBytes(_value);\n        assembly {\n            src := add(bbytes, 32)\n        }\n        memcpy(dest, src, 32);\n\n        return data;\n    }\n}\n",
      "keccak256": "0xb5c236938e1f71524127371a015836e83103c5ac1b4ed7b7f22892a8c0429e10"
    },
    "src/Sand.sol": {
      "content": "pragma solidity 0.5.9;\n\nimport \"./Sand/erc20/ERC20ExecuteExtension.sol\";\nimport \"./Sand/erc20/ERC20BaseToken.sol\";\nimport \"./Sand/erc20/ERC20BasicApproveExtension.sol\";\n\ncontract Sand is ERC20ExecuteExtension, ERC20BasicApproveExtension, ERC20BaseToken {\n\n    constructor(address sandAdmin, address executionAdmin, address beneficiary) public {\n        _admin = sandAdmin;\n        _executionAdmin = executionAdmin;\n        _mint(beneficiary, 3000000000000000000000000000);\n    }\n\n    /// @notice A descriptive name for the tokens\n    /// @return name of the tokens\n    function name() public view returns (string memory) {\n        return \"SAND\";\n    }\n\n    /// @notice An abbreviated name for the tokens\n    /// @return symbol of the tokens\n    function symbol() public view returns (string memory) {\n        return \"SAND\";\n    }\n\n}\n",
      "keccak256": "0xe05c8232fddc05f34648fa1db29cbfff2d163357e613425a925d80dbefff75eb"
    },
    "src/Sand/erc20/ERC20BaseToken.sol": {
      "content": "pragma solidity 0.5.9;\n\nimport \"../../../contracts_common/src/Interfaces/ERC20Events.sol\";\nimport \"../../../contracts_common/src/BaseWithStorage/SuperOperators.sol\";\n\ncontract ERC20BaseToken is SuperOperators, ERC20Events {\n\n    uint256 internal _totalSupply;\n    mapping(address => uint256) internal _balances;\n    mapping(address => mapping(address => uint256)) internal _allowances;\n\n    /// @notice Gets the total number of tokens in existence.\n    /// @return the total number of tokens in existence.\n    function totalSupply() public view returns (uint256) {\n        return _totalSupply;\n    }\n\n    /// @notice Gets the balance of `owner`.\n    /// @param owner The address to query the balance of.\n    /// @return The amount owned by `owner`.\n    function balanceOf(address owner) public view returns (uint256) {\n        return _balances[owner];\n    }\n\n    /// @notice gets allowance of `spender` for `owner`'s tokens.\n    /// @param owner address whose token is allowed.\n    /// @param spender address allowed to transfer.\n    /// @return the amount of token `spender` is allowed to transfer on behalf of `owner`.\n    function allowance(address owner, address spender)\n        public\n        view\n        returns (uint256 remaining)\n    {\n        return _allowances[owner][spender];\n    }\n\n    /// @notice returns the number of decimals for that token.\n    /// @return the number of decimals.\n    function decimals() public view returns (uint8) {\n        return uint8(18);\n    }\n\n    /// @notice Transfer `amount` tokens to `to`.\n    /// @param to the recipient address of the tokens transfered.\n    /// @param amount the number of tokens transfered.\n    /// @return true if success.\n    function transfer(address to, uint256 amount)\n        public\n        returns (bool success)\n    {\n        _transfer(msg.sender, to, amount);\n        return true;\n    }\n\n    /// @notice Transfer `amount` tokens from `from` to `to`.\n    /// @param from whose token it is transferring from.\n    /// @param to the recipient address of the tokens transfered.\n    /// @param amount the number of tokens transfered.\n    /// @return true if success.\n    function transferFrom(address from, address to, uint256 amount)\n        public\n        returns (bool success)\n    {\n        if (msg.sender != from && !_superOperators[msg.sender]) {\n            uint256 currentAllowance = _allowances[from][msg.sender];\n            if (currentAllowance != (2**256) - 1) {\n                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)\n                require(currentAllowance >= amount, \"Not enough funds allowed\");\n                _allowances[from][msg.sender] = currentAllowance - amount;\n            }\n        }\n        _transfer(from, to, amount);\n        return true;\n    }\n\n    /// @notice burn `amount` tokens.\n    /// @param amount the number of tokens to burn.\n    /// @return true if success.\n    function burn(uint256 amount) external returns (bool) {\n        _burn(msg.sender, amount);\n        return true;\n    }\n\n    /// @notice burn `amount` tokens from `owner`.\n    /// @param owner address whose token is to burn.\n    /// @param amount the number of token to burn.\n    /// @return true if success.\n    function burnFor(address owner, uint256 amount) external returns (bool) {\n        _burn(owner, amount);\n        return true;\n    }\n\n    /// @notice approve `spender` to transfer `amount` tokens.\n    /// @param spender address to be given rights to transfer.\n    /// @param amount the number of tokens allowed.\n    /// @return true if success.\n    function approve(address spender, uint256 amount)\n        public\n        returns (bool success)\n    {\n        _approveFor(msg.sender, spender, amount);\n        return true;\n    }\n\n    /// @notice approve `spender` to transfer `amount` tokens from `owner`.\n    /// @param owner address whose token is allowed.\n    /// @param spender  address to be given rights to transfer.\n    /// @param amount the number of tokens allowed.\n    /// @return true if success.\n    function approveFor(address owner, address spender, uint256 amount)\n        public\n        returns (bool success)\n    {\n        require(\n            msg.sender == owner || _superOperators[msg.sender],\n            \"msg.sender != owner && !superOperator\"\n        );\n        _approveFor(owner, spender, amount);\n        return true;\n    }\n\n    function addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded)\n        public\n        returns (bool success)\n    {\n        require(\n            msg.sender == owner || _superOperators[msg.sender],\n            \"msg.sender != owner && !superOperator\"\n        );\n        _addAllowanceIfNeeded(owner, spender, amountNeeded);\n        return true;\n    }\n\n    function _addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded)\n        internal\n    {\n        if(amountNeeded > 0 && !isSuperOperator(spender)) {\n            uint256 currentAllowance = _allowances[owner][spender];\n            if(currentAllowance < amountNeeded) {\n                _approveFor(owner, spender, amountNeeded);\n            }\n        }\n    }\n\n    function _approveFor(address owner, address spender, uint256 amount)\n        internal\n    {\n        require(\n            owner != address(0) && spender != address(0),\n            \"Cannot approve with 0x0\"\n        );\n        _allowances[owner][spender] = amount;\n        emit Approval(owner, spender, amount);\n    }\n\n    function _transfer(address from, address to, uint256 amount) internal {\n        require(to != address(0), \"Cannot send to 0x0\");\n        uint256 currentBalance = _balances[from];\n        require(currentBalance >= amount, \"not enough fund\");\n        _balances[from] = currentBalance - amount;\n        _balances[to] += amount;\n        emit Transfer(from, to, amount);\n    }\n\n    function _mint(address to, uint256 amount) internal {\n        require(to != address(0), \"Cannot mint to 0x0\");\n        require(amount > 0, \"cannot mint 0 tokens\");\n        uint256 currentTotalSupply = _totalSupply;\n        uint256 newTotalSupply = currentTotalSupply + amount;\n        require(newTotalSupply > currentTotalSupply, \"overflow\");\n        _totalSupply = newTotalSupply;\n        _balances[to] += amount;\n        emit Transfer(address(0), to, amount);\n    }\n\n    function _burn(address from, uint256 amount) internal {\n        require(amount > 0, \"cannot burn 0 tokens\");\n        if (msg.sender != from && !_superOperators[msg.sender]) {\n            uint256 currentAllowance = _allowances[from][msg.sender];\n            require(\n                currentAllowance >= amount,\n                \"Not enough funds allowed\"\n            );\n            if (currentAllowance != (2**256) - 1) {\n                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)\n                _allowances[from][msg.sender] = currentAllowance - amount;\n            }\n        }\n\n        uint256 currentBalance = _balances[from];\n        require(currentBalance >= amount, \"Not enough funds\");\n        _balances[from] = currentBalance - amount;\n        _totalSupply -= amount;\n        emit Transfer(from, address(0), amount);\n    }\n}\n",
      "keccak256": "0xc70b1452852cbe8f437ba3fdcff911ed3fd7820b0d853e5fe147a90989cc1085"
    },
    "src/Sand/erc20/ERC20BasicApproveExtension.sol": {
      "content": "pragma solidity 0.5.9;\n\nimport \"../../../contracts_common/src/Libraries/BytesUtil.sol\";\n\ncontract ERC20BasicApproveExtension {\n\n    /// @notice approve `target` to spend `amount` and call it with data.\n    /// @param target address to be given rights to transfer and destination of the call.\n    /// @param amount the number of tokens allowed.\n    /// @param data bytes for the call.\n    /// @return data of the call.\n    function approveAndCall(\n        address target,\n        uint256 amount,\n        bytes calldata data\n    ) external payable returns (bytes memory) {\n        require(\n            BytesUtil.doFirstParamEqualsAddress(data, msg.sender),\n            \"first param != sender\"\n        );\n\n        _approveFor(msg.sender, target, amount);\n\n        // solium-disable-next-line security/no-call-value\n        (bool success, bytes memory returnData) = target.call.value(msg.value)(data);\n        require(success, string(returnData));\n        return returnData;\n    }\n\n    /// @notice temporarly approve `target` to spend `amount` and call it with data. Previous approvals remains unchanged.\n    /// @param target destination of the call, allowed to spend the amount specified\n    /// @param amount the number of tokens allowed to spend.\n    /// @param data bytes for the call.\n    /// @return data of the call.\n    function paidCall(\n        address target,\n        uint256 amount,\n        bytes calldata data\n    ) external payable returns (bytes memory) {\n        require(\n            BytesUtil.doFirstParamEqualsAddress(data, msg.sender),\n            \"first param != sender\"\n        );\n\n        if (amount > 0) {\n            _addAllowanceIfNeeded(msg.sender, target, amount);\n        }\n\n        // solium-disable-next-line security/no-call-value\n        (bool success, bytes memory returnData) = target.call.value(msg.value)(data);\n        require(success, string(returnData));\n\n        return returnData;\n    }\n\n    function _approveFor(address owner, address target, uint256 amount) internal;\n    function _addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) internal;\n}\n",
      "keccak256": "0xbd8c882843acf82adb849222068490302925e31ac66305b75f1663a719c7fc37"
    },
    "src/Sand/erc20/ERC20ExecuteExtension.sol": {
      "content": "pragma solidity 0.5.9;\n\n\ncontract ERC20ExecuteExtension {\n\n    /// @dev _executionAdmin != _admin so that this super power can be disabled independently\n    address internal _executionAdmin;\n\n    event ExecutionAdminAdminChanged(address oldAdmin, address newAdmin);\n\n    /// @notice give the address responsible for adding execution rights.\n    /// @return address of the execution administrator.\n    function getExecutionAdmin() external view returns (address) {\n        return _executionAdmin;\n    }\n\n    /// @notice change the execution adminstrator to be `newAdmin`.\n    /// @param newAdmin address of the new administrator.\n    function changeExecutionAdmin(address newAdmin) external {\n        require(msg.sender == _executionAdmin, \"only executionAdmin can change executionAdmin\");\n        emit ExecutionAdminAdminChanged(_executionAdmin, newAdmin);\n        _executionAdmin = newAdmin;\n    }\n\n    mapping(address => bool) internal _executionOperators;\n    event ExecutionOperator(address executionOperator, bool enabled);\n\n    /// @notice set `executionOperator` as executionOperator: `enabled`.\n    /// @param executionOperator address that will be given/removed executionOperator right.\n    /// @param enabled set whether the executionOperator is enabled or disabled.\n    function setExecutionOperator(address executionOperator, bool enabled) external {\n        require(\n            msg.sender == _executionAdmin,\n            \"only execution admin is allowed to add execution operators\"\n        );\n        _executionOperators[executionOperator] = enabled;\n        emit ExecutionOperator(executionOperator, enabled);\n    }\n\n    /// @notice check whether address `who` is given executionOperator rights.\n    /// @param who The address to query.\n    /// @return whether the address has executionOperator rights.\n    function isExecutionOperator(address who) public view returns (bool) {\n        return _executionOperators[who];\n    }\n\n    /// @notice execute on behalf of the contract.\n    /// @param to destination address fo the call.\n    /// @param gasLimit exact amount of gas to be passed to the call.\n    /// @param data the bytes sent to the destination address.\n    /// @return success whether the execution was successful.\n    /// @return returnData data resulting from the execution.\n    function executeWithSpecificGas(address to, uint256 gasLimit, bytes calldata data) external returns (bool success, bytes memory returnData) {\n        require(_executionOperators[msg.sender], \"only execution operators allowed to execute on SAND behalf\");\n        (success, returnData) = to.call.gas(gasLimit)(data);\n        assert(gasleft() > gasLimit / 63); // not enough gas provided, assert to throw all gas // TODO use EIP-1930\n    }\n\n    /// @notice approve a specific amount of token for `from` and execute on behalf of the contract.\n    /// @param from address of which token will be transfered.\n    /// @param to destination address fo the call.\n    /// @param amount number of tokens allowed that can be transfer by the code at `to`.\n    /// @param gasLimit exact amount of gas to be passed to the call.\n    /// @param data the bytes sent to the destination address.\n    /// @return success whether the execution was successful.\n    /// @return returnData data resulting from the execution.\n    function approveAndExecuteWithSpecificGas(\n        address from,\n        address to,\n        uint256 amount,\n        uint256 gasLimit,\n        bytes calldata data\n    ) external returns (bool success, bytes memory returnData) {\n        require(_executionOperators[msg.sender], \"only execution operators allowed to execute on SAND behalf\");\n        return _approveAndExecuteWithSpecificGas(from, to, amount, gasLimit, data);\n    }\n\n    /// @dev the reason for this function is that charging for gas here is more gas-efficient than doing it in the caller.\n    /// @notice approve a specific amount of token for `from` and execute on behalf of the contract. Plus charge the gas required to perform it.\n    /// @param from address of which token will be transfered.\n    /// @param to destination address fo the call.\n    /// @param amount number of tokens allowed that can be transfer by the code at `to`.\n    /// @param gasLimit exact amount of gas to be passed to the call.\n    /// @param tokenGasPrice price in token for the gas to be charged.\n    /// @param baseGasCharge amount of gas charged on top of the gas used for the call.\n    /// @param tokenReceiver recipient address of the token charged for the gas used.\n    /// @param data the bytes sent to the destination address.\n    /// @return success whether the execution was successful.\n    /// @return returnData data resulting from the execution.\n    function approveAndExecuteWithSpecificGasAndChargeForIt(\n        address from,\n        address to,\n        uint256 amount,\n        uint256 gasLimit,\n        uint256 tokenGasPrice,\n        uint256 baseGasCharge,\n        address tokenReceiver,\n        bytes calldata data\n    ) external returns (bool success, bytes memory returnData) {\n        uint256 initialGas = gasleft();\n        require(_executionOperators[msg.sender], \"only execution operators allowed to execute on SAND behalf\");\n        (success, returnData) = _approveAndExecuteWithSpecificGas(from, to, amount, gasLimit, data);\n        if (tokenGasPrice > 0) {\n            _charge(from, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);\n        }\n    }\n\n    /// @notice transfer 1amount1 token from `from` to `to` and charge the gas required to perform that transfer.\n    /// @param from address of which token will be transfered.\n    /// @param to destination address fo the call.\n    /// @param amount number of tokens allowed that can be transfer by the code at `to`.\n    /// @param gasLimit exact amount of gas to be passed to the call.\n    /// @param tokenGasPrice price in token for the gas to be charged.\n    /// @param baseGasCharge amount of gas charged on top of the gas used for the call.\n    /// @param tokenReceiver recipient address of the token charged for the gas used.\n    /// @return whether the transfer was successful.\n    function transferAndChargeForGas(\n        address from,\n        address to,\n        uint256 amount,\n        uint256 gasLimit,\n        uint256 tokenGasPrice,\n        uint256 baseGasCharge,\n        address tokenReceiver\n    ) external returns (bool) {\n        uint256 initialGas = gasleft();\n        require(_executionOperators[msg.sender], \"only execution operators allowed to perfrom transfer and charge\");\n        _transfer(from, to, amount);\n        if (tokenGasPrice > 0) {\n            _charge(from, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);\n        }\n        return true;\n    }\n\n    function _charge(\n        address from,\n        uint256 gasLimit,\n        uint256 tokenGasPrice,\n        uint256 initialGas,\n        uint256 baseGasCharge,\n        address tokenReceiver\n    ) internal {\n        uint256 gasCharge = initialGas - gasleft();\n        if(gasCharge > gasLimit) {\n            gasCharge = gasLimit;\n        }\n        gasCharge += baseGasCharge;\n        uint256 tokensToCharge = gasCharge * tokenGasPrice;\n        require(tokensToCharge / gasCharge == tokenGasPrice, \"overflow\");\n        _transfer(from, tokenReceiver, tokensToCharge);\n    }\n\n    function _approveAndExecuteWithSpecificGas(\n        address from,\n        address to,\n        uint256 amount,\n        uint256 gasLimit,\n        bytes memory data\n    ) internal returns (bool success, bytes memory returnData) {\n\n        if (amount > 0) {\n            _addAllowanceIfNeeded(from, to, amount);\n        }\n        (success, returnData) = to.call.gas(gasLimit)(data);\n        assert(gasleft() > gasLimit / 63); // not enough gas provided, assert to throw all gas // TODO use EIP-1930\n    }\n\n\n    function _transfer(address from, address to, uint256 amount) internal;\n    function _addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) internal;\n}",
      "keccak256": "0x4b9a75299ab80e84aa287f2ecf2ef175e0feb074764e4a670f9397a2d2d4bda8"
    }
  }
}}