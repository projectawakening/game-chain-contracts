// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { World } from "@latticexyz/world/src/World.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { PuppetModule } from "@latticexyz/world-modules/src/modules/puppet/PuppetModule.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { IModule } from "@latticexyz/world/src/IModule.sol";

import { INVENTORY_DEPLOYMENT_NAMESPACE as DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";
import { SmartObjectFrameworkModule } from "@eveworld/smart-object-framework/src/SmartObjectFrameworkModule.sol";
import { EntitySystem } from "@eveworld/smart-object-framework/src/systems/core/EntitySystem.sol";
import { HookSystem } from "@eveworld/smart-object-framework/src/systems/core/HookSystem.sol";
import { ModuleSystem } from "@eveworld/smart-object-framework/src/systems/core/ModuleSystem.sol";
import "@eveworld/common-constants/src/constants.sol";

import { DeployableState, DeployableStateData } from "../../src/codegen/tables/DeployableState.sol";
import { EntityRecordTable, EntityRecordTableData } from "../../src/codegen/tables/EntityRecordTable.sol";
import { InventoryTable } from "../../src/codegen/tables/InventoryTable.sol";
import { InventoryTableData } from "../../src/codegen/tables/InventoryTable.sol";
import { InventoryItemTable } from "../../src/codegen/tables/InventoryItemTable.sol";
import { InventoryItemTableData } from "../../src/codegen/tables/InventoryItemTable.sol";
import { IInventoryErrors } from "../../src/modules/inventory/IInventoryErrors.sol";
import { StaticDataGlobalTableData } from "../../src/codegen/tables/StaticDataGlobalTable.sol";

import { InventoryLib } from "../../src/modules/inventory/InventoryLib.sol";
import { InventoryModule } from "../../src/modules/inventory/InventoryModule.sol";
import { EntityRecordModule } from "../../src/modules/entity-record/EntityRecordModule.sol";
import { StaticDataModule } from "../../src/modules/static-data/StaticDataModule.sol";
import { LocationModule } from "../../src/modules/location/LocationModule.sol";
import { SmartDeployableLib } from "../../src/modules/smart-deployable/SmartDeployableLib.sol";
import { SmartDeployableModule } from "../../src/modules/smart-deployable/SmartDeployableModule.sol";
import { SmartDeployable } from "../../src/modules/smart-deployable/systems/SmartDeployable.sol";
import { registerERC721 } from "../../src/modules/eve-erc721-puppet/registerERC721.sol";
import { IERC721Mintable } from "../../src/modules/eve-erc721-puppet/IERC721Mintable.sol";
import { Inventory } from "../../src/modules/inventory/systems/Inventory.sol";
import { EphemeralInventory } from "../../src/modules/inventory/systems/EphemeralInventory.sol";
import { InventoryInteract } from "../../src/modules/inventory/systems/InventoryInteract.sol";
import { InventoryItem } from "../../src/modules/inventory/types.sol";
import { createCoreModule } from "../CreateCoreModule.sol";

import { Utils as SmartDeployableUtils } from "../../src/modules/smart-deployable/Utils.sol";
import { Utils as EntityRecordUtils } from "../../src/modules/entity-record/Utils.sol";
import { State } from "../../src/modules/smart-deployable/types.sol";
import { Utils } from "../../src/modules/inventory/Utils.sol";

contract InventoryTest is Test {
  using Utils for bytes14;
  using SmartDeployableUtils for bytes14;
  using EntityRecordUtils for bytes14;
  using InventoryLib for InventoryLib.World;
  using WorldResourceIdInstance for ResourceId;
  using SmartDeployableLib for SmartDeployableLib.World;

  IBaseWorld world;
  InventoryLib.World inventory;
  SmartDeployableLib.World smartDeployable;
  InventoryModule inventoryModule;
  IERC721Mintable erc721DeployableToken;

  bytes14 constant ERC721_DEPLOYABLE = "DeployableTokn";

  function setUp() public {
    world = IBaseWorld(address(new World()));
    world.initialize(createCoreModule());
    // required for `NamespaceOwner` and `WorldResourceIdLib` to infer current World Address properly
    StoreSwitch.setStoreAddress(address(world));

    // installing SOF & other modules (SmartCharacterModule dependancies)
    world.installModule(
      new SmartObjectFrameworkModule(),
      abi.encode(SMART_OBJECT_DEPLOYMENT_NAMESPACE, new EntitySystem(), new HookSystem(), new ModuleSystem())
    );
    // install module dependancies
    _installModule(new PuppetModule(), 0);
    _installModule(new StaticDataModule(), STATIC_DATA_DEPLOYMENT_NAMESPACE);
    _installModule(new EntityRecordModule(), ENTITY_RECORD_DEPLOYMENT_NAMESPACE);
    _installModule(new LocationModule(), LOCATION_DEPLOYMENT_NAMESPACE);

    erc721DeployableToken = registerERC721(
      world,
      ERC721_DEPLOYABLE,
      StaticDataGlobalTableData({ name: "SmartDeployable", symbol: "SD", baseURI: "" })
    );

    // install SmartDeployableModule
    SmartDeployableModule deployableModule = new SmartDeployableModule();
    if (
      NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE)) ==
      address(this)
    )
      world.transferOwnership(
        WorldResourceIdLib.encodeNamespace(SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE),
        address(deployableModule)
      );
    world.installModule(deployableModule, abi.encode(SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE, new SmartDeployable()));
    smartDeployable = SmartDeployableLib.World(world, SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE);
    smartDeployable.registerDeployableToken(address(erc721DeployableToken));
    smartDeployable.globalResume();

    // Inventory Module installation
    inventoryModule = new InventoryModule();
    if (NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(DEPLOYMENT_NAMESPACE)) == address(this))
      world.transferOwnership(WorldResourceIdLib.encodeNamespace(DEPLOYMENT_NAMESPACE), address(inventoryModule));
    world.installModule(
      inventoryModule,
      abi.encode(DEPLOYMENT_NAMESPACE, new Inventory(), new EphemeralInventory(), new InventoryInteract())
    );
    inventory = InventoryLib.World(world, DEPLOYMENT_NAMESPACE);

    //Mock Item creation
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 4235, 4235, 12, 100, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 4236, 4236, 12, 200, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 4237, 4237, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 8235, 8235, 12, 100, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 8236, 8236, 12, 200, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 8237, 8237, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 5237, 5237, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 6237, 6237, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 7237, 7237, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 5238, 5238, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 5239, 5239, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 6238, 6238, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 6239, 6239, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 7238, 7238, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 7239, 7239, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 9236, 9236, 12, 150, true);
    EntityRecordTable.set(ENTITY_RECORD_DEPLOYMENT_NAMESPACE.entityRecordTableId(), 9237, 9237, 12, 150, true);
  }

  // helper function to guard against multiple module registrations on the same namespace
  // TODO: Those kind of functions are used across all unit tests, ideally it should be inherited from a base Test contract
  function _installModule(IModule module, bytes14 namespace) internal {
    if (NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(namespace)) == address(this))
      world.transferOwnership(WorldResourceIdLib.encodeNamespace(namespace), address(module));
    world.installModule(module, abi.encode(namespace));
  }

  function testSetup() public {
    address InventorySystemAddress = Systems.getSystem(DEPLOYMENT_NAMESPACE.inventorySystemId());
    ResourceId inventorySystemId = SystemRegistry.get(InventorySystemAddress);
    assertEq(inventorySystemId.getNamespace(), DEPLOYMENT_NAMESPACE);
  }

  function testSetDeployableStateToValid(uint256 smartObjectId) public {
    vm.assume(smartObjectId != 0);

    DeployableState.set(
      SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE.deployableStateTableId(),
      smartObjectId,
      DeployableStateData({
        createdAt: block.timestamp,
        previousState: State.ANCHORED,
        currentState: State.ONLINE,
        isValid: true,
        anchoredAt: block.timestamp,
        updatedBlockNumber: block.number,
        updatedBlockTime: block.timestamp
      })
    );
  }

  function testSetInventoryCapacity(uint256 smartObjectId, uint256 storageCapacity) public {
    vm.assume(smartObjectId != 0);
    vm.assume(storageCapacity != 0);

    DeployableState.setCurrentState(
      SMART_DEPLOYABLE_DEPLOYMENT_NAMESPACE.deployableStateTableId(),
      smartObjectId,
      State.ONLINE
    );
    inventory.setInventoryCapacity(smartObjectId, storageCapacity);
    assertEq(InventoryTable.getCapacity(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId), storageCapacity);
  }

  function testRevertSetInventoryCapacity(uint256 smartObjectId, uint256 storageCapacity) public {
    vm.assume(storageCapacity == 0);
    vm.expectRevert(
      abi.encodeWithSelector(
        IInventoryErrors.Inventory_InvalidCapacity.selector,
        "Inventory: storage capacity cannot be 0"
      )
    );
    inventory.setInventoryCapacity(smartObjectId, storageCapacity);
  }

  function testDepositToInventory(uint256 smartObjectId, uint256 storageCapacity) public {
    vm.assume(smartObjectId != 0);
    vm.assume(storageCapacity >= 1100 && storageCapacity <= 10000);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](3);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 100, 3);
    items[1] = InventoryItem(4236, address(1), 4236, 0, 200, 2);
    items[2] = InventoryItem(4237, address(2), 4237, 0, 150, 2);

    testSetInventoryCapacity(smartObjectId, storageCapacity);
    testSetDeployableStateToValid(smartObjectId);
    InventoryTableData memory inventoryTableData = InventoryTable.get(
      DEPLOYMENT_NAMESPACE.inventoryTableId(),
      smartObjectId
    );
    uint256 capacityBeforeDeposit = inventoryTableData.usedCapacity;
    uint256 capacityAfterDeposit = 0;

    inventory.depositToInventory(smartObjectId, items);
    inventoryTableData = InventoryTable.get(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId);

    //Check weather the items are stored in the inventory table
    for (uint256 i = 0; i < items.length; i++) {
      uint256 itemVolume = items[i].volume * items[i].quantity;
      capacityAfterDeposit += itemVolume;
      assertEq(inventoryTableData.items[i], items[i].inventoryItemId);
    }

    inventoryTableData = InventoryTable.get(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId);
    assert(capacityBeforeDeposit < capacityAfterDeposit);
    assertEq(inventoryTableData.items.length, 3);

    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      FRONTIER_WORLD_DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem2 = InventoryItemTable.get(
      FRONTIER_WORLD_DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[1].inventoryItemId
    );

    InventoryItemTableData memory inventoryItem3 = InventoryItemTable.get(
      FRONTIER_WORLD_DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[2].inventoryItemId
    );

    assertEq(inventoryItem1.quantity, items[0].quantity);
    assertEq(inventoryItem2.quantity, items[1].quantity);
    assertEq(inventoryItem3.quantity, items[2].quantity);

    // console.log(inventoryItem1.index);
    assertEq(inventoryItem1.index, 0);
    assertEq(inventoryItem2.index, 1);
    assertEq(inventoryItem3.index, 2);
  }

  function testInventoryItemQuantityIncrease(uint256 smartObjectId, uint256 storageCapacity) public {
    vm.assume(smartObjectId != 0);
    vm.assume(storageCapacity >= 20000 && storageCapacity <= 50000);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](3);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 100, 3);
    items[1] = InventoryItem(4236, address(1), 4236, 0, 200, 2);
    items[2] = InventoryItem(4237, address(2), 4237, 0, 150, 2);

    testSetInventoryCapacity(smartObjectId, storageCapacity);
    testSetDeployableStateToValid(smartObjectId);
    inventory.depositToInventory(smartObjectId, items);

    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem2 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[1].inventoryItemId
    );

    assertEq(inventoryItem1.quantity, items[0].quantity);
    assertEq(inventoryItem2.quantity, items[1].quantity);

    //check the increase in quantity
    inventory.depositToInventory(smartObjectId, items);
    inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    inventoryItem2 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[1].inventoryItemId
    );

    assertEq(inventoryItem1.quantity, items[0].quantity * 2);
    assertEq(inventoryItem2.quantity, items[1].quantity * 2);

    uint256 itemsLength = InventoryTable.getItems(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId).length;
    assertEq(itemsLength, 3);

    assertEq(inventoryItem1.index, 0);
    assertEq(inventoryItem2.index, 1);
  }

  function testDepositToExistingInventory(uint256 smartObjectId, uint256 storageCapacity) public {
    testDepositToInventory(smartObjectId, storageCapacity);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem(8235, address(0), 8235, 0, 1, 3);
    inventory.depositToInventory(smartObjectId, items);

    uint256 itemsLength = InventoryTable.getItems(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId).length;
    assertEq(itemsLength, 4);

    inventory.depositToInventory(smartObjectId, items);
    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    assertEq(inventoryItem1.index, 3);
  }

  function testRevertDepositToInventory(uint256 smartObjectId, uint256 storageCapacity) public {
    vm.assume(smartObjectId != 0);
    vm.assume(storageCapacity >= 1 && storageCapacity <= 500);
    testSetInventoryCapacity(smartObjectId, storageCapacity);
    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 100, 6);
    testSetDeployableStateToValid(smartObjectId);
    vm.expectRevert(
      abi.encodeWithSelector(
        IInventoryErrors.Inventory_InsufficientCapacity.selector,
        "Inventory: insufficient capacity",
        storageCapacity,
        items[0].volume * items[0].quantity
      )
    );
    inventory.depositToInventory(smartObjectId, items);
  }

  function testWithdrawFromInventory(uint256 smartObjectId, uint256 storageCapacity) public {
    testDepositToInventory(smartObjectId, storageCapacity);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](3);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 100, 1);
    items[1] = InventoryItem(4236, address(1), 4236, 0, 200, 2);
    items[2] = InventoryItem(4237, address(2), 4237, 0, 150, 1);

    InventoryTableData memory inventoryTableData = InventoryTable.get(
      DEPLOYMENT_NAMESPACE.inventoryTableId(),
      smartObjectId
    );
    uint256 capacityBeforeWithdrawal = inventoryTableData.usedCapacity;
    uint256 itemVolume = 0;

    assertEq(capacityBeforeWithdrawal, 1000);

    inventory.withdrawFromInventory(smartObjectId, items);
    for (uint256 i = 0; i < items.length; i++) {
      itemVolume += items[i].volume * items[i].quantity;
    }

    inventoryTableData = InventoryTable.get(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId);
    assertEq(inventoryTableData.usedCapacity, capacityBeforeWithdrawal - itemVolume);
    assertEq(inventoryTableData.items.length, 2);

    uint256[] memory existingItems = inventoryTableData.items;
    assertEq(existingItems.length, 2);
    assertEq(existingItems[0], items[0].inventoryItemId);
    assertEq(existingItems[1], items[2].inventoryItemId);

    //Check weather the items quantity is reduced
    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem2 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[1].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem3 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[2].inventoryItemId
    );
    assertEq(inventoryItem1.quantity, 2);
    assertEq(inventoryItem2.quantity, 0);
    assertEq(inventoryItem3.quantity, 1);

    assertEq(inventoryItem1.index, 0);
    assertEq(inventoryItem2.index, 0);
    assertEq(inventoryItem3.index, 1);
  }

  function testDeposit1andWithdraw1(uint256 smartObjectId, uint256 storageCapacity) public {
    vm.assume(smartObjectId != 0);
    vm.assume(storageCapacity >= 1100 && storageCapacity <= 10000);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 100, 3);

    testSetInventoryCapacity(smartObjectId, storageCapacity);
    testSetDeployableStateToValid(smartObjectId);
    inventory.depositToInventory(smartObjectId, items);

    inventory.withdrawFromInventory(smartObjectId, items);

    InventoryTableData memory inventoryTableData = InventoryTable.get(
      DEPLOYMENT_NAMESPACE.inventoryTableId(),
      smartObjectId
    );
    assertEq(inventoryTableData.items.length, 0);

    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );

    assertEq(inventoryItem1.quantity, 0);
  }

  function testWithdrawRemove2Items(uint256 smartObjectId, uint256 storageCapacity) public {
    testDepositToInventory(smartObjectId, storageCapacity);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](2);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 100, 3);
    items[1] = InventoryItem(4236, address(1), 4236, 0, 200, 2);

    InventoryTableData memory inventoryTableData = InventoryTable.get(
      DEPLOYMENT_NAMESPACE.inventoryTableId(),
      smartObjectId
    );
    uint256 capacityBeforeWithdrawal = inventoryTableData.usedCapacity;
    uint256 itemVolume = 0;

    assertEq(capacityBeforeWithdrawal, 1000);

    inventory.withdrawFromInventory(smartObjectId, items);
    for (uint256 i = 0; i < items.length; i++) {
      itemVolume += items[i].volume * items[i].quantity;
    }

    inventoryTableData = InventoryTable.get(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId);
    assertEq(inventoryTableData.usedCapacity, capacityBeforeWithdrawal - itemVolume);
    assertEq(inventoryTableData.items.length, 1);

    uint256[] memory existingItems = inventoryTableData.items;
    assertEq(existingItems.length, 1);

    //Check weather the items quantity is reduced
    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem2 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[1].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem3 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      4237
    );
    assertEq(inventoryItem1.quantity, 0);
    assertEq(inventoryItem2.quantity, 0);
    assertEq(inventoryItem3.quantity, 2);

    assertEq(inventoryItem1.index, 0);
    assertEq(inventoryItem2.index, 0);
    assertEq(inventoryItem3.index, 0);
  }

  function testWithdrawRemoveCompletely(uint256 smartObjectId, uint256 storageCapacity) public {
    testDepositToInventory(smartObjectId, storageCapacity);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](3);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 100, 3);
    items[1] = InventoryItem(4236, address(1), 4236, 0, 200, 2);
    items[2] = InventoryItem(4237, address(2), 4237, 0, 150, 2);

    InventoryTableData memory inventoryTableData = InventoryTable.get(
      DEPLOYMENT_NAMESPACE.inventoryTableId(),
      smartObjectId
    );
    uint256 capacityBeforeWithdrawal = inventoryTableData.usedCapacity;
    uint256 itemVolume = 0;

    assertEq(capacityBeforeWithdrawal, 1000);

    inventory.withdrawFromInventory(smartObjectId, items);
    for (uint256 i = 0; i < items.length; i++) {
      itemVolume += items[i].volume * items[i].quantity;
    }

    inventoryTableData = InventoryTable.get(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId);
    assertEq(inventoryTableData.usedCapacity, capacityBeforeWithdrawal - itemVolume);
    assertEq(inventoryTableData.items.length, 0);

    uint256[] memory existingItems = inventoryTableData.items;
    assertEq(existingItems.length, 0);

    //Check weather the items quantity is reduced
    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem2 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[1].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem3 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[2].inventoryItemId
    );
    assertEq(inventoryItem1.quantity, 0);
    assertEq(inventoryItem2.quantity, 0);
    assertEq(inventoryItem3.quantity, 0);

    assertEq(inventoryItem1.index, 0);
    assertEq(inventoryItem2.index, 0);
    assertEq(inventoryItem3.index, 0);
  }

  function testWithdrawWithBigArraySize(uint256 smartObjectId, uint256 storageCapacity) public {
    vm.assume(smartObjectId != 0);
    vm.assume(storageCapacity >= 11000 && storageCapacity <= 90000);

    testSetInventoryCapacity(smartObjectId, storageCapacity);
    testSetDeployableStateToValid(smartObjectId);

    //Note: Issue applying fuzz testing for the below array of inputs : https://github.com/foundry-rs/foundry/issues/5343
    InventoryItem[] memory items = new InventoryItem[](12);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 10, 300);
    items[1] = InventoryItem(4236, address(1), 4236, 0, 20, 2);
    items[2] = InventoryItem(4237, address(2), 4237, 0, 10, 2);
    items[3] = InventoryItem(8235, address(2), 8235, 0, 10, 2);
    items[4] = InventoryItem(8237, address(2), 8237, 0, 10, 2);
    items[5] = InventoryItem(5237, address(2), 5237, 0, 10, 2);
    items[6] = InventoryItem(6237, address(2), 6237, 0, 10, 2);
    items[7] = InventoryItem(7237, address(2), 7237, 0, 10, 2);
    items[8] = InventoryItem(5238, address(2), 5238, 0, 10, 2);
    items[9] = InventoryItem(5239, address(2), 5239, 0, 10, 2);
    items[10] = InventoryItem(6238, address(2), 6238, 0, 10, 2);
    items[11] = InventoryItem(6239, address(2), 6239, 0, 10, 2);

    inventory.depositToInventory(smartObjectId, items);

    //Change the order
    items = new InventoryItem[](12);
    items[0] = InventoryItem(4235, address(0), 4235, 0, 10, 300);
    items[1] = InventoryItem(4236, address(1), 4236, 0, 20, 2);
    items[2] = InventoryItem(4237, address(2), 4237, 0, 10, 2);
    items[3] = InventoryItem(8235, address(2), 8235, 0, 10, 2);
    items[4] = InventoryItem(8237, address(2), 8237, 0, 10, 2);
    items[5] = InventoryItem(5237, address(2), 5237, 0, 10, 2);
    items[6] = InventoryItem(6237, address(2), 6237, 0, 10, 2);
    items[7] = InventoryItem(7237, address(2), 7237, 0, 10, 2);
    items[8] = InventoryItem(5238, address(2), 5238, 0, 10, 2);
    items[9] = InventoryItem(5239, address(2), 5239, 0, 10, 2);
    items[10] = InventoryItem(6238, address(2), 6238, 0, 10, 2);
    items[11] = InventoryItem(6239, address(2), 6239, 0, 10, 2);
    inventory.withdrawFromInventory(smartObjectId, items);

    InventoryTableData memory inventoryTableData = InventoryTable.get(
      DEPLOYMENT_NAMESPACE.inventoryTableId(),
      smartObjectId
    );
    assertEq(inventoryTableData.items.length, 0);

    //check if everything is 0
    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[0].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem2 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[1].inventoryItemId
    );
    InventoryItemTableData memory inventoryItem3 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      items[2].inventoryItemId
    );
    assertEq(inventoryItem1.quantity, 0);
    assertEq(inventoryItem2.quantity, 0);
    assertEq(inventoryItem3.quantity, 0);

    assertEq(inventoryItem1.index, 0);
    assertEq(inventoryItem2.index, 0);
    assertEq(inventoryItem3.index, 0);
  }

  function testWithdrawMultipleTimes(uint256 smartObjectId, uint256 storageCapacity) public {
    testWithdrawFromInventory(smartObjectId, storageCapacity);

    InventoryTableData memory inventoryTableData = InventoryTable.get(
      DEPLOYMENT_NAMESPACE.inventoryTableId(),
      smartObjectId
    );
    assertEq(inventoryTableData.items.length, 2);

    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem(4237, address(0), 4237, 0, 200, 1);

    // Try withdraw again
    inventory.withdrawFromInventory(smartObjectId, items);

    uint256 itemId1 = uint256(4235);
    uint256 itemId3 = uint256(4237);

    InventoryItemTableData memory inventoryItem1 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      itemId1
    );
    InventoryItemTableData memory inventoryItem2 = InventoryItemTable.get(
      DEPLOYMENT_NAMESPACE.inventoryItemTableId(),
      smartObjectId,
      itemId3
    );

    assertEq(inventoryItem1.quantity, 2);
    assertEq(inventoryItem2.quantity, 0);

    assertEq(inventoryItem1.index, 0);
    assertEq(inventoryItem2.index, 0);

    inventoryTableData = InventoryTable.get(DEPLOYMENT_NAMESPACE.inventoryTableId(), smartObjectId);
    assertEq(inventoryTableData.items.length, 1);
  }

  function revertWithdrawalForInvalidQuantity(uint256 smartObjectId, uint256 storageCapacity) public {
    testDepositToInventory(smartObjectId, storageCapacity);

    InventoryItem[] memory items = new InventoryItem[](1);
    items[0] = InventoryItem(4237, address(2), 4237, 0, 150, 1);

    vm.expectRevert(
      abi.encodeWithSelector(
        IInventoryErrors.Inventory_InvalidQuantity.selector,
        "Inventory: invalid quantity",
        3,
        items[0].quantity
      )
    );
    inventory.withdrawFromInventory(smartObjectId, items);
  }

  function testOnlyAdminCanSetInventoryCapacity() public {
    //TODO : Add test case for only admin can set inventory capacity after RBAC
  }

  function testOnlyOwnerCanDepositToInventory() public {
    //TODO : Add test case for only owner can deposit to inventory after RBAC
  }

  function testOnlyOwnerCanWithdrawFromInventory() public {
    //TODO : Add test case for only owner can deposit to inventory after RBAC
  }
}
