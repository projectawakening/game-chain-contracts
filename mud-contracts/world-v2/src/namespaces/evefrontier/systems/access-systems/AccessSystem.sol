// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { HasRole } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/index.sol";
import { DeployableToken } from "../../codegen/index.sol";
import { IERC721 } from "../eve-erc721-puppet/IERC721.sol";

contract AccessSystem is SmartObjectFramework {
  error Access_NotAdmin(address caller);
  error Access_NotOwner(address caller, uint256 objectId);
  error Access_NotAdminOrOwner(address caller, uint256 objectId);

  function onlyDeployableOwner(uint256 objectId, bytes memory data) public view {
    if (!isOwner(_callMsgSender(), objectId)) {
      revert Access_NotOwner(_callMsgSender(), objectId);
    }
  }

  function onlyAdmin(uint256 objectId, bytes memory data) public view {
    if (!isAdmin(_callMsgSender())) {
      revert Access_NotAdmin(_callMsgSender());
    }
  }

  function onlyAdminOrDeployableOwner(uint256 objectId, bytes memory data) public view {
    if (!isAdmin(_callMsgSender()) && !isOwner(_callMsgSender(), objectId)) {
      revert Access_NotAdminOrOwner(_callMsgSender(), objectId);
    }
  }

  function isAdmin(address caller) public view returns (bool) {
    return HasRole.getHasRole("admin", caller);
  }

  function isOwner(address caller, uint256 objectId) public view returns (bool) {
    address erc721Address = DeployableToken.getErc721Address();
    address owner = IERC721(erc721Address).ownerOf(objectId);
    return owner == caller;
  }
}
