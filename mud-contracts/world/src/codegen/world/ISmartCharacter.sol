// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityRecordData } from "./../../modules/smart-character/types.sol";
import { EntityRecordOffchainTableData } from "./../tables/EntityRecordOffchainTable.sol";

/**
 * @title ISmartCharacter
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ISmartCharacter {
  function eveworld__registerERC721Token(address tokenAddress) external;

  function eveworld__createCharacter(
    uint256 characterId,
    address characterAddress,
    EntityRecordData memory entityRecord,
    EntityRecordOffchainTableData memory entityRecordOffchain,
    string memory tokenCid
  ) external;

  function eveworld__setCharClassId(uint256 classId) external;
}
