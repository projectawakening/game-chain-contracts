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

struct EntityAssociationData {
  uint256[] moduleIds;
  uint256[] hookIds;
}

library EntityAssociation {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "eveworld", name: "EntityAssociatio", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x7462657665776f726c64000000000000456e746974794173736f63696174696f);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0000000200000000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (uint256)
  Schema constant _keySchema = Schema.wrap(0x002001001f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (uint256[], uint256[])
  Schema constant _valueSchema = Schema.wrap(0x0000000281810000000000000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "entityId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](2);
    fieldNames[0] = "moduleIds";
    fieldNames[1] = "hookIds";
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
   * @notice Get moduleIds.
   */
  function getModuleIds(uint256 entityId) internal view returns (uint256[] memory moduleIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint256());
  }

  /**
   * @notice Get moduleIds.
   */
  function _getModuleIds(uint256 entityId) internal view returns (uint256[] memory moduleIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint256());
  }

  /**
   * @notice Set moduleIds.
   */
  function setModuleIds(uint256 entityId, uint256[] memory moduleIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((moduleIds)));
  }

  /**
   * @notice Set moduleIds.
   */
  function _setModuleIds(uint256 entityId, uint256[] memory moduleIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((moduleIds)));
  }

  /**
   * @notice Get the length of moduleIds.
   */
  function lengthModuleIds(uint256 entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of moduleIds.
   */
  function _lengthModuleIds(uint256 entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get an item of moduleIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemModuleIds(uint256 entityId, uint256 _index) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (uint256(bytes32(_blob)));
    }
  }

  /**
   * @notice Get an item of moduleIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemModuleIds(uint256 entityId, uint256 _index) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (uint256(bytes32(_blob)));
    }
  }

  /**
   * @notice Push an element to moduleIds.
   */
  function pushModuleIds(uint256 entityId, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to moduleIds.
   */
  function _pushModuleIds(uint256 entityId, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from moduleIds.
   */
  function popModuleIds(uint256 entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from moduleIds.
   */
  function _popModuleIds(uint256 entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Update an element of moduleIds at `_index`.
   */
  function updateModuleIds(uint256 entityId, uint256 _index, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of moduleIds at `_index`.
   */
  function _updateModuleIds(uint256 entityId, uint256 _index, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get hookIds.
   */
  function getHookIds(uint256 entityId) internal view returns (uint256[] memory hookIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint256());
  }

  /**
   * @notice Get hookIds.
   */
  function _getHookIds(uint256 entityId) internal view returns (uint256[] memory hookIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint256());
  }

  /**
   * @notice Set hookIds.
   */
  function setHookIds(uint256 entityId, uint256[] memory hookIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((hookIds)));
  }

  /**
   * @notice Set hookIds.
   */
  function _setHookIds(uint256 entityId, uint256[] memory hookIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((hookIds)));
  }

  /**
   * @notice Get the length of hookIds.
   */
  function lengthHookIds(uint256 entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of hookIds.
   */
  function _lengthHookIds(uint256 entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get an item of hookIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemHookIds(uint256 entityId, uint256 _index) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 32, (_index + 1) * 32);
      return (uint256(bytes32(_blob)));
    }
  }

  /**
   * @notice Get an item of hookIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemHookIds(uint256 entityId, uint256 _index) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 32, (_index + 1) * 32);
      return (uint256(bytes32(_blob)));
    }
  }

  /**
   * @notice Push an element to hookIds.
   */
  function pushHookIds(uint256 entityId, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to hookIds.
   */
  function _pushHookIds(uint256 entityId, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from hookIds.
   */
  function popHookIds(uint256 entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 1, 32);
  }

  /**
   * @notice Pop an element from hookIds.
   */
  function _popHookIds(uint256 entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 1, 32);
  }

  /**
   * @notice Update an element of hookIds at `_index`.
   */
  function updateHookIds(uint256 entityId, uint256 _index, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of hookIds at `_index`.
   */
  function _updateHookIds(uint256 entityId, uint256 _index, uint256 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get the full data.
   */
  function get(uint256 entityId) internal view returns (EntityAssociationData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

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
  function _get(uint256 entityId) internal view returns (EntityAssociationData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

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
  function set(uint256 entityId, uint256[] memory moduleIds, uint256[] memory hookIds) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(moduleIds, hookIds);
    bytes memory _dynamicData = encodeDynamic(moduleIds, hookIds);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(uint256 entityId, uint256[] memory moduleIds, uint256[] memory hookIds) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(moduleIds, hookIds);
    bytes memory _dynamicData = encodeDynamic(moduleIds, hookIds);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(uint256 entityId, EntityAssociationData memory _table) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(_table.moduleIds, _table.hookIds);
    bytes memory _dynamicData = encodeDynamic(_table.moduleIds, _table.hookIds);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(uint256 entityId, EntityAssociationData memory _table) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(_table.moduleIds, _table.hookIds);
    bytes memory _dynamicData = encodeDynamic(_table.moduleIds, _table.hookIds);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of dynamic data using the encoded lengths.
   */
  function decodeDynamic(
    EncodedLengths _encodedLengths,
    bytes memory _blob
  ) internal pure returns (uint256[] memory moduleIds, uint256[] memory hookIds) {
    uint256 _start;
    uint256 _end;
    unchecked {
      _end = _encodedLengths.atIndex(0);
    }
    moduleIds = (SliceLib.getSubslice(_blob, _start, _end).decodeArray_uint256());

    _start = _end;
    unchecked {
      _end += _encodedLengths.atIndex(1);
    }
    hookIds = (SliceLib.getSubslice(_blob, _start, _end).decodeArray_uint256());
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   *
   * @param _encodedLengths Encoded lengths of dynamic fields.
   * @param _dynamicData Tightly packed dynamic fields.
   */
  function decode(
    bytes memory,
    EncodedLengths _encodedLengths,
    bytes memory _dynamicData
  ) internal pure returns (EntityAssociationData memory _table) {
    (_table.moduleIds, _table.hookIds) = decodeDynamic(_encodedLengths, _dynamicData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(uint256 entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(uint256 entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(
    uint256[] memory moduleIds,
    uint256[] memory hookIds
  ) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(moduleIds.length * 32, hookIds.length * 32);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(uint256[] memory moduleIds, uint256[] memory hookIds) internal pure returns (bytes memory) {
    return abi.encodePacked(EncodeArray.encode((moduleIds)), EncodeArray.encode((hookIds)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    uint256[] memory moduleIds,
    uint256[] memory hookIds
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(moduleIds, hookIds);
    bytes memory _dynamicData = encodeDynamic(moduleIds, hookIds);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(uint256 entityId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(entityId));

    return _keyTuple;
  }
}
