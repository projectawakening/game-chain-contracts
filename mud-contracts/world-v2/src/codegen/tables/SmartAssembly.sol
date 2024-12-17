// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

// Import store internals
import { IStore } from "@latticexyz/store/srcIStore.sol";
import { StoreSwitch } from "@latticexyz/store/srcStoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/srcStoreCore.sol";
import { Bytes } from "@latticexyz/store/srcBytes.sol";
import { Memory } from "@latticexyz/store/srcMemory.sol";
import { SliceLib } from "@latticexyz/store/srcSlice.sol";
import { EncodeArray } from "@latticexyz/store/srctightcoder/EncodeArray.sol";
import { FieldLayout } from "@latticexyz/store/srcFieldLayout.sol";
import { Schema } from "@latticexyz/store/srcSchema.sol";
import { EncodedLengths, EncodedLengthsLib } from "@latticexyz/store/srcEncodedLengths.sol";
import { ResourceId } from "@latticexyz/store/srcResourceId.sol";

struct SmartAssemblyData {
  uint256 smartAssemblyId;
  string smartAssemblyType;
}

library SmartAssembly {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "evefrontier", name: "SmartAssembly", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x746265766566726f6e74696572000000536d617274417373656d626c79000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0020010120000000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (uint256)
  Schema constant _keySchema = Schema.wrap(0x002001001f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (uint256, string)
  Schema constant _valueSchema = Schema.wrap(0x002001011fc50000000000000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "smartObjectId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](2);
    fieldNames[0] = "smartAssemblyId";
    fieldNames[1] = "smartAssemblyType";
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
   * @notice Get smartAssemblyId.
   */
  function getSmartAssemblyId(uint256 smartObjectId) internal view returns (uint256 smartAssemblyId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get smartAssemblyId.
   */
  function _getSmartAssemblyId(uint256 smartObjectId) internal view returns (uint256 smartAssemblyId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set smartAssemblyId.
   */
  function setSmartAssemblyId(uint256 smartObjectId, uint256 smartAssemblyId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((smartAssemblyId)), _fieldLayout);
  }

  /**
   * @notice Set smartAssemblyId.
   */
  function _setSmartAssemblyId(uint256 smartObjectId, uint256 smartAssemblyId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((smartAssemblyId)), _fieldLayout);
  }

  /**
   * @notice Get smartAssemblyType.
   */
  function getSmartAssemblyType(uint256 smartObjectId) internal view returns (string memory smartAssemblyType) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (string(_blob));
  }

  /**
   * @notice Get smartAssemblyType.
   */
  function _getSmartAssemblyType(uint256 smartObjectId) internal view returns (string memory smartAssemblyType) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (string(_blob));
  }

  /**
   * @notice Set smartAssemblyType.
   */
  function setSmartAssemblyType(uint256 smartObjectId, string memory smartAssemblyType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, bytes((smartAssemblyType)));
  }

  /**
   * @notice Set smartAssemblyType.
   */
  function _setSmartAssemblyType(uint256 smartObjectId, string memory smartAssemblyType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, bytes((smartAssemblyType)));
  }

  /**
   * @notice Get the length of smartAssemblyType.
   */
  function lengthSmartAssemblyType(uint256 smartObjectId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get the length of smartAssemblyType.
   */
  function _lengthSmartAssemblyType(uint256 smartObjectId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get an item of smartAssemblyType.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemSmartAssemblyType(uint256 smartObjectId, uint256 _index) internal view returns (string memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (string(_blob));
    }
  }

  /**
   * @notice Get an item of smartAssemblyType.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemSmartAssemblyType(uint256 smartObjectId, uint256 _index) internal view returns (string memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (string(_blob));
    }
  }

  /**
   * @notice Push a slice to smartAssemblyType.
   */
  function pushSmartAssemblyType(uint256 smartObjectId, string memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, bytes((_slice)));
  }

  /**
   * @notice Push a slice to smartAssemblyType.
   */
  function _pushSmartAssemblyType(uint256 smartObjectId, string memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, bytes((_slice)));
  }

  /**
   * @notice Pop a slice from smartAssemblyType.
   */
  function popSmartAssemblyType(uint256 smartObjectId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Pop a slice from smartAssemblyType.
   */
  function _popSmartAssemblyType(uint256 smartObjectId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Update a slice of smartAssemblyType at `_index`.
   */
  function updateSmartAssemblyType(uint256 smartObjectId, uint256 _index, string memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update a slice of smartAssemblyType at `_index`.
   */
  function _updateSmartAssemblyType(uint256 smartObjectId, uint256 _index, string memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get the full data.
   */
  function get(uint256 smartObjectId) internal view returns (SmartAssemblyData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

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
  function _get(uint256 smartObjectId) internal view returns (SmartAssemblyData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

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
  function set(uint256 smartObjectId, uint256 smartAssemblyId, string memory smartAssemblyType) internal {
    bytes memory _staticData = encodeStatic(smartAssemblyId);

    EncodedLengths _encodedLengths = encodeLengths(smartAssemblyType);
    bytes memory _dynamicData = encodeDynamic(smartAssemblyType);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(uint256 smartObjectId, uint256 smartAssemblyId, string memory smartAssemblyType) internal {
    bytes memory _staticData = encodeStatic(smartAssemblyId);

    EncodedLengths _encodedLengths = encodeLengths(smartAssemblyType);
    bytes memory _dynamicData = encodeDynamic(smartAssemblyType);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(uint256 smartObjectId, SmartAssemblyData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.smartAssemblyId);

    EncodedLengths _encodedLengths = encodeLengths(_table.smartAssemblyType);
    bytes memory _dynamicData = encodeDynamic(_table.smartAssemblyType);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(uint256 smartObjectId, SmartAssemblyData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.smartAssemblyId);

    EncodedLengths _encodedLengths = encodeLengths(_table.smartAssemblyType);
    bytes memory _dynamicData = encodeDynamic(_table.smartAssemblyType);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(bytes memory _blob) internal pure returns (uint256 smartAssemblyId) {
    smartAssemblyId = (uint256(Bytes.getBytes32(_blob, 0)));
  }

  /**
   * @notice Decode the tightly packed blob of dynamic data using the encoded lengths.
   */
  function decodeDynamic(
    EncodedLengths _encodedLengths,
    bytes memory _blob
  ) internal pure returns (string memory smartAssemblyType) {
    uint256 _start;
    uint256 _end;
    unchecked {
      _end = _encodedLengths.atIndex(0);
    }
    smartAssemblyType = (string(SliceLib.getSubslice(_blob, _start, _end).toBytes()));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   * @param _encodedLengths Encoded lengths of dynamic fields.
   * @param _dynamicData Tightly packed dynamic fields.
   */
  function decode(
    bytes memory _staticData,
    EncodedLengths _encodedLengths,
    bytes memory _dynamicData
  ) internal pure returns (SmartAssemblyData memory _table) {
    (_table.smartAssemblyId) = decodeStatic(_staticData);

    (_table.smartAssemblyType) = decodeDynamic(_encodedLengths, _dynamicData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(uint256 smartObjectId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(uint256 smartObjectId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(uint256 smartAssemblyId) internal pure returns (bytes memory) {
    return abi.encodePacked(smartAssemblyId);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(string memory smartAssemblyType) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(bytes(smartAssemblyType).length);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(string memory smartAssemblyType) internal pure returns (bytes memory) {
    return abi.encodePacked(bytes((smartAssemblyType)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    uint256 smartAssemblyId,
    string memory smartAssemblyType
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(smartAssemblyId);

    EncodedLengths _encodedLengths = encodeLengths(smartAssemblyType);
    bytes memory _dynamicData = encodeDynamic(smartAssemblyType);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(uint256 smartObjectId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(smartObjectId));

    return _keyTuple;
  }
}
