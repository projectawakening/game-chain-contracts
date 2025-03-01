// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";

import { World } from "@latticexyz/world/src/World.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdInstance, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_NAMESPACE, RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";

import { IEntitySystem } from "../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { entitySystem } from "../src/namespaces/evefrontier/codegen/systems/EntitySystemLib.sol";
import { ITagSystem } from "../src/namespaces/evefrontier/interfaces/ITagSystem.sol";
import { tagSystem } from "../src/namespaces/evefrontier/codegen/systems/TagSystemLib.sol";
import { IRoleManagementSystem } from "../src/namespaces/evefrontier/interfaces/IRoleManagementSystem.sol";
import { roleManagementSystem } from "../src/namespaces/evefrontier/codegen/systems/RoleManagementSystemLib.sol";
import { accessConfigSystem } from "../src/namespaces/evefrontier/codegen/systems/AccessConfigSystemLib.sol";
import { ISOFAccessSystem } from "../src/namespaces/sofaccess/interfaces/ISOFAccessSystem.sol";
import { sOFAccessSystem } from "../src/namespaces/sofaccess/codegen/systems/SOFAccessSystemLib.sol";

import "../src/namespaces/evefrontier/codegen/index.sol";

import { TagId, TagIdLib } from "../src/libs/TagId.sol";

import { TAG_TYPE_PROPERTY, TAG_TYPE_ENTITY_RELATION, TAG_TYPE_RESOURCE_RELATION, TAG_IDENTIFIER_CLASS, TAG_IDENTIFIER_OBJECT, TAG_IDENTIFIER_ENTITY_COUNT, TagParams, EntityRelationValue, ResourceRelationValue } from "../src/namespaces/evefrontier/systems/tag-system/types.sol";

import { ClassScopedMock } from "./mocks/ClassScopedMock.sol";
import { UnscopedMock } from "./mocks/UnscopedMock.sol";
import { SmartObjectFramework } from "../src/inherit/SmartObjectFramework.sol";

contract SOFAccessSystemTest is MudTest {
  IBaseWorld world;
  ClassScopedMock classScopedSystem;
  UnscopedMock unscopedSystem;

  ResourceId ENTITY_SYSTEM_ID = entitySystem.toResourceId();
  ResourceId TAG_SYSTEM_ID = tagSystem.toResourceId();
  ResourceId ROLE_MANAGEMENT_SYSTEM_ID = roleManagementSystem.toResourceId();
  ResourceId SOF_ACCESS_SYSTEM_ID = sOFAccessSystem.toResourceId();

  ResourceId CLASS_SCOPED_SYSTEM_ID =
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("ClassScopedMock"))));
  ResourceId UNSCOPED_SYSTEM_ID =
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("evefrontier"), bytes16("UnscopedMock"))));

  TagId CLASS_SCOPED_SYSTEM_TAG =
    TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(CLASS_SCOPED_SYSTEM_ID)));
  TagId UNSCOPED_SYSTEM_TAG =
    TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(UNSCOPED_SYSTEM_ID)));

  uint256 classId = uint256(bytes32("TEST_CLASS"));
  bytes32 classAccessRole = keccak256(abi.encodePacked("ACCESS_ROLE", classId));
  uint256 objectId = uint256(bytes32("TEST_OBJECT"));
  bytes32 objectAccessRole = keccak256(abi.encodePacked("ACCESS_ROLE", objectId));

  bytes32 adminRole = bytes32("ADMIN_ROLE");
  bytes32 testRole = bytes32("TEST_ROLE");

  string constant mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  address deployer = vm.addr(deployerPK);
  uint256 alicePK = vm.deriveKey(mnemonic, 1);
  address alice = vm.addr(alicePK);

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

    // TagSystem.sol access config and enforcement
    accessConfigSystem.configureAccess(
      TAG_SYSTEM_ID,
      ITagSystem.setTag.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowEntitySystemOrDirectAccessRole.selector
    );
    accessConfigSystem.configureAccess(
      TAG_SYSTEM_ID,
      ITagSystem.removeTag.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowEntitySystemOrDirectAccessRole.selector
    );

    accessConfigSystem.setAccessEnforcement(TAG_SYSTEM_ID, ITagSystem.setTag.selector, true);
    accessConfigSystem.setAccessEnforcement(TAG_SYSTEM_ID, ITagSystem.removeTag.selector, true);

    // EntitySystem.sol access config and enforcement
    accessConfigSystem.configureAccess(
      ENTITY_SYSTEM_ID,
      IEntitySystem.scopedRegisterClass.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowDefinedSystems.selector
    );
    accessConfigSystem.configureAccess(
      ENTITY_SYSTEM_ID,
      IEntitySystem.setClassAccessRole.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystemOrDirectAccessRole.selector
    );
    accessConfigSystem.configureAccess(
      ENTITY_SYSTEM_ID,
      IEntitySystem.deleteClass.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowDirectAccessRole.selector
    );
    accessConfigSystem.configureAccess(
      ENTITY_SYSTEM_ID,
      IEntitySystem.setObjectAccessRole.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystemOrDirectAccessRole.selector
    );
    accessConfigSystem.configureAccess(
      ENTITY_SYSTEM_ID,
      IEntitySystem.instantiate.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector
    );
    accessConfigSystem.configureAccess(
      ENTITY_SYSTEM_ID,
      IEntitySystem.deleteObject.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystemOrDirectClassAccessRole.selector
    );

    accessConfigSystem.setAccessEnforcement(ENTITY_SYSTEM_ID, IEntitySystem.scopedRegisterClass.selector, true);
    accessConfigSystem.setAccessEnforcement(ENTITY_SYSTEM_ID, IEntitySystem.setClassAccessRole.selector, true);
    accessConfigSystem.setAccessEnforcement(ENTITY_SYSTEM_ID, IEntitySystem.deleteClass.selector, true);
    accessConfigSystem.setAccessEnforcement(ENTITY_SYSTEM_ID, IEntitySystem.setObjectAccessRole.selector, true);
    accessConfigSystem.setAccessEnforcement(ENTITY_SYSTEM_ID, IEntitySystem.instantiate.selector, true);
    accessConfigSystem.setAccessEnforcement(ENTITY_SYSTEM_ID, IEntitySystem.deleteObject.selector, true);

    // RoleManagementSystem.sol access config and enforcement
    accessConfigSystem.configureAccess(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedCreateRole.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowEntitySystemOrClassScopedSystem.selector
    );
    accessConfigSystem.configureAccess(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedTransferRoleAdmin.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystem.selector
    );
    accessConfigSystem.configureAccess(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedGrantRole.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystem.selector
    );
    accessConfigSystem.configureAccess(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedRevokeRole.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystem.selector
    );
    accessConfigSystem.configureAccess(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedRenounceRole.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowClassScopedSystem.selector
    );
    accessConfigSystem.configureAccess(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedRevokeAll.selector,
      SOF_ACCESS_SYSTEM_ID,
      ISOFAccessSystem.allowEntitySystemOrClassScopedSystem.selector
    );
    accessConfigSystem.setAccessEnforcement(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedCreateRole.selector,
      true
    );
    accessConfigSystem.setAccessEnforcement(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedTransferRoleAdmin.selector,
      true
    );
    accessConfigSystem.setAccessEnforcement(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedGrantRole.selector,
      true
    );
    accessConfigSystem.setAccessEnforcement(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedRevokeRole.selector,
      true
    );
    accessConfigSystem.setAccessEnforcement(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedRenounceRole.selector,
      true
    );
    accessConfigSystem.setAccessEnforcement(
      ROLE_MANAGEMENT_SYSTEM_ID,
      IRoleManagementSystem.scopedRevokeAll.selector,
      true
    );
    vm.stopPrank();
  }

  function testSetup() public {
    // mock systems are registered on the World
    assertEq(ResourceIds.getExists(CLASS_SCOPED_SYSTEM_ID), true);
    assertEq(ResourceIds.getExists(UNSCOPED_SYSTEM_ID), true);

    // check all target systems/functions are configured with the SOF Access System and enforced
    assertEq(AccessConfig.getConfigured(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.setTag.selector))), true);
    assertEq(AccessConfig.getEnforcement(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.setTag.selector))), true);

    assertEq(
      AccessConfig.getConfigured(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.removeTag.selector))),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(keccak256(abi.encodePacked(TAG_SYSTEM_ID, ITagSystem.removeTag.selector))),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.scopedRegisterClass.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setClassAccessRole.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setClassAccessRole.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.deleteClass.selector))),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.deleteClass.selector))),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setObjectAccessRole.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.setObjectAccessRole.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.instantiate.selector))),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(keccak256(abi.encodePacked(ENTITY_SYSTEM_ID, IEntitySystem.instantiate.selector))),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ResourceId.unwrap(ENTITY_SYSTEM_ID), IEntitySystem.deleteObject.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ResourceId.unwrap(ENTITY_SYSTEM_ID), IEntitySystem.deleteObject.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedCreateRole.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedCreateRole.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedTransferRoleAdmin.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedTransferRoleAdmin.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedGrantRole.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedGrantRole.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedRevokeRole.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedRevokeRole.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedRenounceRole.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedRenounceRole.selector))
      ),
      true
    );

    assertEq(
      AccessConfig.getConfigured(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedRevokeAll.selector))
      ),
      true
    );
    assertEq(
      AccessConfig.getEnforcement(
        keccak256(abi.encodePacked(ROLE_MANAGEMENT_SYSTEM_ID, IRoleManagementSystem.scopedRevokeAll.selector))
      ),
      true
    );
  }

  // TagSystem.sol
  function test_TagSystem_setTag() public {
    // setSystemTag -> allowEntitySystemOrDirectAccessRole (class/object)

    // implicit success, via the EntitySystem call (through registerClass->setTags->setTag)
    // register Class (with the class scoped system tag)
    ResourceId[] memory scopedSystemIds = new ResourceId[](1);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;

    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);

    // revert, if calling system is not scoped
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, classId, UNSCOPED_SYSTEM_ID)
    );
    world.call(
      UNSCOPED_SYSTEM_ID,
      abi.encodeCall(
        UnscopedMock.callSetTag,
        (
          classId,
          TagParams(
            CLASS_SCOPED_SYSTEM_TAG,
            abi.encode(ResourceRelationValue("COMPOSITION", RESOURCE_SYSTEM, CLASS_SCOPED_SYSTEM_ID.getResourceName()))
          )
        )
      )
    );

    // revert, even if the System is in scope but is not explicitly an EntitySystem caller
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, classId, address(classScopedSystem))
    );
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(
        ClassScopedMock.callSetTag,
        (
          classId,
          TagParams(
            UNSCOPED_SYSTEM_TAG,
            abi.encode(ResourceRelationValue("COMPOSITION", RESOURCE_SYSTEM, UNSCOPED_SYSTEM_ID.getResourceName()))
          )
        )
      )
    );

    // revert, if direct caller is not a class access role member
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, classId, address(this)));
    tagSystem.setTag(
      classId,
      TagParams(
        UNSCOPED_SYSTEM_TAG,
        abi.encode(ResourceRelationValue("COMPOSITION", RESOURCE_SYSTEM, UNSCOPED_SYSTEM_ID.getResourceName()))
      )
    );

    // success, direct caller is a class access role member
    vm.prank(deployer);
    tagSystem.setTag(
      classId,
      TagParams(
        UNSCOPED_SYSTEM_TAG,
        abi.encode(ResourceRelationValue("COMPOSITION", RESOURCE_SYSTEM, UNSCOPED_SYSTEM_ID.getResourceName()))
      )
    );
  }

  function test_TagSystem_removeSystemTag() public {
    // removeSystemTag - allowEntitySystemOrDirectAccessRole (class/object)
    // register Class (with the class scoped system tag)
    ResourceId[] memory scopedSystemIds = new ResourceId[](1);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);

    // revert, if calling system is not scoped
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, classId, UNSCOPED_SYSTEM_ID)
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callRemoveTag, (classId, CLASS_SCOPED_SYSTEM_TAG)));

    // success, via the EntitySystem call (all tags removed through deleteClass->removeSystemTags->removeSystemTag)
    vm.prank(deployer);
    entitySystem.deleteClass(classId);

    // re-register Class (with classScopedSystem tag)
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);

    // set object level tag (unscopedSystem)
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callInstantiate, (classId, objectId, alice)));
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callSetObjectAccessRole, (objectId, classAccessRole))
    );
    vm.prank(deployer);
    tagSystem.setTag(
      objectId,
      TagParams(
        UNSCOPED_SYSTEM_TAG,
        abi.encode(ResourceRelationValue("COMPOSITION", RESOURCE_SYSTEM, UNSCOPED_SYSTEM_ID.getResourceName()))
      )
    );

    // revert, even if the System is in scope but is not explicitly an EntitySystem caller
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, classId, address(classScopedSystem))
    );
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callRemoveTag, (classId, CLASS_SCOPED_SYSTEM_TAG))
    );

    // revert, if direct caller is not a class access role member (class)
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, classId, address(this)));
    tagSystem.removeTag(classId, CLASS_SCOPED_SYSTEM_TAG);

    // success, direct caller is a class access role member (class)
    vm.prank(deployer);
    tagSystem.removeTag(classId, CLASS_SCOPED_SYSTEM_TAG);

    // revert, if direct caller is not a object access role member (object)
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    tagSystem.removeTag(objectId, UNSCOPED_SYSTEM_TAG);

    // success, direct caller is a object access role member (object)
    vm.prank(deployer);
    tagSystem.removeTag(objectId, UNSCOPED_SYSTEM_TAG);
  }

  // EntitySystem.sol
  function test_EntitySystem_registerClass() public {}

  function test_EntitySystem_setClassAccessRole() public {
    // setClassAccessRole - allowClassScopedSystemOrDirectClassAccessRole (class)

    // register Class (with the class scoped system tag)
    ResourceId[] memory scopedSystemIds = new ResourceId[](1);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);

    // set object level tag (unscopedSystem)
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callInstantiate, (classId, objectId, alice)));
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callSetObjectAccessRole, (objectId, classAccessRole))
    );

    vm.prank(deployer);
    tagSystem.setTag(
      objectId,
      TagParams(
        UNSCOPED_SYSTEM_TAG,
        abi.encode(ResourceRelationValue("COMPOSITION", RESOURCE_SYSTEM, UNSCOPED_SYSTEM_ID.getResourceName()))
      )
    );

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, classId, UNSCOPED_SYSTEM_ID)
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callSetClassAccessRole, (classId, classAccessRole)));

    // success, via the class scoped system call
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callSetClassAccessRole, (classId, classAccessRole))
    );

    // revert, if direct caller is not a class access role member
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, classId, address(this)));
    entitySystem.setClassAccessRole(classId, classAccessRole);

    // success, direct caller is a class access role member
    vm.prank(deployer);
    entitySystem.setClassAccessRole(classId, classAccessRole);
  }

  function test_EntitySystem_setObjectAccessRole() public {
    // setObjectAccessRole - allowClassScopedSystemOrDirectAccessRole (object)

    // register Class (with the class scoped system tag)
    ResourceId[] memory scopedSystemIds = new ResourceId[](1);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);

    // instantitate object
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    // revert, if calling system is not scoped for this object (nor its class)
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, objectId, UNSCOPED_SYSTEM_ID)
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callSetObjectAccessRole, (objectId, classAccessRole)));

    // success, via the class scoped system call
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callSetObjectAccessRole, (objectId, classAccessRole))
    );

    // revert, if direct caller is not a object access role member (in this case the object role is the class role added in the last call)
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    entitySystem.setObjectAccessRole(objectId, classAccessRole);

    // success, direct caller is a object access role member
    vm.prank(deployer);
    entitySystem.setObjectAccessRole(objectId, classAccessRole);
  }

  function test_EntitySystem_instantiate() public {
    // instantiate - allowClassScopedSystemOrDirectClassAccessRole (object)

    // register Class (with the class scoped system tag)
    ResourceId[] memory scopedSystemIds = new ResourceId[](1);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, classId, UNSCOPED_SYSTEM_ID)
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callInstantiate, (classId, objectId, alice)));

    // success, via the class scoped system call
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callInstantiate, (classId, objectId, alice)));

    // delete object (so we can successfully instantiate again)
    vm.prank(deployer);
    entitySystem.deleteObject(objectId);

    // revert, if direct caller is not a class access role member
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, classId, address(this)));
    entitySystem.instantiate(classId, objectId, alice);

    // success, direct caller is a class access role member
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);
  }

  function test_EntitySystem_deleteObject() public {
    // deleteObject - allowClassScopedSystemOrDirectAccessRole (object)

    // register Class (with the class scoped system tag)
    ResourceId[] memory scopedSystemIds = new ResourceId[](1);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);
    // instantiate object
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, objectId, UNSCOPED_SYSTEM_ID)
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callDeleteObject, (objectId)));

    // success, via the class scoped system call (with a member of the object access role as the caller)
    vm.prank(alice);
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callDeleteObject, (objectId)));

    // re-instantiate object (so we can successfully delete it again)
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    // revert, if direct caller is not a class access role member
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    entitySystem.deleteObject(objectId);

    // success, direct caller is a class access role member
    vm.prank(deployer);
    entitySystem.deleteObject(objectId);
  }

  function test_EntitySystem_deleteClass() public {
    // deleteClass - allowDirectAccessRole

    // register Class (with the class scoped system tag)
    ResourceId[] memory scopedSystemIds = new ResourceId[](2);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    scopedSystemIds[1] = ROLE_MANAGEMENT_SYSTEM_ID;
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);

    // revert, if any system is calling (only direct calls allowed)
    vm.expectRevert(abi.encodeWithSelector(SmartObjectFramework.SOF_CallTooDeep.selector, 2));
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callDeleteClass, (classId)));

    // revert, if direct caller is not a class access role member
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, classId, address(this)));
    entitySystem.deleteClass(classId);

    // success, direct caller is a class access role member
    vm.prank(deployer);
    entitySystem.deleteClass(classId);
  }

  function test_RoleManagermentSystem_scopedCreateRole() public {
    // scopedCreateRole - allowEntitySystemOrClassScopedSystem
    ResourceId[] memory scopedSystemIds = new ResourceId[](2);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    scopedSystemIds[1] = ROLE_MANAGEMENT_SYSTEM_ID;
    // setup class and object to test against, success case for scopedCreateRole via EntitySystem
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    // revert, if direct calling
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    roleManagementSystem.scopedCreateRole(objectId, adminRole, adminRole, deployer);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(unscopedSystem))
    );
    world.call(
      UNSCOPED_SYSTEM_ID,
      abi.encodeCall(UnscopedMock.callScopedCreateRole, (objectId, adminRole, adminRole, deployer))
    );

    // success, via the class scoped system call
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callScopedCreateRole, (objectId, adminRole, adminRole, deployer))
    );
  }

  function test_RoleManagermentSystem_scopedTransferRoleAdmin() public {
    ResourceId[] memory scopedSystemIds = new ResourceId[](2);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    scopedSystemIds[1] = ROLE_MANAGEMENT_SYSTEM_ID;
    // setup class and object to test against
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    // create two roles which have themselves as admin
    vm.prank(deployer);
    roleManagementSystem.createRole(testRole, testRole);
    vm.prank(deployer);
    roleManagementSystem.createRole(adminRole, adminRole);

    // revert, if direct calling
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    roleManagementSystem.scopedTransferRoleAdmin(objectId, testRole, adminRole);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(unscopedSystem))
    );
    world.call(
      UNSCOPED_SYSTEM_ID,
      abi.encodeCall(UnscopedMock.callScopedTransferRoleAdmin, (objectId, testRole, adminRole))
    );

    // success, via the class scoped system call
    vm.prank(deployer);
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callScopedTransferRoleAdmin, (objectId, testRole, adminRole))
    );
  }

  function test_RoleManagermentSystem_scopedGrantRole() public {
    ResourceId[] memory scopedSystemIds = new ResourceId[](2);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    scopedSystemIds[1] = ROLE_MANAGEMENT_SYSTEM_ID;
    // setup class and object to test against, success case for scopedGrantRole via EntitySystem
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    vm.prank(deployer);
    roleManagementSystem.createRole(adminRole, adminRole);

    // revert, if direct calling
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    roleManagementSystem.scopedGrantRole(objectId, adminRole, alice);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callScopedGrantRole, (objectId, adminRole, alice)));

    // success, via the class scoped system call
    vm.prank(deployer);
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callScopedGrantRole, (objectId, adminRole, alice))
    );
  }

  function test_RoleManagermentSystem_scopedRevokeRole() public {
    ResourceId[] memory scopedSystemIds = new ResourceId[](2);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    scopedSystemIds[1] = ROLE_MANAGEMENT_SYSTEM_ID;
    // setup class and object to test against
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    vm.prank(deployer);
    roleManagementSystem.createRole(adminRole, adminRole);
    vm.prank(deployer);
    roleManagementSystem.grantRole(adminRole, alice);

    // revert, if direct calling
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    roleManagementSystem.scopedRevokeRole(objectId, adminRole, alice);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callScopedRevokeRole, (objectId, adminRole, alice)));

    // success, via the class scoped system call
    vm.prank(deployer);
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callScopedRevokeRole, (objectId, adminRole, alice))
    );
  }

  function test_RoleManagermentSystem_scopedRenounceRole() public {
    ResourceId[] memory scopedSystemIds = new ResourceId[](2);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    scopedSystemIds[1] = ROLE_MANAGEMENT_SYSTEM_ID;
    // setup class and object to test against
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    vm.prank(deployer);
    roleManagementSystem.createRole(adminRole, adminRole);

    // revert, if direct calling
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    roleManagementSystem.scopedRenounceRole(objectId, adminRole, deployer);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(unscopedSystem))
    );
    world.call(
      UNSCOPED_SYSTEM_ID,
      abi.encodeCall(UnscopedMock.callScopedRenounceRole, (objectId, adminRole, deployer))
    );

    // success, via the class scoped system call
    vm.prank(deployer);
    world.call(
      CLASS_SCOPED_SYSTEM_ID,
      abi.encodeCall(ClassScopedMock.callScopedRenounceRole, (objectId, adminRole, deployer))
    );
  }

  function test_RoleManagermentSystem_scopedRevokeAll() public {
    // allowEntitySystemOrClassScopedSystem
    ResourceId[] memory scopedSystemIds = new ResourceId[](2);
    scopedSystemIds[0] = CLASS_SCOPED_SYSTEM_ID;
    scopedSystemIds[1] = ROLE_MANAGEMENT_SYSTEM_ID;
    // setup class and object to test against
    vm.prank(deployer);
    entitySystem.registerClass(classId, scopedSystemIds);
    vm.prank(deployer);
    entitySystem.instantiate(classId, objectId, alice);

    vm.prank(deployer);
    roleManagementSystem.createRole(adminRole, adminRole);
    vm.prank(deployer);
    roleManagementSystem.grantRole(adminRole, alice);

    // revert, if direct calling
    vm.expectRevert(abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(this)));
    roleManagementSystem.scopedRevokeAll(objectId, adminRole);

    // revert, if calling system is not class scoped
    vm.expectRevert(
      abi.encodeWithSelector(ISOFAccessSystem.SOFAccess_AccessDenied.selector, objectId, address(unscopedSystem))
    );
    world.call(UNSCOPED_SYSTEM_ID, abi.encodeCall(UnscopedMock.callScopedRevokeAll, (objectId, adminRole)));

    // success, via the class scoped system call
    vm.prank(deployer);
    world.call(CLASS_SCOPED_SYSTEM_ID, abi.encodeCall(ClassScopedMock.callScopedRevokeAll, (objectId, adminRole)));

    // EntitySystemm calling case success proven in EntitySystem.deleteClass and EntitySystem.deleteObject tests above
  }
}
