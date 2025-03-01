// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema } from "@latticexyz/store/src/Schema.sol";
import { EncodedLengths, EncodedLengthsLib } from "@latticexyz/store/src/EncodedLengths.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

// Import user types
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

struct AccessConfigData {
  bool configured;
  ResourceId targetSystemId;
  bytes4 targetFunctionId;
  ResourceId accessSystemId;
  bytes4 accessFunctionId;
  bool enforcement;
}

library AccessConfig {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "evefrontier", name: "AccessConfig", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x746265766566726f6e74696572000000416363657373436f6e66696700000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x004a060001200420040100000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (bytes32)
  Schema constant _keySchema = Schema.wrap(0x002001005f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (bool, bytes32, bytes4, bytes32, bytes4, bool)
  Schema constant _valueSchema = Schema.wrap(0x004a0600605f435f436000000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "target";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](6);
    fieldNames[0] = "configured";
    fieldNames[1] = "targetSystemId";
    fieldNames[2] = "targetFunctionId";
    fieldNames[3] = "accessSystemId";
    fieldNames[4] = "accessFunctionId";
    fieldNames[5] = "enforcement";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, _keySchema, _valueSchema, getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, _keySchema, _valueSchema, getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get configured.
   */
  function getConfigured(bytes32 target) internal view returns (bool configured) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Get configured.
   */
  function _getConfigured(bytes32 target) internal view returns (bool configured) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Set configured.
   */
  function setConfigured(bytes32 target, bool configured) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((configured)), _fieldLayout);
  }

  /**
   * @notice Set configured.
   */
  function _setConfigured(bytes32 target, bool configured) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((configured)), _fieldLayout);
  }

  /**
   * @notice Get targetSystemId.
   */
  function getTargetSystemId(bytes32 target) internal view returns (ResourceId targetSystemId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return ResourceId.wrap(bytes32(_blob));
  }

  /**
   * @notice Get targetSystemId.
   */
  function _getTargetSystemId(bytes32 target) internal view returns (ResourceId targetSystemId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return ResourceId.wrap(bytes32(_blob));
  }

  /**
   * @notice Set targetSystemId.
   */
  function setTargetSystemId(bytes32 target, ResourceId targetSystemId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setStaticField(
      _tableId,
      _keyTuple,
      1,
      abi.encodePacked(ResourceId.unwrap(targetSystemId)),
      _fieldLayout
    );
  }

  /**
   * @notice Set targetSystemId.
   */
  function _setTargetSystemId(bytes32 target, ResourceId targetSystemId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(ResourceId.unwrap(targetSystemId)), _fieldLayout);
  }

  /**
   * @notice Get targetFunctionId.
   */
  function getTargetFunctionId(bytes32 target) internal view returns (bytes4 targetFunctionId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (bytes4(_blob));
  }

  /**
   * @notice Get targetFunctionId.
   */
  function _getTargetFunctionId(bytes32 target) internal view returns (bytes4 targetFunctionId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (bytes4(_blob));
  }

  /**
   * @notice Set targetFunctionId.
   */
  function setTargetFunctionId(bytes32 target, bytes4 targetFunctionId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((targetFunctionId)), _fieldLayout);
  }

  /**
   * @notice Set targetFunctionId.
   */
  function _setTargetFunctionId(bytes32 target, bytes4 targetFunctionId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((targetFunctionId)), _fieldLayout);
  }

  /**
   * @notice Get accessSystemId.
   */
  function getAccessSystemId(bytes32 target) internal view returns (ResourceId accessSystemId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 3, _fieldLayout);
    return ResourceId.wrap(bytes32(_blob));
  }

  /**
   * @notice Get accessSystemId.
   */
  function _getAccessSystemId(bytes32 target) internal view returns (ResourceId accessSystemId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 3, _fieldLayout);
    return ResourceId.wrap(bytes32(_blob));
  }

  /**
   * @notice Set accessSystemId.
   */
  function setAccessSystemId(bytes32 target, ResourceId accessSystemId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setStaticField(
      _tableId,
      _keyTuple,
      3,
      abi.encodePacked(ResourceId.unwrap(accessSystemId)),
      _fieldLayout
    );
  }

  /**
   * @notice Set accessSystemId.
   */
  function _setAccessSystemId(bytes32 target, ResourceId accessSystemId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked(ResourceId.unwrap(accessSystemId)), _fieldLayout);
  }

  /**
   * @notice Get accessFunctionId.
   */
  function getAccessFunctionId(bytes32 target) internal view returns (bytes4 accessFunctionId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 4, _fieldLayout);
    return (bytes4(_blob));
  }

  /**
   * @notice Get accessFunctionId.
   */
  function _getAccessFunctionId(bytes32 target) internal view returns (bytes4 accessFunctionId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 4, _fieldLayout);
    return (bytes4(_blob));
  }

  /**
   * @notice Set accessFunctionId.
   */
  function setAccessFunctionId(bytes32 target, bytes4 accessFunctionId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((accessFunctionId)), _fieldLayout);
  }

  /**
   * @notice Set accessFunctionId.
   */
  function _setAccessFunctionId(bytes32 target, bytes4 accessFunctionId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((accessFunctionId)), _fieldLayout);
  }

  /**
   * @notice Get enforcement.
   */
  function getEnforcement(bytes32 target) internal view returns (bool enforcement) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 5, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Get enforcement.
   */
  function _getEnforcement(bytes32 target) internal view returns (bool enforcement) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 5, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Set enforcement.
   */
  function setEnforcement(bytes32 target, bool enforcement) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((enforcement)), _fieldLayout);
  }

  /**
   * @notice Set enforcement.
   */
  function _setEnforcement(bytes32 target, bool enforcement) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((enforcement)), _fieldLayout);
  }

  /**
   * @notice Get the full data.
   */
  function get(bytes32 target) internal view returns (AccessConfigData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = StoreSwitch.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data.
   */
  function _get(bytes32 target) internal view returns (AccessConfigData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(
    bytes32 target,
    bool configured,
    ResourceId targetSystemId,
    bytes4 targetFunctionId,
    ResourceId accessSystemId,
    bytes4 accessFunctionId,
    bool enforcement
  ) internal {
    bytes memory _staticData = encodeStatic(
      configured,
      targetSystemId,
      targetFunctionId,
      accessSystemId,
      accessFunctionId,
      enforcement
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(
    bytes32 target,
    bool configured,
    ResourceId targetSystemId,
    bytes4 targetFunctionId,
    ResourceId accessSystemId,
    bytes4 accessFunctionId,
    bool enforcement
  ) internal {
    bytes memory _staticData = encodeStatic(
      configured,
      targetSystemId,
      targetFunctionId,
      accessSystemId,
      accessFunctionId,
      enforcement
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(bytes32 target, AccessConfigData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.configured,
      _table.targetSystemId,
      _table.targetFunctionId,
      _table.accessSystemId,
      _table.accessFunctionId,
      _table.enforcement
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(bytes32 target, AccessConfigData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.configured,
      _table.targetSystemId,
      _table.targetFunctionId,
      _table.accessSystemId,
      _table.accessFunctionId,
      _table.enforcement
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(
    bytes memory _blob
  )
    internal
    pure
    returns (
      bool configured,
      ResourceId targetSystemId,
      bytes4 targetFunctionId,
      ResourceId accessSystemId,
      bytes4 accessFunctionId,
      bool enforcement
    )
  {
    configured = (_toBool(uint8(Bytes.getBytes1(_blob, 0))));

    targetSystemId = ResourceId.wrap(Bytes.getBytes32(_blob, 1));

    targetFunctionId = (Bytes.getBytes4(_blob, 33));

    accessSystemId = ResourceId.wrap(Bytes.getBytes32(_blob, 37));

    accessFunctionId = (Bytes.getBytes4(_blob, 69));

    enforcement = (_toBool(uint8(Bytes.getBytes1(_blob, 73))));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   *
   *
   */
  function decode(
    bytes memory _staticData,
    EncodedLengths,
    bytes memory
  ) internal pure returns (AccessConfigData memory _table) {
    (
      _table.configured,
      _table.targetSystemId,
      _table.targetFunctionId,
      _table.accessSystemId,
      _table.accessFunctionId,
      _table.enforcement
    ) = decodeStatic(_staticData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(bytes32 target) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(bytes32 target) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(
    bool configured,
    ResourceId targetSystemId,
    bytes4 targetFunctionId,
    ResourceId accessSystemId,
    bytes4 accessFunctionId,
    bool enforcement
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(configured, targetSystemId, targetFunctionId, accessSystemId, accessFunctionId, enforcement);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    bool configured,
    ResourceId targetSystemId,
    bytes4 targetFunctionId,
    ResourceId accessSystemId,
    bytes4 accessFunctionId,
    bool enforcement
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(
      configured,
      targetSystemId,
      targetFunctionId,
      accessSystemId,
      accessFunctionId,
      enforcement
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(bytes32 target) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = target;

    return _keyTuple;
  }
}

/**
 * @notice Cast a value to a bool.
 * @dev Boolean values are encoded as uint8 (1 = true, 0 = false), but Solidity doesn't allow casting between uint8 and bool.
 * @param value The uint8 value to convert.
 * @return result The boolean value.
 */
function _toBool(uint8 value) pure returns (bool result) {
  assembly {
    result := value
  }
}
