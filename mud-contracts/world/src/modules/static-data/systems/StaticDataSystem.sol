// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { EveSystem } from "@eveworld/smart-object-framework/src/systems/internal/EveSystem.sol";

import { AccessModified } from "../../access/systems/AccessModified.sol";
import { Utils } from "../Utils.sol";
import { StaticDataTable } from "../../../codegen/tables/StaticDataTable.sol";
import { StaticDataGlobalTable, StaticDataGlobalTableData } from "../../../codegen/tables/StaticDataGlobalTable.sol";

contract StaticDataSystem is AccessModified, EveSystem {
  using Utils for bytes14;

  /**
   * set a new Base URI for a SystemId (represents a class of object)
   * TODO: should we check if the targeted SystemID even points to something ?
   * @param systemId corresponds to the class targeted
   * @param baseURI the new base URI string
   */
  function setBaseURI(
    ResourceId systemId,
    string memory baseURI
  ) public onlyAdmin hookable(uint256(ResourceId.unwrap(systemId)), _systemId()) {
    StaticDataGlobalTable.setBaseURI(systemId, baseURI);
  }

  /**
   * set a new name for a SystemId (represents a class of object)
   * TODO: should we check if the targeted SystemID even points to something ?
   * @param systemId corresponds to the class targeted
   * @param name the new name string
   */
  function setName(
    ResourceId systemId,
    string memory name
  ) public onlyAdmin hookable(uint256(ResourceId.unwrap(systemId)), _systemId()) {
    StaticDataGlobalTable.setName(systemId, name);
  }

  /**
   * set a new name for a SystemId (represents a class of object)
   * TODO: should we check if the targeted SystemID even points to something ?
   * @param systemId corresponds to the class targeted
   * @param symbol the new symbol string
   */
  function setSymbol(
    ResourceId systemId,
    string memory symbol
  ) public onlyAdmin hookable(uint256(ResourceId.unwrap(systemId)), _systemId()) {
    StaticDataGlobalTable.setSymbol(systemId, symbol);
  }

  /**
   * set a new name for a SystemId (represents a class of object)
   * TODO: should we check if the targeted SystemID even points to something ?
   * @param systemId corresponds to the class targeted
   * @param data the new metadata structure of type {StaticDataGlobalTableData}
   */
  function setMetadata(
    ResourceId systemId,
    StaticDataGlobalTableData memory data
  ) public onlyAdmin hookable(uint256(ResourceId.unwrap(systemId)), _systemId()) {
    StaticDataGlobalTable.set(systemId, data);
  }

  /**
   * set a new custom CID for an entity
   * @param entityId entityId of the in-game object
   * @param cid the new CID string
   */
  function setCid(uint256 entityId, string memory cid) public onlyAdmin hookable(entityId, _systemId()) {
    StaticDataTable.setCid(entityId, cid);
  }

  /**
   * returns this contract's systemId
   */
  function _systemId() internal view returns (ResourceId) {
    return _namespace().staticDataSystemId();
  }
}
