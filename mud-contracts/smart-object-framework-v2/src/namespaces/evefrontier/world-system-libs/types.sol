// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

struct EntityRecordData {
  uint256 typeId;
  uint256 itemId;
  uint256 volume;
}

struct LocationData {
  uint256 solarSystemId;
  uint256 x;
  uint256 y;
  uint256 z;
}

struct SmartObjectData {
  address owner;
  string tokenURI;
}

struct CreateAndAnchorDeployableParams {
  uint256 smartObjectId;
  string smartAssemblyType;
  EntityRecordData entityRecordData;
  SmartObjectData smartObjectData;
  uint256 fuelUnitVolume;
  uint256 fuelConsumptionIntervalInSeconds;
  uint256 fuelMaxCapacity;
  LocationData locationData;
}

struct EntityMetadata {
  string name;
  string dappURL;
  string description;
}

struct InventoryItem {
  uint256 inventoryItemId;
  address owner;
  uint256 itemId;
  uint256 typeId;
  uint256 volume;
  uint256 quantity;
}

struct TransferItem {
  uint256 inventoryItemId;
  address owner;
  uint256 quantity;
}

struct TargetPriority {
  SmartTurretTarget target;
  uint256 weight;
}

struct SmartTurretTarget {
  uint256 shipId;
  uint256 shipTypeId;
  uint256 characterId;
  uint256 hpRatio;
  uint256 shieldRatio;
  uint256 armorRatio;
}

struct Turret {
  uint256 weaponTypeId;
  uint256 ammoTypeId;
  uint256 chargesLeft;
}

struct AggressionParams {
  uint256 smartObjectId;
  uint256 turretOwnerCharacterId;
  TargetPriority[] priorityQueue;
  Turret turret;
  SmartTurretTarget aggressor;
  SmartTurretTarget victim;
}

