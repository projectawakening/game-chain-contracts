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

struct RiftData {
  uint256 createdAt;
  uint256 crudeAmount;
}

library Rift {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "evefrontier", name: "Rift", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x746265766566726f6e7469657200000052696674000000000000000000000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0040020020200000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (uint256)
  Schema constant _keySchema = Schema.wrap(0x002001001f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (uint256, uint256)
  Schema constant _valueSchema = Schema.wrap(0x004002001f1f0000000000000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "riftId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](2);
    fieldNames[0] = "createdAt";
    fieldNames[1] = "crudeAmount";
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
   * @notice Get createdAt.
   */
  function getCreatedAt(uint256 riftId) internal view returns (uint256 createdAt) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get createdAt.
   */
  function _getCreatedAt(uint256 riftId) internal view returns (uint256 createdAt) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set createdAt.
   */
  function setCreatedAt(uint256 riftId, uint256 createdAt) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((createdAt)), _fieldLayout);
  }

  /**
   * @notice Set createdAt.
   */
  function _setCreatedAt(uint256 riftId, uint256 createdAt) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((createdAt)), _fieldLayout);
  }

  /**
   * @notice Get crudeAmount.
   */
  function getCrudeAmount(uint256 riftId) internal view returns (uint256 crudeAmount) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get crudeAmount.
   */
  function _getCrudeAmount(uint256 riftId) internal view returns (uint256 crudeAmount) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set crudeAmount.
   */
  function setCrudeAmount(uint256 riftId, uint256 crudeAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((crudeAmount)), _fieldLayout);
  }

  /**
   * @notice Set crudeAmount.
   */
  function _setCrudeAmount(uint256 riftId, uint256 crudeAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((crudeAmount)), _fieldLayout);
  }

  /**
   * @notice Get the full data.
   */
  function get(uint256 riftId) internal view returns (RiftData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

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
  function _get(uint256 riftId) internal view returns (RiftData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

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
  function set(uint256 riftId, uint256 createdAt, uint256 crudeAmount) internal {
    bytes memory _staticData = encodeStatic(createdAt, crudeAmount);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(uint256 riftId, uint256 createdAt, uint256 crudeAmount) internal {
    bytes memory _staticData = encodeStatic(createdAt, crudeAmount);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(uint256 riftId, RiftData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.createdAt, _table.crudeAmount);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(uint256 riftId, RiftData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.createdAt, _table.crudeAmount);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(bytes memory _blob) internal pure returns (uint256 createdAt, uint256 crudeAmount) {
    createdAt = (uint256(Bytes.getBytes32(_blob, 0)));

    crudeAmount = (uint256(Bytes.getBytes32(_blob, 32)));
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
  ) internal pure returns (RiftData memory _table) {
    (_table.createdAt, _table.crudeAmount) = decodeStatic(_staticData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(uint256 riftId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(uint256 riftId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(uint256 createdAt, uint256 crudeAmount) internal pure returns (bytes memory) {
    return abi.encodePacked(createdAt, crudeAmount);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    uint256 createdAt,
    uint256 crudeAmount
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(createdAt, crudeAmount);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(uint256 riftId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(riftId));

    return _keyTuple;
  }
}
