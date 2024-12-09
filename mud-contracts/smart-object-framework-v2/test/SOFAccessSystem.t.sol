// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";

import { World } from "@latticexyz/world/src/World.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdInstance, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_NAMESPACE, RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";

import { DEPLOYMENT_NAMESPACE } from "../src/namespaces/evefrontier/constants.sol";
import { DEPLOYMENT_NAMESPACE as SOF_ACCESS_NAMESPACE } from "../src/namespaces/sofaccess/constants.sol";
import { IRoleManagementSystem } from "../src/namespaces/evefrontier/interfaces/IRoleManagementSystem.sol";
import { Utils as RoleManagementSystemUtils } from "../src/namespaces/evefrontier/systems/role-management-system/Utils.sol";
import { IAccessConfigSystem } from "../src/namespaces/evefrontier/interfaces/IAccessConfigSystem.sol";
import { Utils as AccessConfigSystemUtils } from "../src/namespaces/evefrontier/systems/access-config-system/Utils.sol";
import { IEntitySystem } from "../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { Utils as EntitySystemUtils } from "../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { ITagSystem } from "../src/namespaces/evefrontier/interfaces/ITagSystem.sol";
import { Utils as TagSystemUtils } from "../src/namespaces/evefrontier/systems/tag-system/Utils.sol";
import { ISOFAccessSystem } from "../src/namespaces/sofaccess/interfaces/ISOFAccessSystem.sol";
import { Utils as SOFAccessSystemUtils } from "../src/namespaces/sofaccess/systems/sof-access-system/Utils.sol";

import "../src/namespaces/evefrontier/codegen/index.sol";

import { Id, IdLib } from "../src/libs/Id.sol";
import { ENTITY_CLASS, ENTITY_OBJECT } from "../src/types/entityTypes.sol";
import { TAG_SYSTEM } from "../src/types/tagTypes.sol";

import { ClassScopedMock } from "./mocks/ClassScopedMock.sol";
import { UnscopedMock } from "./mocks/UnscopedMock.sol";
import { SmartObjectFramework } from "../src/inherit/SmartObjectFramework.sol";

contract SOFAccessSystemTest is MudTest {

  IBaseWorld world;
  ClassScopedMock classScopedSystem;
  UnscopedMock unscopedSystem;

  bytes14 constant NAMESPACE = DEPLOYMENT_NAMESPACE;
  ResourceId constant NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, NAMESPACE)));
  ResourceId ROLE_MANAGEMENT_SYSTEM_ID = RoleManagementSystemUtils.roleManagementSystemId();
  ResourceId ACCESS_CONFIG_SYSTEM_ID = AccessConfigSystemUtils.accessConfigSystemId();
  ResourceId ENTITY_SYSTEM_ID = EntitySystemUtils.entitySystemId();
  ResourceId TAG_SYSTEM_ID = TagSystemUtils.tagSystemId();
  ResourceId SOF_ACCESS_SYSTEM_ID = SOFAccessSystemUtils.sofAccessSystemId();

  ResourceId CLASS_SCOPED_SYSTEM_ID = 
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("ClassScopedMock"))));
  ResourceId UNSCOPED_SYSTEM_ID = 
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("UnscopedMock"))));

  Id CLASS_SCOPED_SYSTEM_TAG = Id.wrap(bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("ClassScopedMock"))));
  Id UNSCOPED_SYSTEM_TAG = Id.wrap(bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("UnscopedMock"))));

  Id classId = IdLib.encode(ENTITY_CLASS, bytes30("TEST_CLASS"));
  bytes32 classAccessRole = bytes32("TEST_CLASS_ACCESS_ROLE");
  Id objectId = IdLib.encode(ENTITY_OBJECT, bytes30("TEST_OBJECT"));
  bytes32 objectAccessRole = bytes32("TEST_OBJECT_ACCESS_ROLE");

  string constant mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  address deployer = vm.addr(deployerPK);

  function setUp() public override {
    // DEPLOY AND REGISTER A MUD WORLD
    worldAddress = vm.envAddress("WORLD_ADDRESS");
    world = IBaseWorld(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);

    vm.startPrank(deployer);
    // DEPLOY AND REGISTER THE CLASS SCOPED SYSTEM AND THE UNSCOPED SYSTEM
    classScopedSystem = new ClassScopedMock();
    world.registerSystem(CLASS_SCOPED_SYSTEM_ID, System(classScopedSystem), true);

    unscopedSystem = new UnscopedMock();
    world.registerSystem(UNSCOPED_SYSTEM_ID, System(unscopedSystem), true);

    // CONFIGURE ROLES, ACCESS, AND ENFORCEMENT FOR THE ENTITY AND TAG SYSTEMS
    // create the Class Access Role with the deployer as the only member
    world.call(ROLE_MANAGEMENT_SYSTEM_ID, abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole)));

    // TagSystem.sol access config and enforcement
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.configureAccess, (TAG_SYSTEM_ID, ITagSystem.setSystemTag.selector, SOF_ACCESS_SYSTEM_ID, ISOFAccessSystem.allowEntitySystemOrDirectAccessRole.selector))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.configureAccess, (TAG_SYSTEM_ID, ITagSystem.removeSystemTag.selector, SOF_ACCESS_SYSTEM_ID, ISOFAccessSystem.allowEntitySystemOrDirectAccessRole.selector))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (TAG_SYSTEM_ID, ITagSystem.setSystemTag.selector, true))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (TAG_SYSTEM_ID, ITagSystem.removeSystemTag.selector, true))
    );
    
    // EntitySystem.sol access config and enforcement
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.configureAccess, (ENTITY_SYSTEM_ID, IEntitySystem.setClassAccessRole.selector, SOF_ACCESS_SYSTEM_ID, ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.configureAccess, (ENTITY_SYSTEM_ID, IEntitySystem.deleteClass.selector, SOF_ACCESS_SYSTEM_ID, ISOFAccessSystem.allowClassAccessRole.selector))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.configureAccess, (ENTITY_SYSTEM_ID, IEntitySystem.setObjectAccessRole.selector, SOF_ACCESS_SYSTEM_ID, ISOFAccessSystem.allowClassScopedSystemOrDirectObjectAccessRole.selector))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.configureAccess, (ENTITY_SYSTEM_ID, IEntitySystem.instantiate.selector, SOF_ACCESS_SYSTEM_ID, ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.configureAccess, (ENTITY_SYSTEM_ID, IEntitySystem.deleteObject.selector, SOF_ACCESS_SYSTEM_ID, ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (ENTITY_SYSTEM_ID, IEntitySystem.setClassAccessRole.selector, true))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (ENTITY_SYSTEM_ID, IEntitySystem.deleteClass.selector, true))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (ENTITY_SYSTEM_ID, IEntitySystem.setObjectAccessRole.selector, true))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (ENTITY_SYSTEM_ID, IEntitySystem.instantiate.selector, true))
    );
    world.call(
      ACCESS_CONFIG_SYSTEM_ID,
      abi.encodeCall(IAccessConfigSystem.setAccessEnforcement, (ENTITY_SYSTEM_ID, IEntitySystem.deleteObject.selector, true))
    );

    vm.stopPrank();
  }

  function testSetup() public {
    // mock systems are registered on the World
    assertEq(ResourceIds.getExists(CLASS_SCOPED_SYSTEM_ID), true);
    assertEq(ResourceIds.getExists(UNSCOPED_SYSTEM_ID), true);

    // check Role is created and has the deployer as a member
    assertEq(Role.getExists(classAccessRole), true);
    assertEq(HasRole.get(classAccessRole, deployer), true);

    // check all target systems/functions are configured with the SOF Access System and enforced
    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.setSystemTag.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.setSystemTag.selector))), true);
    
    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.removeSystemTag.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.removeSystemTag.selector))), true);

    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setClassAccessRole.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setClassAccessRole.selector))), true);

    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.deleteClass.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.deleteClass.selector))), true);

    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setObjectAccessRole.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setObjectAccessRole.selector))), true);

    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.instantiate.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.instantiate.selector))), true);

    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(ResourceId.unwrap(ENTITY_SYSTEM_ID), IEntitySystem.deleteObject.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(ResourceId.unwrap(ENTITY_SYSTEM_ID), IEntitySystem.deleteObject.selector))), true);
  }

  // TagSystem.sol
  function test_TagSystem_setSystemTag() public {
    // setSystemTag -> allowEntitySystemOrDirectAccessRole (class/object)

    // revert, if calling system is not the EntitySystem
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, classId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callSetSystemTag, (classId, CLASS_SCOPED_SYSTEM_TAG)));

    // success, via the EntitySystem call (through registerClass->setSystemTags->setSystemTag)
    // register Class (with the class scoped system tag)
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = CLASS_SCOPED_SYSTEM_TAG;

    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    
    // revert, even if the System is in scope but still not EntitySystem
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, classId, address(classScopedSystem))
    );
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callSetSystemTag, (classId, UNSCOPED_SYSTEM_TAG)));

    // revert, if direct caller is not a class access role member
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.setSystemTag, (classId, UNSCOPED_SYSTEM_TAG)));
    
    // success, direct caller is a class access role member
    vm.prank(deployer);
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.setSystemTag, (classId, UNSCOPED_SYSTEM_TAG)));
  }

  function test_TagSystem_removeSystemTag() public {
    // removeSystemTag - allowEntitySystemOrDirectAccessRole (class/object)
    // register Class (with the class scoped system tag)
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = CLASS_SCOPED_SYSTEM_TAG;
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    
    // revert, if calling system is not the EntitySystem
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, classId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callRemoveSystemTag, (classId, CLASS_SCOPED_SYSTEM_TAG)));

    // success, via the EntitySystem call (all tags removed through deleteClass->removeSystemTags->removeSystemTag)
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));

    // re-register Class (with classScopedSystem tag)
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    
    // set object level tag (unscopedSystem)
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callInstantiate, (classId, objectId)));
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callSetObjectAccessRole, (objectId, classAccessRole)));
    vm.prank(deployer);
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.setSystemTag, (objectId, UNSCOPED_SYSTEM_TAG)));

    // revert, even if the System is in scope but still not EntitySystem
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, classId, address(classScopedSystem))
    );
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callRemoveSystemTag, (classId, CLASS_SCOPED_SYSTEM_TAG)));

    // revert, if direct caller is not a class access role member (class)
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.removeSystemTag, (classId, CLASS_SCOPED_SYSTEM_TAG)));
    
    // success, direct caller is a class access role member (class)
    vm.prank(deployer);
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.removeSystemTag, (classId, CLASS_SCOPED_SYSTEM_TAG)));
    
    // revert, if direct caller is not a object access role member (object)
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.removeSystemTag, (objectId, UNSCOPED_SYSTEM_TAG)));
    
    // success, direct caller is a object access role member (object)
    vm.prank(deployer);
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.removeSystemTag, (objectId, UNSCOPED_SYSTEM_TAG)));
  }

  // EntitySystem.sol
  function test_EntitySystem_setClassAccessRole() public {
    // setClassAccessRole - allowClassScopedSystemOrDirectClassAccessRole (class)
  
    // register Class (with the class scoped system tag)
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = CLASS_SCOPED_SYSTEM_TAG;
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    
    // set object level tag (unscopedSystem)
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callInstantiate, (classId, objectId)));
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callSetObjectAccessRole, (objectId, classAccessRole)));
    vm.prank(deployer);
    world.call(TAG_SYSTEM_ID, abi.encodeCall(ITagSystem.setSystemTag, (objectId, UNSCOPED_SYSTEM_TAG)));
    
    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, classId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callSetClassAccessRole, (classId, classAccessRole)));

    // success, via the class scoped system call
     world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callSetClassAccessRole, (classId, classAccessRole)));

    // revert, if direct caller is not a class access role member
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.setClassAccessRole, (classId, classAccessRole)));

    // success, direct caller is a class access role member
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.setClassAccessRole, (classId, classAccessRole)));
  }

  function test_EntitySystem_setObjectAccessRole() public {
    // setObjectAccessRole - allowClassScopedSystemOrDirectObjectAccessRole (object)
  
    // register Class (with the class scoped system tag)
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = CLASS_SCOPED_SYSTEM_TAG;
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    // instantitate object
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callInstantiate, (classId, objectId)));
    
    // revert, if calling system is not class scoped for this object's class
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, objectId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callSetObjectAccessRole, (objectId, classAccessRole)));

    // success, via the class scoped system call
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callSetObjectAccessRole, (objectId, classAccessRole)));

    // revert, if direct caller is not a object access role member (in this case the object role is the class role added in the last call)
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.setObjectAccessRole, (objectId, classAccessRole)));

    // success, direct caller is a object access role member
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.setObjectAccessRole, (objectId, classAccessRole)));
  }

  function test_EntitySystem_instantiate() public {
    // instantiate - allowClassScopedSystemOrDirectClassAccessRole (object)
     
    // register Class (with the class scoped system tag)
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = CLASS_SCOPED_SYSTEM_TAG;
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    
    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, classId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callInstantiate, (classId, objectId)));

    // success, via the class scoped system call
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callInstantiate, (classId, objectId)));

    // delete object (so we can successfully instantiate again)
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));

    // revert, if direct caller is not a class access role member
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));

    // success, direct caller is a class access role member
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));
  }

  function test_EntitySystem_deleteObject() public {
    // deleteObject - allowClassScopedSystemOrDirectClassAccessRole (object)
    
    // register Class (with the class scoped system tag)
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = CLASS_SCOPED_SYSTEM_TAG;
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    // instantiate object
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));
    
    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_SystemAccessDenied.selector, classId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callDeleteObject, (objectId)));

    // success, via the class scoped system call
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callDeleteObject, (objectId)));

    // re-instantiate object (so we can successfully delete it again)
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));

    // revert, if direct caller is not a class access role member
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));

    // success, direct caller is a class access role member
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));
  }

  function test_EntitySystem_deleteClass() public {
    // deleteClass - allowClassAccessRole

    // register Class (with the class scoped system tag)
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = CLASS_SCOPED_SYSTEM_TAG;
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));

    // revert, if any system is calling (only direct calls allowed)
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_CallTooDeep.selector, 2)
    );
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callDeleteClass, (classId)));

    // revert, if direct caller is not a class access role member
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_RoleAccessDenied.selector, classAccessRole, address(this))
    );
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));

    // success, direct caller is a class access role member
    vm.prank(deployer);
    world.call(ENTITY_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));
  }
}
