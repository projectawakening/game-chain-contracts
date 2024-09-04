// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM, RESOURCE_TABLE } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";

import { SMART_TURRET_SYSTEM_NAME } from "@eveworld/common-constants/src/constants.sol";

import "./constants.sol";

library Utils {
  using WorldResourceIdInstance for ResourceId;

  function getSystemId(bytes14 namespace, bytes16 name) internal pure returns (ResourceId) {
    return WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: namespace, name: name });
  }

  function smartTurretConfigTableId(bytes14 namespace) internal pure returns (ResourceId) {
    return
      WorldResourceIdLib.encode({ typeId: RESOURCE_TABLE, namespace: namespace, name: SMART_TURRET_CONFIG_TABLE_NAME });
  }

  function smartTurretSystemId(bytes14 namespace) internal pure returns (ResourceId) {
    return WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: namespace, name: SMART_TURRET_SYSTEM_NAME });
  }
}
