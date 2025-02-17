// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { WorldWithContext } from "@eveworld/smart-object-framework-v2/src/WorldWithContext.sol";

// TODO: Allow MUD to read custom worlds outside of the current package.
contract WorldWithContextProxy is WorldWithContext {
  constructor() WorldWithContext() {}
}
