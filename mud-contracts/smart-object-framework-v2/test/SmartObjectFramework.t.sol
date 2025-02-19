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

import { DEPLOYMENT_NAMESPACE } from "../src/namespaces/evefrontier/constants.sol";
import { entitySystem } from "../src/namespaces/evefrontier/codegen/systems/EntitySystemLib.sol";
import { tagSystem } from "../src/namespaces/evefrontier/codegen/systems/TagSystemLib.sol";
import { accessConfigSystem } from "../src/namespaces/evefrontier/codegen/systems/AccessConfigSystemLib.sol";

import { SystemMock } from "./mocks/SystemMock.sol";
import { AccessSystemMock } from "./mocks/AccessSystemMock.sol";

import "../src/namespaces/evefrontier/codegen/index.sol";

import { TagId, TagIdLib } from "../src/libs/TagId.sol";

import { TAG_TYPE_PROPERTY, TAG_TYPE_ENTITY_RELATION, TAG_TYPE_RESOURCE_RELATION, TAG_IDENTIFIER_CLASS, TAG_IDENTIFIER_OBJECT, TAG_IDENTIFIER_ENTITY_COUNT, TagParams, EntityRelationValue, ResourceRelationValue } from "../src/namespaces/evefrontier/systems/tag-system/types.sol";

import { SmartObjectFramework } from "../src/inherit/SmartObjectFramework.sol";

contract SmartObjectFrameworkTest is MudTest {
  IBaseWorld world;
  SystemMock taggedSystemMock;
  SystemMock unTaggedSystemMock;
  AccessSystemMock accessSystemMock;

  bytes14 constant NAMESPACE = DEPLOYMENT_NAMESPACE;
  ResourceId constant NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, NAMESPACE)));

  ResourceId constant TAGGED_SYSTEM_ID =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("TaggedSystemMock")))));
  ResourceId constant UNTAGGED_SYSTEM_ID =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("UnTaggedSystemMo")))));
  ResourceId constant ACCESS_NAMESPACE_ID =
    ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, bytes14("AccessNamespac"))));
  ResourceId ACCESS_SYSTEM_ID =
    ResourceId.wrap(
      (bytes32(abi.encodePacked(RESOURCE_SYSTEM, bytes14("AccessNamespac"), bytes16("AccessSystemMock"))))
    );

  uint256 classId = uint256(bytes32("TEST_CLASS"));
  uint256 unTaggedClassId = uint256(bytes32("TEST_FAIL_CLASS"));
  uint256 objectId = uint256(bytes32("TEST_OBJECT"));
  uint256 unTaggedObjectId = uint256(bytes32("TEST_FAIL_OBJECT"));
  TagId taggedSystemTagId = TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(TAGGED_SYSTEM_ID)));
  TagId unTaggedSystemTagId =
    TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(UNTAGGED_SYSTEM_ID)));

  TagId CLASS_PROPERTY_TAG = TagIdLib.encode(TAG_TYPE_PROPERTY, TAG_IDENTIFIER_CLASS);
  TagId OBJECT_PROPERTY_TAG = TagIdLib.encode(TAG_TYPE_PROPERTY, TAG_IDENTIFIER_OBJECT);

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

    // deploy and register tagged and untagged SystemMock.sol, and functions
    vm.startPrank(deployer);
    taggedSystemMock = new SystemMock();
    world.registerSystem(TAGGED_SYSTEM_ID, System(taggedSystemMock), true);

    unTaggedSystemMock = new SystemMock();
    world.registerSystem(UNTAGGED_SYSTEM_ID, System(unTaggedSystemMock), true);

    // register access namespace and system
    world.registerNamespace(ACCESS_NAMESPACE_ID);
    accessSystemMock = new AccessSystemMock();
    world.registerSystem(ACCESS_SYSTEM_ID, System(accessSystemMock), true);

    // system tags (only add the tagged systems)
    ResourceId[] memory scopedSystemIds = new ResourceId[](1);
    scopedSystemIds[0] = TAGGED_SYSTEM_ID;

    // register Class (with a taggedSystem tag)
    entitySystem.registerClass(classId, scopedSystemIds);

    // register Class without system tags
    entitySystem.registerClass(unTaggedClassId, new ResourceId[](0));

    // instantiate system resource tagged Class->Object
    entitySystem.instantiate(classId, objectId, alice);

    // instantiate Class->Object without system tags
    entitySystem.instantiate(unTaggedClassId, unTaggedObjectId, alice);

    vm.stopPrank();
  }

  function testSetup() public {
    // mock systems are registered on the World
    assertEq(ResourceIds.getExists(TAGGED_SYSTEM_ID), true);
    assertEq(ResourceIds.getExists(UNTAGGED_SYSTEM_ID), true);

    // check Class is registered
    assertEq(Entity.getExists(classId), true);

    // check system tagged SystemMock<>Class tag
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId), true);

    // check Class->Object instantiation
    TagId objectEntityRealtionTagId = TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(objectId)));
    EntityRelationValue memory entityRelationValue = abi.decode(
      EntityTagMap.getValue(objectId, objectEntityRealtionTagId),
      (EntityRelationValue)
    );
    assertEq(entityRelationValue.relatedEntityId, classId);

    // // check Object is created
    // assertEq(Entity.getExists(objectId), true);

    // // check non-system tagged Object is created
    // assertEq(Entity.getExists(unTaggedObjectId), true);
  }

  function test_scope_Class() public {
    // revert call TaggedSystemMock using unTaggedClassId
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, unTaggedClassId, TAGGED_SYSTEM_ID)
    );
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.classLevelScope, (unTaggedClassId)));

    // revert call UntaggedSystemMock using classId
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, classId, UNTAGGED_SYSTEM_ID)
    );
    world.call(UNTAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.classLevelScope, (classId)));

    // success call TaggedSystemMock using classId
    bytes memory returnData = world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.classLevelScope, (classId)));
    assertEq(abi.decode(returnData, (bool)), true);
  }

  function test_scope_Object() public {
    // check scope by Class inheritance for Object
    // revert call SystemMock using untaggedObjectId
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, unTaggedObjectId, TAGGED_SYSTEM_ID)
    );
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.objectLevelScope, (unTaggedObjectId)));

    // revert call UntaggedSystemMock using untagged objectId
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, objectId, UNTAGGED_SYSTEM_ID)
    );
    world.call(UNTAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.objectLevelScope, (objectId)));

    // success call SystemMock using the tagged objectId
    bytes memory returnData = world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.objectLevelScope, (objectId)));

    assertEq(abi.decode(returnData, (bool)), true);

    // check scope direct by Object (only)
    // remove classTag
    tagSystem.removeTag(classId, taggedSystemTagId);

    // revert call SystemMock using objectId (but tag was temporarily removed)
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, objectId, TAGGED_SYSTEM_ID)
    );
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.objectLevelScope, (objectId)));

    // add Object tag
    tagSystem.setTag(
      objectId,
      TagParams(
        taggedSystemTagId,
        abi.encode(ResourceRelationValue("COMPOSITION", RESOURCE_SYSTEM, TAGGED_SYSTEM_ID.getResourceName()))
      )
    );

    // success
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.objectLevelScope, (objectId)));
  }

  // internal scope enforcement
  function test_scope_internal() public {
    // revert, if a call chain leaves scope and tries to call back into scope
    vm.expectRevert(
      abi.encodeWithSelector(SmartObjectFramework.SOF_UnscopedSystemCall.selector, classId, UNTAGGED_SYSTEM_ID)
    );
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.entryScoped, (classId, false)));

    bytes memory returnData = world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.entryScoped, (classId, true)));
    (, , bool result) = abi.decode(returnData, (bytes32, bytes32, bool));
    assertEq(result, true);
  }

  function test_context() public {
    // revert, test WorldContextProvider cannot be used to make direct calls
    vm.expectRevert(bytes(""));
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.callFromWorldContextProviderLib, ()));

    // revert, test WorldContextProvider cannot be used to make direct delegatecalls to functions with context()
    vm.expectRevert(SmartObjectFramework.SOF_InvalidCall.selector);
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.delegatecallFromWorldContextProviderLib, ()));
  }

  function test_enforceCallCount() public {
    // revert, secondary internal call count exceeds the call count limit
    vm.expectRevert(abi.encodeWithSelector(SmartObjectFramework.SOF_CallTooDeep.selector, 2));
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.callToEnforceCallCount1, ()));

    // success, direct call (under the call count limit)
    world.call(TAGGED_SYSTEM_ID, abi.encodeCall(SystemMock.callEnforceCallCount1, ()));
  }

  // access test
  function test_access() public {
    vm.startPrank(deployer);
    // configure Access configuration for SystemMock
    accessConfigSystem.configureAccess(
      TAGGED_SYSTEM_ID,
      SystemMock.accessControlled.selector,
      ACCESS_SYSTEM_ID,
      AccessSystemMock.invalidAccessController.selector
    );

    // set enforcement
    accessConfigSystem.setAccessEnforcement(TAGGED_SYSTEM_ID, SystemMock.accessControlled.selector, true);

    // revert, if a non-static call was made yto access logic
    vm.expectRevert(bytes(""));
    world.call(
      TAGGED_SYSTEM_ID,
      abi.encodeCall(SystemMock.accessControlled, (classId, TAGGED_SYSTEM_ID, SystemMock.accessControlled.selector))
    );

    // re-configure Access configuration for SystemMock
    accessConfigSystem.configureAccess(
      TAGGED_SYSTEM_ID,
      SystemMock.accessControlled.selector,
      ACCESS_SYSTEM_ID,
      AccessSystemMock.accessController.selector
    );

    // re-set enforcement
    accessConfigSystem.setAccessEnforcement(TAGGED_SYSTEM_ID, SystemMock.accessControlled.selector, true);

    // revert, to check verification data failure
    vm.expectRevert(abi.encodeWithSelector(AccessSystemMock.AccessSystemMock_IncorrectCallData.selector));
    world.call(
      TAGGED_SYSTEM_ID,
      abi.encodeCall(
        SystemMock.accessControlled,
        (classId, UNTAGGED_SYSTEM_ID, SystemMock.callEnforceCallCount1.selector)
      )
    );

    // successful call
    world.call(
      TAGGED_SYSTEM_ID,
      abi.encodeCall(SystemMock.accessControlled, (classId, TAGGED_SYSTEM_ID, SystemMock.accessControlled.selector))
    );
    // the above success proves the following:
    // check entityId and targetCallData are passed correctly to the access logic
    // check that call count is not affected by the access logic call
    // check that the correct access function is called by the correct target
    vm.stopPrank();
  }
}
