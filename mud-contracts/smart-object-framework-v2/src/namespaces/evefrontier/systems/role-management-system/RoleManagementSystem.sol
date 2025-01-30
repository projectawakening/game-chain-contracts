/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { Role, RoleData } from "../../codegen/tables/Role.sol";
import { HasRole } from "../../codegen/tables/HasRole.sol";

import { IRoleManagementSystem } from "../../interfaces/IRoleManagementSystem.sol";

import { SmartObjectFramework } from "../../../../inherit/SmartObjectFramework.sol";

/**
 * @title Role Management System
 * @author CCP Games
 * @notice Handles role-based membership management
 * @dev Implements role creation, administration, and membership management functionality
 * @dev IMPORTANT: all state changing functions implement the `enforceCallCount(1)` modifier, which means (for security enforcement) they must be directly called from a MUD World entry point, not another MUD System
 */
contract RoleManagementSystem is IRoleManagementSystem, SmartObjectFramework {
  /**
   * @dev Modifier that checks if `account` is a member of a specific role with `roleId`. Reverts
   * with an {AccessControlUnauthorizedAccount} error, if the `account` is not a member.
   * @param role The role identifier to check
   * @param account The address to verify role membership for
   */
  modifier onlyRole(bytes32 role, address account) {
    _checkRole(role, account);
    _;
  }

  /**
   * @notice Create a new `role` with specified `admin` role
   * @dev Creates a new entry in the {Role} table assigning an admin value, and exsitence
   *   flag under the `role` key. NOTE: If `role` and `admin` are identical, then creates self-administered role
   * @param role The identifier for the new role
   * @param admin The identifier for the admin role
   */
  function createRole(bytes32 role, bytes32 admin) external context {
    if (role == bytes32(0) || admin == bytes32(0)) {
      revert RoleManagement_InvalidRole();
    }

    if (Role.getExists(role)) {
      revert RoleManagement_RoleAlreadyCreated(role);
    }

    if (role == admin) {
      _createRole(role, admin);
      _grantRole(role, _callMsgSender(1));
    } else {
      _checkRole(admin, _callMsgSender(1));
      _createRole(role, admin);
    }
  }

  /**
   * @notice Updates the admin role for an existing `role`
   * @dev Updates the admin value in the {Role} table with `newAdmin` for the key `role`.
   * @param role The role to modify
   * @param newAdmin The new admin role to set
   */
  function transferRoleAdmin(
    bytes32 role,
    bytes32 newAdmin
  ) external context enforceCallCount(1) onlyRole(Role.getAdmin(role), _callMsgSender(1)) {
    _setRoleAdmin(role, newAdmin);
  }

  /**
   * @notice Grants role membership to an account.
   * @dev Updates the {HasRole} table with `hasRole` = true, for the keys `role`,`account`
   * @param role The role to grant membership for
   * @param account The account to grant as a member.
   */
  function grantRole(bytes32 role, address account) external context onlyRole(Role.getAdmin(role), _callMsgSender(1)) {
    _grantRole(role, account);
  }

  /**
   * @notice Revokes role membership of an account.
   * @dev Updates the {HasRole} table with `hasRole` = false, for the keys `role`,`account`
   * @param role The role to revoke membership for
   * @param account The account to remove as a member
   */
  function revokeRole(
    bytes32 role,
    address account
  ) external context enforceCallCount(1) onlyRole(Role.getAdmin(role), _callMsgSender(1)) {
    if (account == _callMsgSender(1)) {
      revert RoleManagement_MustRenounceSelf();
    }
    _revokeRole(role, account);
  }

  /**
   * @notice Allows users to revoke their own role membership (as a seperate explicit function so accounts don't accidentally revoke themselves)
   * @dev Updates the {HasRole} table with `hasRole` = false, for the keys `role`,`callerConfirmation`
   * @param role The role to revoke account membership for
   * @param callerConfirmation Address of the world entry point caller for verification
   */
  function renounceRole(bytes32 role, address callerConfirmation) external context enforceCallCount(1) {
    if (callerConfirmation != _callMsgSender(1)) {
      revert RoleManagement_BadConfirmation();
    }

    _revokeRole(role, callerConfirmation);
  }

  /**
   * @dev Internal role verification. Reverts with an {RoleManagement_UnauthorizedAccount} error if `account`
   * @param role Role to verify
   * @param account Account to check membership of
   */
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!HasRole.get(role, account)) {
      revert RoleManagement_UnauthorizedAccount(role, account);
    }
  }

  /**
   * @dev Internal role creation logic
   * @param role Role to create
   * @param admin Admin role to assign
   */
  function _createRole(bytes32 role, bytes32 admin) internal virtual {
    Role.set(role, true, bytes32(0));

    _setRoleAdmin(role, admin);
  }

  /**
   * @dev Internal admin update logic
   * @param role Role to modify
   * @param admin New admin role
   */
  function _setRoleAdmin(bytes32 role, bytes32 admin) internal virtual {
    RoleData memory roleData = Role.get(role);
    RoleData memory adminData = Role.get(admin);

    if (!adminData.exists) {
      revert RoleManagement_RoleDoesNotExist(admin);
    }

    if (roleData.admin == admin) {
      revert RoleManagement_AdminAlreadyAssigned(role, admin);
    }

    Role.setAdmin(role, admin);
  }

  /**
   * @dev Attempts to grant `role` membership to `account` (if HasRole.hasRole is false)
   * @param role Role to grant
   * @param account Role membership recipient address
   */
  function _grantRole(bytes32 role, address account) internal virtual {
    if (!HasRole.get(role, account)) {
      HasRole.set(role, account, true);
    }
  }

  /**
   * @dev Attempts to revoke `role` membership for `account` (if HasRole.hasRole is true)
   * @param role Role to revoke
   * @param account Address to revoke role membership from
   */
  function _revokeRole(bytes32 role, address account) internal virtual {
    if (HasRole.get(role, account)) {
      HasRole.set(role, account, false);
    }
  }
}
