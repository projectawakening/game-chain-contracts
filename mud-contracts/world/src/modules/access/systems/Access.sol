// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM, RESOURCE_TABLE } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IWorldKernel } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceAccess } from "@latticexyz/world/src/codegen/tables/ResourceAccess.sol";

import { IERC721 } from "../../eve-erc721-puppet/IERC721.sol";
import { Utils } from "../Utils.sol";
import { DeployableTokenTable } from "../../../codegen/tables/DeployableTokenTable.sol";

import { AccessRole, AccessEnforcement } from "../../../codegen/index.sol";

import { IAccessErrors } from "../interfaces/IAccessErrors.sol";

import { ACCESS_ROLE_TABLE_NAME, ACCESS_ENFORCEMENT_TABLE_NAME, EVE_WORLD_NAMESPACE } from "../constants.sol";
import { EveSystem } from "@eveworld/smart-object-framework/src/systems/internal/EveSystem.sol";

contract Access is EveSystem {
  using Utils for bytes14;

  function setAccessListByRole(bytes32 accessRoleId, address[] memory accessList) public {
    // we are reserving "OWNER" for the ERC721 owner accounts (ownership defined in the ERC721 tables, not here)
    if (accessRoleId == bytes32("OWNER")) {
      revert IAccessErrors.Access_InvalidRoleId();
    }
    // only account granted access to the AccessRole table can sucessfully call this function
    if (!ResourceAccess.get(EVE_WORLD_NAMESPACE.accessRoleTableId(), IWorldKernel(_world()).initialMsgSender())) {
      revert IAccessErrors.Access_AccessConfigAccessDenied();
    }
    AccessRole.set(EVE_WORLD_NAMESPACE.accessRoleTableId(), accessRoleId, accessList);
  }

  function setAccessEnforcement(bytes32 target, bool isEnforced) public {
    // same access restirction as setAccessListByRole
    if (!ResourceAccess.get(EVE_WORLD_NAMESPACE.accessRoleTableId(), IWorldKernel(_world()).initialMsgSender())) {
      revert IAccessErrors.Access_AccessConfigAccessDenied();
    }
    AccessEnforcement.set(EVE_WORLD_NAMESPACE.accessEnforcementTableId(), target, isEnforced);
  }
}
