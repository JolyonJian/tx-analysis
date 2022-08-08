// contracts_common/src/BaseWithStorage/Admin.sol

pragma solidity ^0.5.2;

contract Admin {

    address internal _admin;

    event AdminChanged(address oldAdmin, address newAdmin);

    /// @notice gives the current administrator of this contract.
    /// @return the current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @notice change the administrator to be `newAdmin`.
    /// @param newAdmin address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "only admin can change admin");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}


// contracts_common/src/BaseWithStorage/Admin.sol

0x74418caab05cca3fe5b9309ab069a9bfe327ff96f593a347e1f1cc0c02f25693

