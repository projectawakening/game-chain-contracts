// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { console } from "forge-std/console.sol";

import { World } from "@latticexyz/world/src/World.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdInstance, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_NAMESPACE, RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";

import { DEPLOYMENT_NAMESPACE } from "../src/namespaces/evefrontier/constants.sol";
import { IRoleManagementSystem } from "../src/namespaces/evefrontier/interfaces/IRoleManagementSystem.sol";
import { Utils as RoleManagementSystemUtils } from "../src/namespaces/evefrontier/systems/role-management-system/Utils.sol";
import { IEntitySystem } from "../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { Utils as EntitySystemUtils } from "../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { Utils as TagSystemUtils } from "../src/namespaces/evefrontier/systems/tag-system/Utils.sol";
import { SystemMock } from "./mocks/SystemMock.sol";

import "../src/namespaces/evefrontier/codegen/index.sol";

import { Id, IdLib } from "../src/libs/Id.sol";
import { ENTITY_CLASS, ENTITY_OBJECT } from "../src/types/entityTypes.sol";
import { TAG_SYSTEM } from "../src/types/tagTypes.sol";

contract EntitySystemTest is MudTest {
  IBaseWorld world;
  SystemMock taggedSystemMock;
  SystemMock taggedSystemMock2;
  SystemMock unTaggedSystemMock;

  bytes14 constant NAMESPACE = DEPLOYMENT_NAMESPACE;
  ResourceId constant NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, NAMESPACE)));
  ResourceId ROLE_MANAGEMENT_SYSTEM_ID = RoleManagementSystemUtils.roleManagementSystemId();
  ResourceId ENTITIES_SYSTEM_ID = EntitySystemUtils.entitySystemId();
  ResourceId TAGS_SYSTEM_ID = TagSystemUtils.tagSystemId();
  ResourceId TAGGED_SYSTEM_ID =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("TaggedSystemMock")))));
  ResourceId constant TAGGED_SYSTEM_ID_2 =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("TaggedSystemMoc2")))));

  Id classId = IdLib.encode(ENTITY_CLASS, bytes30("TEST_CLASS"));
  bytes32 classAccessRole = bytes32("TEST_CLASS_ACCESS_ROLE");
  Id classId2 = IdLib.encode(ENTITY_CLASS, bytes30("TEST_CLASS_2"));
  Id objectId = IdLib.encode(ENTITY_OBJECT, bytes30("TEST_OBJECT"));
  Id objectId2 = IdLib.encode(ENTITY_OBJECT, bytes30("TEST_OBJECT_2"));
  Id taggedSystemTagId = IdLib.encode(TAG_SYSTEM, TAGGED_SYSTEM_ID.getResourceName());
  Id taggedSystemTagId2 = IdLib.encode(TAG_SYSTEM, TAGGED_SYSTEM_ID_2.getResourceName());

  string constant mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  address deployer = vm.addr(deployerPK);
  function setUp() public override {
    // DEPLOY AND REGISTER A MUD WORLD
    worldAddress = vm.envAddress("WORLD_ADDRESS");
    world = IBaseWorld(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);

    // deploy and register Mock Systems and functions
    vm.startPrank(deployer);
    taggedSystemMock = new SystemMock();
    world.registerSystem(TAGGED_SYSTEM_ID, System(taggedSystemMock), true);
    world.registerFunctionSelector(TAGGED_SYSTEM_ID, "classLevelScope(bytes32)");
    world.registerFunctionSelector(TAGGED_SYSTEM_ID, "objectLevelScope(bytes32)");

    taggedSystemMock2 = new SystemMock();
    world.registerSystem(TAGGED_SYSTEM_ID_2, System(taggedSystemMock2), true);
    world.registerFunctionSelector(TAGGED_SYSTEM_ID_2, "classLevelScope2(bytes32)");
    world.registerFunctionSelector(TAGGED_SYSTEM_ID_2, "objectLevelScope2(bytes32)");

    vm.stopPrank();
  }

  function testSetup() public {
    // mock systems are registered on the World
    assertEq(ResourceIds.getExists(TAGGED_SYSTEM_ID), true);
    assertEq(ResourceIds.getExists(TAGGED_SYSTEM_ID_2), true);

    // mock functions are registered on the World
    string memory mockTaggedNamespaceString = WorldResourceIdLib.toTrimmedString(
      WorldResourceIdInstance.getNamespace(TAGGED_SYSTEM_ID)
    );
    assertEq(
      ResourceId.unwrap(
        FunctionSelectors.getSystemId(
          bytes4(keccak256(bytes(string.concat(mockTaggedNamespaceString, "__", "classLevelScope(bytes32)"))))
        )
      ),
      ResourceId.unwrap(TAGGED_SYSTEM_ID)
    );
    assertEq(
      ResourceId.unwrap(
        FunctionSelectors.getSystemId(
          bytes4(keccak256(bytes(string.concat(mockTaggedNamespaceString, "__", "objectLevelScope(bytes32)"))))
        )
      ),
      ResourceId.unwrap(TAGGED_SYSTEM_ID)
    );

    string memory mockTagged2NamespaceString = WorldResourceIdLib.toTrimmedString(
      WorldResourceIdInstance.getNamespace(TAGGED_SYSTEM_ID_2)
    );
    assertEq(
      ResourceId.unwrap(
        FunctionSelectors.getSystemId(
          bytes4(keccak256(bytes(string.concat(mockTagged2NamespaceString, "__", "classLevelScope2(bytes32)"))))
        )
      ),
      ResourceId.unwrap(TAGGED_SYSTEM_ID_2)
    );
    assertEq(
      ResourceId.unwrap(
        FunctionSelectors.getSystemId(
          bytes4(keccak256(bytes(string.concat(mockTagged2NamespaceString, "__", "objectLevelScope2(bytes32)"))))
        )
      ),
      ResourceId.unwrap(TAGGED_SYSTEM_ID_2)
    );
  }

  function test_registerClass() public {
    Id[] memory tagIds = new Id[](2);
    tagIds[0] = taggedSystemTagId;
    tagIds[1] = taggedSystemTagId2;
    // reverts if classId is bytes32(0)
    vm.startPrank(deployer);
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_InvalidEntityId.selector, Id.wrap(bytes32(0))));
    world.call(
      ENTITIES_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.registerClass, (Id.wrap(bytes32(0)), classAccessRole, tagIds))
    );

    // reverts if classId is not a Class type
    bytes2[] memory expected = new bytes2[](1);
    expected[0] = ENTITY_CLASS;
    vm.expectRevert(
      abi.encodeWithSelector(IEntitySystem.Entity_WrongEntityType.selector, objectId.getType(), expected)
    );
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (objectId, classAccessRole, tagIds)));

    // reverts if the entrypoint _msgSender() is not a member of the given access role
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_RoleAccessDenied.selector, classAccessRole, deployer));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));

    // create the Class Access Role with the deployer as the only member
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );

    // succesful call
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));

    // after
    assertEq(Classes.getExists(classId), true);

    bytes32[] memory class1SystemTagsAfter = Classes.getSystemTags(classId);
    assertEq(class1SystemTagsAfter.length, 2);
    assertEq(class1SystemTagsAfter[0], Id.unwrap(taggedSystemTagId));
    assertEq(class1SystemTagsAfter[1], Id.unwrap(taggedSystemTagId2));

    // reverts if classId is already registered
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ClassAlreadyExists.selector, classId));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    vm.stopPrank();
  }

  function test_instantiate() public {
    vm.startPrank(deployer);
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );

    // reverts if classId has NOT been registered
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ClassDoesNotExist.selector, classId));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));

    // register classId
    world.call(
      ENTITIES_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, new Id[](0)))
    );

    // reverts if objectId is bytes32(0)
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_InvalidEntityId.selector, Id.wrap(bytes32(0))));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, Id.wrap(bytes32(0)))));

    // reverts if objectId is not an ENTITY_OBJECT type
    bytes2[] memory expected = new bytes2[](1);
    expected[0] = ENTITY_OBJECT;
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_WrongEntityType.selector, classId.getType(), expected));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, classId)));

    // successful call
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));
    // after checks
    // creates an entry in the EntityIds table
    assertEq(Objects.getExists(objectId), true);

    // correctly creates/updates entries for the Classes, Objects, and ClassObjectMap Tables
    bytes32[] memory classObjectAfter = Classes.getObjects(classId);
    assertEq(classObjectAfter.length, 1);
    assertEq(classObjectAfter[0], Id.unwrap(objectId));

    Id instanceOf = Objects.getClass(objectId);
    assertEq(Id.unwrap(instanceOf), Id.unwrap(classId));

    ClassObjectMapData memory classObjectMapData = ClassObjectMap.get(classId, objectId);
    assertEq(classObjectMapData.instanceOf, true);
    assertEq(classObjectMapData.objectIndex, 0);

    // reverts if objectId is already instantiated
    Id instanceClass = Objects.getClass(objectId);
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ObjectAlreadyExists.selector, objectId, instanceClass));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));
    vm.stopPrank();
  }

  function test_deleteObject() public {
    vm.startPrank(deployer);
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );

    // setup - register classId
    world.call(
      ENTITIES_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, new Id[](0)))
    );

    // reverts if objectId doesn't exist (hasn't been instantiated)
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ObjectDoesNotExist.selector, objectId));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));

    // check data state
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId2)));
    // before
    bytes32[] memory classObjectsBefore = Classes.getObjects(classId);
    assertEq(classObjectsBefore.length, 2);
    assertEq(classObjectsBefore[0], Id.unwrap(objectId));
    assertEq(classObjectsBefore[1], Id.unwrap(objectId2));

    ClassObjectMapData memory classObject1MapDataBefore = ClassObjectMap.get(classId, objectId);
    assertEq(classObject1MapDataBefore.instanceOf, true);
    assertEq(classObject1MapDataBefore.objectIndex, 0);

    ClassObjectMapData memory classObject2MapDataBefore = ClassObjectMap.get(classId, objectId2);
    assertEq(classObject2MapDataBefore.instanceOf, true);
    assertEq(classObject2MapDataBefore.objectIndex, 1);

    // successful call

    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));

    // after
    // Classes.objects array correctly updated
    bytes32[] memory classObjectsAfter = Classes.getObjects(classId);
    assertEq(classObjectsAfter.length, 1);
    assertEq(classObjectsAfter[0], Id.unwrap(objectId2));

    // ClassObjectMap for removed object deleted
    ClassObjectMapData memory classObject1MapDataAfter = ClassObjectMap.get(classId, objectId);
    assertEq(classObject1MapDataAfter.instanceOf, false);
    assertEq(classObject1MapDataAfter.objectIndex, 0);

    // ClassObjectMap for last object correctly updated
    ClassObjectMapData memory classObject2MapDataAfter = ClassObjectMap.get(classId, objectId2);
    assertEq(classObject2MapDataAfter.instanceOf, true);
    assertEq(classObject2MapDataAfter.objectIndex, 0);

    // Objects entry deleted
    assertEq(Objects.getExists(objectId), false);
    vm.stopPrank();
  }

  function test_deleteObjects() public {
    vm.startPrank(deployer);
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );

    // correctly calls and executes deleteObject for multiple objectIds
    world.call(
      ENTITIES_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, new Id[](0)))
    );
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId2)));

    assertEq(Objects.getExists(objectId), true);
    assertEq(Id.unwrap(Objects.getClass(objectId)), Id.unwrap(classId));
    assertEq(Objects.getExists(objectId2), true);
    assertEq(Id.unwrap(Objects.getClass(objectId2)), Id.unwrap(classId));

    Id[] memory objectsToDelete = new Id[](2);
    objectsToDelete[0] = objectId;
    objectsToDelete[1] = objectId2;

    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObjects, (objectsToDelete)));

    assertEq(Objects.getExists(objectId), false);
    assertEq(Id.unwrap(Objects.getClass(objectId)), bytes32(0));
    assertEq(Objects.getExists(objectId2), false);
    assertEq(Id.unwrap(Objects.getClass(objectId2)), bytes32(0));
    vm.stopPrank();
  }

  function test_deleteClass() public {
    vm.startPrank(deployer);
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );

    // reverts if classId doesn't exist (wasn't registered)
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ClassDoesNotExist.selector, classId));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = taggedSystemTagId;
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));

    // reverts if Class has Object(s) instantiated still
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ClassHasObjects.selector, classId, 1));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));

    // check data state updates
    // before
    bytes32[] memory class1SystemTagsBefore = Classes.getSystemTags(classId);
    assertEq(class1SystemTagsBefore.length, 1);
    assertEq(class1SystemTagsBefore[0], Id.unwrap(taggedSystemTagId));

    assertEq(Classes.getExists(classId), true);

    // successful call
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteObject, (objectId)));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClass, (classId)));
    // after
    // removes all SystemTags
    bytes32[] memory class1SystemTagsAfter = Classes.getSystemTags(classId);
    assertEq(class1SystemTagsAfter.length, 0);

    // removes the EntityIds entry
    assertEq(Classes.getExists(classId), false);
    vm.stopPrank();
  }

  function test_deleteClasses() public {
    vm.startPrank(deployer);
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );

    // corectly calls and executes deleteClass for multiple classIds
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = taggedSystemTagId;
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId2, classAccessRole, tagIds)));

    // check data state updates
    // before
    bytes32[] memory class1SystemTagsBefore = Classes.getSystemTags(classId);
    assertEq(class1SystemTagsBefore.length, 1);
    assertEq(class1SystemTagsBefore[0], Id.unwrap(taggedSystemTagId));
    bytes32[] memory class2SystemTagsBefore = Classes.getSystemTags(classId2);
    assertEq(class2SystemTagsBefore.length, 1);
    assertEq(class2SystemTagsBefore[0], Id.unwrap(taggedSystemTagId));
    assertEq(Classes.getExists(classId), true);
    assertEq(Classes.getExists(classId2), true);

    // successful call
    Id[] memory classIds = new Id[](2);
    classIds[0] = classId;
    classIds[1] = classId2;
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.deleteClasses, (classIds)));

    // after
    bytes32[] memory class1SystemTagsAfter = Classes.getSystemTags(classId);
    assertEq(class1SystemTagsAfter.length, 0);
    bytes32[] memory class2SystemTagsAfter = Classes.getSystemTags(classId2);
    assertEq(class2SystemTagsAfter.length, 0);
    assertEq(Classes.getExists(classId), false);
    assertEq(Classes.getExists(classId2), false);
    vm.stopPrank();
  }

  function test_setClassAccessRole() public {
    vm.startPrank(deployer);
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = taggedSystemTagId;
    // create original Class access role
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );
    // register Class
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    // set invalid params
    Id invalidClassId = IdLib.encode(ENTITY_CLASS, bytes30("INVALID_CLASS"));
    bytes32 invalidRole = bytes32("INVALID_ROLE");

    // reverts, if classId in not registered
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ClassDoesNotExist.selector, invalidClassId));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.setClassAccessRole, (invalidClassId, classAccessRole)));

    // reverts, if newAccessRole does not exist
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_RoleDoesNotExist.selector, invalidRole));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.setClassAccessRole, (classId, invalidRole)));

    //check old access role
    bytes32 accessRoleBefore = Classes.getAccessRole(classId);
    assertEq(accessRoleBefore, classAccessRole);

    bytes32 newClassAccessRole = bytes32("NEW_CLASS_ACCESS_ROLE");
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (newClassAccessRole, newClassAccessRole))
    );
    // success
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.setClassAccessRole, (classId, newClassAccessRole)));

    //check new access role
    bytes32 accessRoleAfter = Classes.getAccessRole(classId);
    assertEq(accessRoleAfter, newClassAccessRole);
    vm.stopPrank();
  }

  function test_setObjectAccessRole() public {
    vm.startPrank(deployer);
    Id[] memory tagIds = new Id[](1);
    tagIds[0] = taggedSystemTagId;
    // create Class access role
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );
    // register Class
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.registerClass, (classId, classAccessRole, tagIds)));
    // instantiate Object
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.instantiate, (classId, objectId)));

    // set invalid params
    Id invalidObjectId = IdLib.encode(ENTITY_CLASS, bytes30("INVALID_OBJECT"));
    bytes32 invalidRole = bytes32("INVALID_ROLE");

    // reverts, if objectId in not instantiated
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_ObjectDoesNotExist.selector, invalidObjectId));
    world.call(
      ENTITIES_SYSTEM_ID,
      abi.encodeCall(IEntitySystem.setObjectAccessRole, (invalidObjectId, classAccessRole))
    );

    // reverts, if newAccessRole does not exist
    vm.expectRevert(abi.encodeWithSelector(IEntitySystem.Entity_RoleDoesNotExist.selector, invalidRole));
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.setObjectAccessRole, (objectId, invalidRole)));

    //check old access role
    bytes32 accessRoleBefore = Objects.getAccessRole(objectId);
    assertEq(accessRoleBefore, bytes32(0));

    bytes32 newObjectAccessRole = bytes32("NEW_OBJECT_ACCESS_ROLE");
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (newObjectAccessRole, newObjectAccessRole))
    );
    // success
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(IEntitySystem.setObjectAccessRole, (objectId, newObjectAccessRole)));

    //check new access role
    bytes32 accessRoleAfter = Objects.getAccessRole(objectId);
    assertEq(accessRoleAfter, newObjectAccessRole);
    vm.stopPrank();
  }
}
