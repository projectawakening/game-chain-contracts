// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { AccessSystem } from "../../systems/access-systems/AccessSystem.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { IWorldCall } from "@latticexyz/world/src/IWorldKernel.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

type AccessSystemType is bytes32;

// equivalent to WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "evefrontier", name: "AccessSystem" }))
AccessSystemType constant accessSystem = AccessSystemType.wrap(
  0x737965766566726f6e7469657200000041636365737353797374656d00000000
);

struct CallWrapper {
  ResourceId systemId;
  address from;
}

struct RootCallWrapper {
  ResourceId systemId;
  address from;
}

/**
 * @title AccessSystemLib
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This library is automatically generated from the corresponding system contract. Do not edit manually.
 */
library AccessSystemLib {
  error AccessSystemLib_CallingFromRootSystem();
  error Access_NotAdmin(address caller);
  error Access_NotDeployableOwner(address caller, uint256 objectId);
  error Access_NotAdminOrOwner(address caller, uint256 objectId);
  error Access_NotOwnerOrCanWithdrawFromInventory(address caller, uint256 objectId);
  error Access_NotOwnerOrCanDepositToInventory(address caller, uint256 objectId);
  error Access_NotDeployableOwnerOrInventoryInteractSystem(address caller, uint256 objectId);
  error Access_NotInventoryAdmin(address caller, uint256 smartObjectId);
  error Access_NotAdminOrDeployableSystem(address caller, uint256 objectId);

  function onlyOwnerOrCanWithdrawFromInventory(
    AccessSystemType self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyOwnerOrCanWithdrawFromInventory(objectId, data);
  }

  function onlyOwnerOrCanDepositToInventory(AccessSystemType self, uint256 objectId, bytes memory data) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyOwnerOrCanDepositToInventory(objectId, data);
  }

  function onlyDeployableOwner(AccessSystemType self, uint256 objectId, bytes memory data) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyDeployableOwner(objectId, data);
  }

  function onlyAdmin(AccessSystemType self, uint256 objectId, bytes memory data) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyAdmin(objectId, data);
  }

  function onlyAdminOrDeployableOwner(AccessSystemType self, uint256 objectId, bytes memory data) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyAdminOrDeployableOwner(objectId, data);
  }

  function onlyDeployableOwnerOrInventoryInteractSystem(
    AccessSystemType self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyDeployableOwnerOrInventoryInteractSystem(objectId, data);
  }

  function onlyInventoryAdmin(AccessSystemType self, uint256 smartObjectId, bytes memory data) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyInventoryAdmin(smartObjectId, data);
  }

  function onlyAdminOrDeployableSystem(AccessSystemType self, uint256 objectId, bytes memory data) internal view {
    return CallWrapper(self.toResourceId(), address(0)).onlyAdminOrDeployableSystem(objectId, data);
  }

  function isAdmin(AccessSystemType self, address caller) internal view returns (bool) {
    return CallWrapper(self.toResourceId(), address(0)).isAdmin(caller);
  }

  function isOwner(AccessSystemType self, address caller, uint256 objectId) internal view returns (bool) {
    return CallWrapper(self.toResourceId(), address(0)).isOwner(caller, objectId);
  }

  function canWithdrawFromInventory(
    AccessSystemType self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    return CallWrapper(self.toResourceId(), address(0)).canWithdrawFromInventory(smartObjectId, caller);
  }

  function canDepositToInventory(
    AccessSystemType self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    return CallWrapper(self.toResourceId(), address(0)).canDepositToInventory(smartObjectId, caller);
  }

  function isInventoryInteractSystem(AccessSystemType self, address caller) internal view returns (bool) {
    return CallWrapper(self.toResourceId(), address(0)).isInventoryInteractSystem(caller);
  }

  function isInventoryAdmin(AccessSystemType self, uint256 smartObjectId, address caller) internal view returns (bool) {
    return CallWrapper(self.toResourceId(), address(0)).isInventoryAdmin(smartObjectId, caller);
  }

  function isDeployableSystem(AccessSystemType self, address caller) internal view returns (bool) {
    return CallWrapper(self.toResourceId(), address(0)).isDeployableSystem(caller);
  }

  function onlyOwnerOrCanWithdrawFromInventory(
    CallWrapper memory self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _onlyOwnerOrCanWithdrawFromInventory_uint256_bytes.onlyOwnerOrCanWithdrawFromInventory,
      (objectId, data)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function onlyOwnerOrCanDepositToInventory(
    CallWrapper memory self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _onlyOwnerOrCanDepositToInventory_uint256_bytes.onlyOwnerOrCanDepositToInventory,
      (objectId, data)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function onlyDeployableOwner(CallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_onlyDeployableOwner_uint256_bytes.onlyDeployableOwner, (objectId, data));
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function onlyAdmin(CallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_onlyAdmin_uint256_bytes.onlyAdmin, (objectId, data));
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function onlyAdminOrDeployableOwner(CallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _onlyAdminOrDeployableOwner_uint256_bytes.onlyAdminOrDeployableOwner,
      (objectId, data)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function onlyDeployableOwnerOrInventoryInteractSystem(
    CallWrapper memory self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _onlyDeployableOwnerOrInventoryInteractSystem_uint256_bytes.onlyDeployableOwnerOrInventoryInteractSystem,
      (objectId, data)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function onlyInventoryAdmin(CallWrapper memory self, uint256 smartObjectId, bytes memory data) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _onlyInventoryAdmin_uint256_bytes.onlyInventoryAdmin,
      (smartObjectId, data)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function onlyAdminOrDeployableSystem(CallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _onlyAdminOrDeployableSystem_uint256_bytes.onlyAdminOrDeployableSystem,
      (objectId, data)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);
    abi.decode(returnData, (bytes));
  }

  function isAdmin(CallWrapper memory self, address caller) internal view returns (bool) {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_isAdmin_address.isAdmin, (caller));
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);

    bytes memory result = abi.decode(returnData, (bytes));
    return abi.decode(result, (bool));
  }

  function isOwner(CallWrapper memory self, address caller, uint256 objectId) internal view returns (bool) {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_isOwner_address_uint256.isOwner, (caller, objectId));
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);

    bytes memory result = abi.decode(returnData, (bytes));
    return abi.decode(result, (bool));
  }

  function canWithdrawFromInventory(
    CallWrapper memory self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _canWithdrawFromInventory_uint256_address.canWithdrawFromInventory,
      (smartObjectId, caller)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);

    bytes memory result = abi.decode(returnData, (bytes));
    return abi.decode(result, (bool));
  }

  function canDepositToInventory(
    CallWrapper memory self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _canDepositToInventory_uint256_address.canDepositToInventory,
      (smartObjectId, caller)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);

    bytes memory result = abi.decode(returnData, (bytes));
    return abi.decode(result, (bool));
  }

  function isInventoryInteractSystem(CallWrapper memory self, address caller) internal view returns (bool) {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_isInventoryInteractSystem_address.isInventoryInteractSystem, (caller));
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);

    bytes memory result = abi.decode(returnData, (bytes));
    return abi.decode(result, (bool));
  }

  function isInventoryAdmin(
    CallWrapper memory self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(
      _isInventoryAdmin_uint256_address.isInventoryAdmin,
      (smartObjectId, caller)
    );
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);

    bytes memory result = abi.decode(returnData, (bytes));
    return abi.decode(result, (bool));
  }

  function isDeployableSystem(CallWrapper memory self, address caller) internal view returns (bool) {
    // if the contract calling this function is a root system, it should use `callAsRoot`
    if (address(_world()) == address(this)) revert AccessSystemLib_CallingFromRootSystem();

    bytes memory systemCall = abi.encodeCall(_isDeployableSystem_address.isDeployableSystem, (caller));
    bytes memory worldCall = self.from == address(0)
      ? abi.encodeCall(IWorldCall.call, (self.systemId, systemCall))
      : abi.encodeCall(IWorldCall.callFrom, (self.from, self.systemId, systemCall));
    (bool success, bytes memory returnData) = address(_world()).staticcall(worldCall);
    if (!success) revertWithBytes(returnData);

    bytes memory result = abi.decode(returnData, (bytes));
    return abi.decode(result, (bool));
  }

  function onlyOwnerOrCanWithdrawFromInventory(
    RootCallWrapper memory self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    bytes memory systemCall = abi.encodeCall(
      _onlyOwnerOrCanWithdrawFromInventory_uint256_bytes.onlyOwnerOrCanWithdrawFromInventory,
      (objectId, data)
    );
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function onlyOwnerOrCanDepositToInventory(
    RootCallWrapper memory self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    bytes memory systemCall = abi.encodeCall(
      _onlyOwnerOrCanDepositToInventory_uint256_bytes.onlyOwnerOrCanDepositToInventory,
      (objectId, data)
    );
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function onlyDeployableOwner(RootCallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    bytes memory systemCall = abi.encodeCall(_onlyDeployableOwner_uint256_bytes.onlyDeployableOwner, (objectId, data));
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function onlyAdmin(RootCallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    bytes memory systemCall = abi.encodeCall(_onlyAdmin_uint256_bytes.onlyAdmin, (objectId, data));
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function onlyAdminOrDeployableOwner(RootCallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    bytes memory systemCall = abi.encodeCall(
      _onlyAdminOrDeployableOwner_uint256_bytes.onlyAdminOrDeployableOwner,
      (objectId, data)
    );
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function onlyDeployableOwnerOrInventoryInteractSystem(
    RootCallWrapper memory self,
    uint256 objectId,
    bytes memory data
  ) internal view {
    bytes memory systemCall = abi.encodeCall(
      _onlyDeployableOwnerOrInventoryInteractSystem_uint256_bytes.onlyDeployableOwnerOrInventoryInteractSystem,
      (objectId, data)
    );
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function onlyInventoryAdmin(RootCallWrapper memory self, uint256 smartObjectId, bytes memory data) internal view {
    bytes memory systemCall = abi.encodeCall(
      _onlyInventoryAdmin_uint256_bytes.onlyInventoryAdmin,
      (smartObjectId, data)
    );
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function onlyAdminOrDeployableSystem(RootCallWrapper memory self, uint256 objectId, bytes memory data) internal view {
    bytes memory systemCall = abi.encodeCall(
      _onlyAdminOrDeployableSystem_uint256_bytes.onlyAdminOrDeployableSystem,
      (objectId, data)
    );
    SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
  }

  function isAdmin(RootCallWrapper memory self, address caller) internal view returns (bool) {
    bytes memory systemCall = abi.encodeCall(_isAdmin_address.isAdmin, (caller));

    bytes memory result = SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
    return abi.decode(result, (bool));
  }

  function isOwner(RootCallWrapper memory self, address caller, uint256 objectId) internal view returns (bool) {
    bytes memory systemCall = abi.encodeCall(_isOwner_address_uint256.isOwner, (caller, objectId));

    bytes memory result = SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
    return abi.decode(result, (bool));
  }

  function canWithdrawFromInventory(
    RootCallWrapper memory self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    bytes memory systemCall = abi.encodeCall(
      _canWithdrawFromInventory_uint256_address.canWithdrawFromInventory,
      (smartObjectId, caller)
    );

    bytes memory result = SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
    return abi.decode(result, (bool));
  }

  function canDepositToInventory(
    RootCallWrapper memory self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    bytes memory systemCall = abi.encodeCall(
      _canDepositToInventory_uint256_address.canDepositToInventory,
      (smartObjectId, caller)
    );

    bytes memory result = SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
    return abi.decode(result, (bool));
  }

  function isInventoryInteractSystem(RootCallWrapper memory self, address caller) internal view returns (bool) {
    bytes memory systemCall = abi.encodeCall(_isInventoryInteractSystem_address.isInventoryInteractSystem, (caller));

    bytes memory result = SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
    return abi.decode(result, (bool));
  }

  function isInventoryAdmin(
    RootCallWrapper memory self,
    uint256 smartObjectId,
    address caller
  ) internal view returns (bool) {
    bytes memory systemCall = abi.encodeCall(
      _isInventoryAdmin_uint256_address.isInventoryAdmin,
      (smartObjectId, caller)
    );

    bytes memory result = SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
    return abi.decode(result, (bool));
  }

  function isDeployableSystem(RootCallWrapper memory self, address caller) internal view returns (bool) {
    bytes memory systemCall = abi.encodeCall(_isDeployableSystem_address.isDeployableSystem, (caller));

    bytes memory result = SystemCall.staticcallOrRevert(self.from, self.systemId, systemCall);
    return abi.decode(result, (bool));
  }

  function callFrom(AccessSystemType self, address from) internal pure returns (CallWrapper memory) {
    return CallWrapper(self.toResourceId(), from);
  }

  function callAsRoot(AccessSystemType self) internal view returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), msg.sender);
  }

  function callAsRootFrom(AccessSystemType self, address from) internal pure returns (RootCallWrapper memory) {
    return RootCallWrapper(self.toResourceId(), from);
  }

  function toResourceId(AccessSystemType self) internal pure returns (ResourceId) {
    return ResourceId.wrap(AccessSystemType.unwrap(self));
  }

  function fromResourceId(ResourceId resourceId) internal pure returns (AccessSystemType) {
    return AccessSystemType.wrap(resourceId.unwrap());
  }

  function getAddress(AccessSystemType self) internal view returns (address) {
    return Systems.getSystem(self.toResourceId());
  }

  function _world() private view returns (IWorldCall) {
    return IWorldCall(StoreSwitch.getStoreAddress());
  }
}

/**
 * System Function Interfaces
 *
 * We generate an interface for each system function, which is then used for encoding system calls.
 * This is necessary to handle function overloading correctly (which abi.encodeCall cannot).
 *
 * Each interface is uniquely named based on the function name and parameters to prevent collisions.
 */

interface _onlyOwnerOrCanWithdrawFromInventory_uint256_bytes {
  function onlyOwnerOrCanWithdrawFromInventory(uint256 objectId, bytes memory data) external;
}

interface _onlyOwnerOrCanDepositToInventory_uint256_bytes {
  function onlyOwnerOrCanDepositToInventory(uint256 objectId, bytes memory data) external;
}

interface _onlyDeployableOwner_uint256_bytes {
  function onlyDeployableOwner(uint256 objectId, bytes memory data) external;
}

interface _onlyAdmin_uint256_bytes {
  function onlyAdmin(uint256 objectId, bytes memory data) external;
}

interface _onlyAdminOrDeployableOwner_uint256_bytes {
  function onlyAdminOrDeployableOwner(uint256 objectId, bytes memory data) external;
}

interface _onlyDeployableOwnerOrInventoryInteractSystem_uint256_bytes {
  function onlyDeployableOwnerOrInventoryInteractSystem(uint256 objectId, bytes memory data) external;
}

interface _onlyInventoryAdmin_uint256_bytes {
  function onlyInventoryAdmin(uint256 smartObjectId, bytes memory data) external;
}

interface _onlyAdminOrDeployableSystem_uint256_bytes {
  function onlyAdminOrDeployableSystem(uint256 objectId, bytes memory data) external;
}

interface _isAdmin_address {
  function isAdmin(address caller) external;
}

interface _isOwner_address_uint256 {
  function isOwner(address caller, uint256 objectId) external;
}

interface _canWithdrawFromInventory_uint256_address {
  function canWithdrawFromInventory(uint256 smartObjectId, address caller) external;
}

interface _canDepositToInventory_uint256_address {
  function canDepositToInventory(uint256 smartObjectId, address caller) external;
}

interface _isInventoryInteractSystem_address {
  function isInventoryInteractSystem(address caller) external;
}

interface _isInventoryAdmin_uint256_address {
  function isInventoryAdmin(uint256 smartObjectId, address caller) external;
}

interface _isDeployableSystem_address {
  function isDeployableSystem(address caller) external;
}

using AccessSystemLib for AccessSystemType global;
using AccessSystemLib for CallWrapper global;
using AccessSystemLib for RootCallWrapper global;
