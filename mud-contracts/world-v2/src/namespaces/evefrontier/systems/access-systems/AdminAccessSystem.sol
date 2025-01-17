// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { HasRole } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/index.sol";

/**
 * @title DeployableSystem
 * @author CCP Games
 * DeployableSystem stores the deployable state of a smart object on-chain
 */

contract AdminAccessSystem is SmartObjectFramework {
  error AdminAccess_NotAdmin();

  function onlyAdmin(uint256 objectId, bytes memory data) public view {
    if (HasRole.getHasRole("admin", _callMsgSender()) == false) {
      revert AdminAccess_NotAdmin();
    }
  }
}
