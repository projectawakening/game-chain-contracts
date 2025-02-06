// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

// World imports
import { World } from "@latticexyz/world/src/World.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IModule } from "@latticexyz/world/src/IModule.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { PuppetModule } from "@latticexyz/world-modules/src/modules/puppet/PuppetModule.sol";
import { IERC20Mintable } from "@latticexyz/world-modules/src/modules/erc20-puppet/IERC20Mintable.sol";
import { ERC20MetadataData } from "@latticexyz/world-modules/src/modules/erc20-puppet/tables/ERC20Metadata.sol";
import { registerERC20 } from "@latticexyz/world-modules/src/modules/erc20-puppet/registerERC20.sol";

import { registerERC721 } from "../src/modules/eve-erc721-puppet/registerERC721.sol";
import { StaticDataGlobalTableData } from "../src/codegen/tables/StaticDataGlobalTable.sol";
import { IERC721Mintable } from "../src/modules/eve-erc721-puppet/IERC721Mintable.sol";

import "@eveworld/common-constants/src/constants.sol";
import { SmartObjectFrameworkModule } from "@eveworld/smart-object-framework/src/SmartObjectFrameworkModule.sol";
import { EntitySystem } from "@eveworld/smart-object-framework/src/systems/core/EntitySystem.sol";
import { HookSystem } from "@eveworld/smart-object-framework/src/systems/core/HookSystem.sol";
import { ModuleSystem } from "@eveworld/smart-object-framework/src/systems/core/ModuleSystem.sol";

import { EntityRecordModule } from "../src/modules/entity-record/EntityRecordModule.sol";
import { StaticDataModule } from "../src/modules/static-data/StaticDataModule.sol";
import { LocationModule } from "../src/modules/location/LocationModule.sol";
import { SmartCharacterModule } from "../src/modules/smart-character/SmartCharacterModule.sol";
import { SmartDeployableModule } from "../src/modules/smart-deployable/SmartDeployableModule.sol";
import { SmartDeployableLib } from "../src/modules/smart-deployable/SmartDeployableLib.sol";
import { SmartDeployableSystem } from "../src/modules/smart-deployable/systems/SmartDeployableSystem.sol";
import { SmartStorageUnitModule } from "../src/modules/smart-storage-unit/SmartStorageUnitModule.sol";
import { SmartCharacterLib } from "../src/modules/smart-character/SmartCharacterLib.sol";
import { SmartStorageUnitLib } from "../src/modules/smart-storage-unit/SmartStorageUnitLib.sol";

import { InventoryModule } from "../src/modules/inventory/InventoryModule.sol";
import { InventorySystem } from "../src/modules/inventory/systems/InventorySystem.sol";
import { EphemeralInventorySystem } from "../src/modules/inventory/systems/EphemeralInventorySystem.sol";
import { InventoryInteractSystem } from "../src/modules/inventory/systems/InventoryInteractSystem.sol";

import { SmartObjectLib } from "@eveworld/smart-object-framework/src/SmartObjectLib.sol";
import { EntityTable, EntityTableData } from "@eveworld/smart-object-framework/src/codegen/tables/EntityTable.sol";
import { EntityMap } from "@eveworld/smart-object-framework/src/codegen/tables/EntityMap.sol";
import { Utils as SmartObjectUtils } from "@eveworld/smart-object-framework/src/utils.sol";

contract PostDeploy is Script {
  using SmartObjectUtils for bytes14;
  using SmartCharacterLib for SmartCharacterLib.World;
  using SmartDeployableLib for SmartDeployableLib.World;
  using SmartObjectLib for SmartObjectLib.World;
  using SmartStorageUnitLib for SmartStorageUnitLib.World;

  SmartObjectLib.World SOFInterface;
  SmartStorageUnitLib.World smartStorageUnit;

  function run(address worldAddress) external {
    StoreSwitch.setStoreAddress(worldAddress);
    IBaseWorld world = IBaseWorld(worldAddress);
    string memory baseURI = vm.envString("BASE_URI");
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    // required for `NamespaceOwner` and `WorldResourceIdLib` to infer current World Address properly
    StoreSwitch.setStoreAddress(address(world));

    vm.startBroadcast(deployerPrivateKey);
    // installing all modules sequentially
    _installModule(
      world,
      deployer,
      new SmartObjectFrameworkModule(),
      FRONTIER_WORLD_DEPLOYMENT_NAMESPACE,
      address(new EntitySystem()),
      address(new HookSystem()),
      address(new ModuleSystem())
    );
    _installPuppet(world, deployer);
    _installModule(world, deployer, new StaticDataModule(), FRONTIER_WORLD_DEPLOYMENT_NAMESPACE);
    _installModule(world, deployer, new EntityRecordModule(), FRONTIER_WORLD_DEPLOYMENT_NAMESPACE);
    _installModule(world, deployer, new LocationModule(), FRONTIER_WORLD_DEPLOYMENT_NAMESPACE);
    _installModule(world, deployer, new SmartCharacterModule(), FRONTIER_WORLD_DEPLOYMENT_NAMESPACE);
    _installModule(
      world,
      deployer,
      new SmartDeployableModule(),
      FRONTIER_WORLD_DEPLOYMENT_NAMESPACE,
      address(new SmartDeployableSystem())
    );
    _installModule(
      world,
      deployer,
      new InventoryModule(),
      FRONTIER_WORLD_DEPLOYMENT_NAMESPACE,
      address(new InventorySystem()),
      address(new EphemeralInventorySystem()),
      address(new InventoryInteractSystem())
    );
    _installModule(world, deployer, new SmartStorageUnitModule(), FRONTIER_WORLD_DEPLOYMENT_NAMESPACE);
    // register new ERC721 puppets for SmartCharacter and SmartDeployable modules
    _initERC721(world, baseURI);

    _configureEntitiesAndClasses(world);
    _createEVEToken(world);
    vm.stopBroadcast();
  }

  function _installPuppet(IBaseWorld world, address deployer) internal {
    StoreSwitch.setStoreAddress(address(world));
    // creating all module contracts
    PuppetModule puppetModule = new PuppetModule();
    // puppetModule is conventionally installed as such
    world.installModule(puppetModule, new bytes(0));
  }

  function _installModule(IBaseWorld world, address deployer, IModule module, bytes14 namespace) internal {
    if (NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(namespace)) == deployer)
      world.transferOwnership(WorldResourceIdLib.encodeNamespace(namespace), address(module));
    world.installModule(module, abi.encode(namespace));
  }

  function _installModule(
    IBaseWorld world,
    address deployer,
    IModule module,
    bytes14 namespace,
    address system1
  ) internal {
    if (NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(namespace)) == deployer)
      world.transferOwnership(WorldResourceIdLib.encodeNamespace(namespace), address(module));
    world.installModule(module, abi.encode(namespace, system1));
  }

  function _installModule(
    IBaseWorld world,
    address deployer,
    IModule module,
    bytes14 namespace,
    address system1,
    address system2
  ) internal {
    if (NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(namespace)) == deployer)
      world.transferOwnership(WorldResourceIdLib.encodeNamespace(namespace), address(module));
    world.installModule(module, abi.encode(namespace, system1, system2));
  }

  function _installModule(
    IBaseWorld world,
    address deployer,
    IModule module,
    bytes14 namespace,
    address system1,
    address system2,
    address system3
  ) internal {
    if (NamespaceOwner.getOwner(WorldResourceIdLib.encodeNamespace(namespace)) == deployer)
      world.transferOwnership(WorldResourceIdLib.encodeNamespace(namespace), address(module));
    world.installModule(module, abi.encode(namespace, system1, system2, system3));
  }

  function _initERC721(IBaseWorld world, string memory baseURI) internal {
    IERC721Mintable erc721SmartDeployableToken = registerERC721(
      world,
      "erc721deploybl",
      StaticDataGlobalTableData({ name: "SmartDeployable", symbol: "SD", baseURI: baseURI })
    );
    console.log("Deploying Smart Deployable token with address: ", address(erc721SmartDeployableToken));

    IERC721Mintable erc721CharacterToken = registerERC721(
      world,
      "erc721charactr",
      StaticDataGlobalTableData({ name: "SmartCharacter", symbol: "SC", baseURI: baseURI })
    );
    console.log("Deploying Smart Character token with address: ", address(erc721CharacterToken));

    SmartCharacterLib
      .World({ iface: IBaseWorld(world), namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE })
      .registerERC721Token(address(erc721CharacterToken));

    SmartDeployableLib
      .World({ iface: IBaseWorld(world), namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE })
      .registerDeployableToken(address(erc721SmartDeployableToken));

    SmartDeployableLib
      .World({ iface: IBaseWorld(world), namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE })
      .globalResume();
  }

  //Create ERC20 Token
  function _createEVEToken(IBaseWorld world) internal {
    string memory namespace = vm.envString("EVE_TOKEN_NAMESPACE");
    string memory name = vm.envString("ERC20_TOKEN_NAME");
    string memory symbol = vm.envString("ERC20_TOKEN_SYMBOL");

    uint8 decimals = uint8(18);
    uint256 amount = uint256(vm.envUint("ERC20_INITIAL_SUPPLY"));
    address to = vm.envAddress("EVE_TOKEN_ADMIN");

    // ERC20 TOKEN DEPLOYMENT
    IERC20Mintable erc20Token;
    erc20Token = registerERC20(
      world,
      stringToBytes14(namespace),
      ERC20MetadataData({ decimals: decimals, name: name, symbol: symbol })
    );

    console.log("Deploying ERC20 token with address: ", address(erc20Token));

    address erc20Address = address(erc20Token);

    IERC20Mintable erc20 = IERC20Mintable(erc20Address);
    erc20.mint(to, amount * 1 ether);

    console.log("minting to: ", address(to));
    console.log("amount: ", amount * 1 ether);
  }

  //Configure Entities and Classes
  function _configureEntitiesAndClasses(IBaseWorld world) internal {
    uint256 smartCharacterClassId = uint256(keccak256("SmartCharacterClass"));

    SOFInterface = SmartObjectLib.World(world, FRONTIER_WORLD_DEPLOYMENT_NAMESPACE);
    smartStorageUnit = SmartStorageUnitLib.World(world, FRONTIER_WORLD_DEPLOYMENT_NAMESPACE);

    // create class and object types
    SOFInterface.registerEntityType(2, "CLASS");
    SOFInterface.registerEntityType(1, "OBJECT");
    // allow object to class tagging
    SOFInterface.registerEntityTypeAssociation(OBJECT, CLASS);

    // // register the SD CLASS ID as a CLASS entity
    // SOFInterface.registerEntity(sdClassId, CLASS);

    // initalize the smart character class
    SOFInterface.registerEntity(smartCharacterClassId, CLASS);
    // set smart character classId in the config
    SmartCharacterLib
      .World({ iface: IBaseWorld(world), namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE })
      .setCharClassId(smartCharacterClassId);

    // initalize the ssu class
    uint256 ssuClassId = uint256(keccak256("SSUClass"));
    SOFInterface.registerEntity(ssuClassId, 2);

    // set ssu classId in the config
    smartStorageUnit.setSSUClassId(ssuClassId);
  }

  function stringToBytes14(string memory str) public pure returns (bytes14) {
    bytes memory tempBytes = bytes(str);

    // Ensure the bytes array is not longer than 14 bytes.
    // If it is, this will truncate the array to the first 14 bytes.
    // If it's shorter, it will be padded with zeros.
    require(tempBytes.length <= 14, "String too long");

    bytes14 converted;
    for (uint i = 0; i < tempBytes.length; i++) {
      converted |= bytes14(tempBytes[i] & 0xFF) >> (i * 8);
    }

    return converted;
  }
}
