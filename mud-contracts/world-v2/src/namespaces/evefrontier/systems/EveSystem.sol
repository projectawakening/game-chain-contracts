// SPDX-License-Identifier: MIT

pragma solidity >=0.8.24;

import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { IWorldWithContext } from "@eveworld/smart-object-framework-v2/src/IWorldWithContext.sol";

/**
 * @title EveSystem
 * @author CCP Games
 * @notice This is the base system to be inherited by all other systems.
 * @dev Consider combining this with the SmartObjectSystem which is extended by all systems.
 */
contract EveSystem is SmartObjectFramework {
  /**
   * @notice Get the world instance
   * @return The IWorld instance
   */
  function world() internal view returns (IWorldWithContext) {
    return IWorldWithContext(_world());
  }
}
