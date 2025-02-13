// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
import { EntitySystem } from "../src/namespaces/evefrontier/systems/entity-system/EntitySystem.sol";
import { Utils as EntitySystemUtils } from "../src/namespaces/evefrontier/systems/entity-system/Utils.sol";
import { TagSystem } from "../src/namespaces/evefrontier/systems/tag-system/TagSystem.sol";
import { Utils as TagSystemUtils } from "../src/namespaces/evefrontier/systems/tag-system/Utils.sol";
import { SystemMock } from "./mocks/SystemMock.sol";

import "../src/namespaces/evefrontier/codegen/index.sol";

import { IEntitySystem } from "../src/namespaces/evefrontier/interfaces/IEntitySystem.sol";
import { ITagSystem } from "../src/namespaces/evefrontier/interfaces/ITagSystem.sol";

import { TagId, TagIdLib } from "../src/libs/TagId.sol";

import { TAG_TYPE_PROPERTY, TAG_TYPE_ENTITY_RELATION, TAG_TYPE_RESOURCE_RELATION, TAG_IDENTIFIER_CLASS, TAG_IDENTIFIER_OBJECT, TAG_IDENTIFIER_ENTITY_COUNT, TagParams, EntityRelationValue, ResourceRelationValue } from "../src/namespaces/evefrontier/systems/tag-system/types.sol";

contract TagSystemTest is MudTest {
  IBaseWorld world;
  EntitySystem entitySystem;
  TagSystem tagSystem;
  SystemMock taggedSystemMock;
  SystemMock taggedSystemMock2;
  SystemMock taggedSystemMock3;
  SystemMock unTaggedSystemMock;

  bytes14 constant NAMESPACE = DEPLOYMENT_NAMESPACE;
  ResourceId constant NAMESPACE_ID = ResourceId.wrap(bytes32(abi.encodePacked(RESOURCE_NAMESPACE, NAMESPACE)));
  ResourceId ROLE_MANAGEMENT_SYSTEM_ID = RoleManagementSystemUtils.roleManagementSystemId();
  ResourceId ENTITIES_SYSTEM_ID = EntitySystemUtils.entitySystemId();
  ResourceId TAGS_SYSTEM_ID = TagSystemUtils.tagSystemId();
  ResourceId constant TAGGED_SYSTEM_ID =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("TaggedSystem")))));
  ResourceId constant TAGGED_SYSTEM_ID_2 =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("TaggedSystem2")))));
  ResourceId constant TAGGED_SYSTEM_ID_3 =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("TaggedSystem3")))));
  ResourceId constant UNTAGGED_SYSTEM_ID =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("UnTaggedSystem")))));
  ResourceId constant UNREGISTERED_SYSTEM_ID =
    ResourceId.wrap((bytes32(abi.encodePacked(RESOURCE_SYSTEM, NAMESPACE, bytes16("UnregisteredSy")))));

  uint256 invalidEntityId = uint256(bytes32("INVALID_ENTITY"));
  uint256 classId = uint256(bytes32("TEST_CLASS"));
  bytes32 classAccessRole = bytes32("TEST_CLASS_ACCESS_ROLE");
  uint256 classId2 = uint256(bytes32("TEST_CLASS_2"));
  uint256 objectId = uint256(bytes32("TEST_OBJECT"));
  uint256 objectId2 = uint256(bytes32("TEST_OBJECT_2"));
  uint256 unregisteredClassId = uint256(bytes32("FAIL_REGISTER_CLASS"));
  TagId taggedSystemTagId = TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(TAGGED_SYSTEM_ID)));
  TagId taggedSystemTagId2 =
    TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(TAGGED_SYSTEM_ID_2)));
  TagId taggedSystemTagId3 =
    TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(TAGGED_SYSTEM_ID_3)));
  TagId untaggedSystemTagId =
    TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(UNTAGGED_SYSTEM_ID)));
  TagId unregisteredSystemTagId =
    TagIdLib.encode(TAG_TYPE_RESOURCE_RELATION, bytes30(ResourceId.unwrap(UNREGISTERED_SYSTEM_ID)));

  TagId OBJECT_RELATION_TAG = TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(objectId)));

  TagId CLASS_PROPERTY_TAG = TagIdLib.encode(TAG_TYPE_PROPERTY, TAG_IDENTIFIER_CLASS);
  TagId OBJECT_PROPERTY_TAG = TagIdLib.encode(TAG_TYPE_PROPERTY, TAG_IDENTIFIER_OBJECT);
  TagId ENTITY_COUNT_PROPERTY_TAG = TagIdLib.encode(TAG_TYPE_PROPERTY, TAG_IDENTIFIER_ENTITY_COUNT);

  TagId COLOR_TAG = TagIdLib.encode(TAG_TYPE_PROPERTY, bytes30("COLOR"));

  string constant mnemonic = "test test test test test test test test test test test junk";
  uint256 deployerPK = vm.deriveKey(mnemonic, 0);
  address deployer = vm.addr(deployerPK);

  function setUp() public override {
    // DEPLOY AND REGISTER A MUD WORLD
    worldAddress = vm.envAddress("WORLD_ADDRESS");
    world = IBaseWorld(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);

    // deploy and register mock systems and functions
    vm.startPrank(deployer);
    taggedSystemMock = new SystemMock();
    world.registerSystem(TAGGED_SYSTEM_ID, System(taggedSystemMock), true);

    taggedSystemMock2 = new SystemMock();
    world.registerSystem(TAGGED_SYSTEM_ID_2, System(taggedSystemMock2), true);

    taggedSystemMock3 = new SystemMock();
    world.registerSystem(TAGGED_SYSTEM_ID_3, System(taggedSystemMock3), true);

    unTaggedSystemMock = new SystemMock();
    world.registerSystem(UNTAGGED_SYSTEM_ID, System(unTaggedSystemMock), true);

    // create the Class Access Role with the deployer as the only member
    world.call(
      ROLE_MANAGEMENT_SYSTEM_ID,
      abi.encodeCall(IRoleManagementSystem.createRole, (classAccessRole, classAccessRole))
    );

    // register Class without any additional tags
    world.call(
      ENTITIES_SYSTEM_ID,
      abi.encodeCall(EntitySystem.registerClass, (classId, classAccessRole, new ResourceId[](0)))
    );

    // register Class2 without any additional tags
    world.call(
      ENTITIES_SYSTEM_ID,
      abi.encodeCall(EntitySystem.registerClass, (classId2, classAccessRole, new ResourceId[](0)))
    );
    vm.stopPrank();
  }

  function testSetup() public {
    // mock systems are registered on the World
    assertEq(ResourceIds.getExists(TAGGED_SYSTEM_ID), true);
    assertEq(ResourceIds.getExists(TAGGED_SYSTEM_ID_2), true);
    assertEq(ResourceIds.getExists(TAGGED_SYSTEM_ID_3), true);
    assertEq(ResourceIds.getExists(UNTAGGED_SYSTEM_ID), true);

    // check Classes are registered
    assertEq(Entity.getExists(classId), true);
    assertEq(Entity.getExists(classId2), true);
  }

  function test_setTag() public {
    vm.startPrank(deployer);

    // revert for bytes32(0) tagId
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidTagId.selector, TagId.wrap(bytes32(0))));
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(TagSystem.setTag, (classId, TagParams(TagId.wrap(bytes32(0)), bytes(""))))
    );

    // TAG_TYPE_PROPERTY
    // ONLY EntitySystem can set CLASS, OBJECT, ENTITY_COUNT tags
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.setTag, (objectId, TagParams(CLASS_PROPERTY_TAG, bytes("")))));

    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.setTag, (objectId, TagParams(OBJECT_PROPERTY_TAG, bytes("")))));

    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(TagSystem.setTag, (objectId, TagParams(ENTITY_COUNT_PROPERTY_TAG, bytes(""))))
    );

    // TAG_TYPE_ENTITY_RELATION
    // ONLY EntitySystem can set INHERITANCE type ENTITY_RELATION tags
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (objectId, TagParams(OBJECT_RELATION_TAG, abi.encode(EntityRelationValue("INHERITANCE", classId))))
      )
    );

    // TAG_TYPE_RESOURCE_RELATION
    // reverts if the RESOURCE RELATION Tag's correlated resourceId has not been registered on the World
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_ResourceNotRegistered.selector, UNREGISTERED_SYSTEM_ID));
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (
          classId,
          TagParams(
            unregisteredSystemTagId,
            abi.encode(
              ResourceRelationValue(
                "COMPOSITION",
                UNREGISTERED_SYSTEM_ID.getType(),
                UNREGISTERED_SYSTEM_ID.getResourceName()
              )
            )
          )
        )
      )
    );

    // INVALID TAG TYPE
    // revert Tag_TagTypeNotDefined(TagId.getType(inputTagData.tagId));
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_TagTypeNotDefined.selector, bytes2("XX")));
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (classId, TagParams(TagIdLib.encode(bytes2("XX"), bytes30("INVALID_TAG_TYPE")), bytes("")))
      )
    );

    // SUCCESS CASE

    // check data tables
    // before (class)
    bytes32[] memory classPropertyTagsBefore = Entity.getPropertyTags(classId);
    assertEq(classPropertyTagsBefore.length, 2);
    assertEq(classPropertyTagsBefore[0], TagId.unwrap(CLASS_PROPERTY_TAG));
    assertEq(classPropertyTagsBefore[1], TagId.unwrap(ENTITY_COUNT_PROPERTY_TAG));
    assertEq(EntityTagMap.getHasTag(classId, COLOR_TAG), false);

    assertEq(TagId.unwrap(Entity.getEntityRelationTag(classId)), bytes32(0));
    assertEq(
      EntityTagMap.getHasTag(classId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(classId)))),
      false
    );

    bytes32[] memory classSystemTagsBefore = Entity.getResourceRelationTags(classId);
    assertEq(classSystemTagsBefore.length, 0);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId), false);

    // before (object)
    bytes32[] memory objectPropertyTagsBefore = Entity.getPropertyTags(objectId);
    assertEq(objectPropertyTagsBefore.length, 0);
    assertEq(EntityTagMap.getHasTag(objectId, COLOR_TAG), false);

    assertEq(TagId.unwrap(Entity.getEntityRelationTag(objectId)), bytes32(0));
    assertEq(
      EntityTagMap.getHasTag(objectId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(objectId)))),
      false
    );

    bytes32[] memory objectResourceRelationTagsBefore = Entity.getResourceRelationTags(objectId);
    assertEq(objectResourceRelationTagsBefore.length, 0);
    assertEq(EntityTagMap.getHasTag(objectId, taggedSystemTagId), false);

    // successfull calls

    // instantiating object adds classId to the Entity.entityRealtionTag of the object
    world.call(ENTITIES_SYSTEM_ID, abi.encodeCall(EntitySystem.instantiate, (classId, objectId)));

    // add an entityRelationTag for the class (class2 as its super class)
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (
          classId,
          TagParams(
            TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(classId))),
            abi.encode(EntityRelationValue("SUPER_CLASS", classId2))
          )
        )
      )
    );

    // add the COLOR property tag (with value BLUE) for the class
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(TagSystem.setTag, (classId, TagParams(COLOR_TAG, bytes(abi.encode("BLUE")))))
    );

    // a system resource tag for the class
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (
          classId,
          TagParams(
            taggedSystemTagId,
            abi.encode(
              ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID.getType(), TAGGED_SYSTEM_ID.getResourceName())
            )
          )
        )
      )
    );

    // add the COLOR property tag (with value GREEN) for the object
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(TagSystem.setTag, (objectId, TagParams(COLOR_TAG, bytes(abi.encode("GREEN")))))
    );

    // a system resource tag for the object
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (
          objectId,
          TagParams(
            taggedSystemTagId,
            abi.encode(
              ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID.getType(), TAGGED_SYSTEM_ID.getResourceName())
            )
          )
        )
      )
    );

    // check data tables
    // after (class)
    bytes32[] memory classPropertyTagsAfter = Entity.getPropertyTags(classId);
    assertEq(classPropertyTagsAfter.length, 3);
    assertEq(classPropertyTagsAfter[0], TagId.unwrap(CLASS_PROPERTY_TAG));
    assertEq(classPropertyTagsAfter[1], TagId.unwrap(ENTITY_COUNT_PROPERTY_TAG));
    assertEq(classPropertyTagsAfter[2], TagId.unwrap(COLOR_TAG));
    assertEq(EntityTagMap.getHasTag(classId, COLOR_TAG), true);
    assertEq(EntityTagMap.getTagIndex(classId, COLOR_TAG), 2);
    string memory classColorValue = abi.decode(EntityTagMap.getValue(classId, COLOR_TAG), (string));
    assertEq(classColorValue, "BLUE");

    assertEq(
      TagId.unwrap(Entity.getEntityRelationTag(classId)),
      TagId.unwrap(TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(classId))))
    );
    assertEq(
      EntityTagMap.getHasTag(classId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(classId)))),
      true
    );
    EntityRelationValue memory classEntityRelationTagValue = abi.decode(
      EntityTagMap.getValue(classId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(classId)))),
      (EntityRelationValue)
    );
    assertEq(classEntityRelationTagValue.relationType, "SUPER_CLASS");
    assertEq(classEntityRelationTagValue.relatedEntityId, classId2);

    bytes32[] memory classSystemTagsAfter = Entity.getResourceRelationTags(classId);
    assertEq(classSystemTagsAfter.length, 1);
    assertEq(classSystemTagsAfter[0], TagId.unwrap(taggedSystemTagId));
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId), true);
    ResourceRelationValue memory classResourceRelationTagValue = abi.decode(
      EntityTagMap.getValue(classId, taggedSystemTagId),
      (ResourceRelationValue)
    );
    assertEq(classResourceRelationTagValue.relationType, "COMPOSITION");
    assertEq(classResourceRelationTagValue.resourceType, TAGGED_SYSTEM_ID.getType());
    assertEq(classResourceRelationTagValue.resourceIdentifier, TAGGED_SYSTEM_ID.getResourceName());

    // after (object)
    bytes32[] memory objectPropertyTagsAfter = Entity.getPropertyTags(objectId);
    assertEq(objectPropertyTagsAfter.length, 2);
    assertEq(EntityTagMap.getHasTag(objectId, COLOR_TAG), true);
    assertEq(EntityTagMap.getTagIndex(objectId, COLOR_TAG), 1);
    string memory objectColorValue = abi.decode(EntityTagMap.getValue(objectId, COLOR_TAG), (string));
    assertEq(objectColorValue, "GREEN");

    assertEq(
      TagId.unwrap(Entity.getEntityRelationTag(objectId)),
      TagId.unwrap(TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(objectId))))
    );
    assertEq(
      EntityTagMap.getHasTag(objectId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(objectId)))),
      true
    );
    EntityRelationValue memory objectEntityRelationTagValue = abi.decode(
      EntityTagMap.getValue(objectId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(objectId)))),
      (EntityRelationValue)
    );
    assertEq(objectEntityRelationTagValue.relationType, "INHERITANCE");
    assertEq(objectEntityRelationTagValue.relatedEntityId, classId);

    bytes32[] memory objectResourceRelationTagsAfter = Entity.getResourceRelationTags(objectId);
    assertEq(objectResourceRelationTagsAfter.length, 1);
    assertEq(EntityTagMap.getHasTag(objectId, taggedSystemTagId), true);
    ResourceRelationValue memory objectResourceRelationTagValue = abi.decode(
      EntityTagMap.getValue(objectId, taggedSystemTagId),
      (ResourceRelationValue)
    );
    assertEq(objectResourceRelationTagValue.relationType, "COMPOSITION");
    assertEq(objectResourceRelationTagValue.resourceType, TAGGED_SYSTEM_ID.getType());
    assertEq(objectResourceRelationTagValue.resourceIdentifier, TAGGED_SYSTEM_ID.getResourceName());

    // revert if Entity already has this Tag
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_EntityAlreadyHasTag.selector, classId, taggedSystemTagId));
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (
          classId,
          TagParams(
            taggedSystemTagId,
            abi.encode(
              ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID.getType(), TAGGED_SYSTEM_ID.getResourceName())
            )
          )
        )
      )
    );

    vm.stopPrank();
  }

  function test_setTags() public {
    vm.startPrank(deployer);
    bytes32[] memory classResourceTagsBefore = Entity.getResourceRelationTags(classId);
    assertEq(classResourceTagsBefore.length, 0);

    // add three system resource tags for the class
    TagParams[] memory tags = new TagParams[](3);
    tags[0] = TagParams(
      taggedSystemTagId,
      abi.encode(ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID.getType(), TAGGED_SYSTEM_ID.getResourceName()))
    );
    tags[1] = TagParams(
      taggedSystemTagId2,
      abi.encode(
        ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID_2.getType(), TAGGED_SYSTEM_ID_2.getResourceName())
      )
    );
    tags[2] = TagParams(
      taggedSystemTagId3,
      abi.encode(
        ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID_3.getType(), TAGGED_SYSTEM_ID_3.getResourceName())
      )
    );

    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.setTags, (classId, tags)));

    // check stored tag results
    bytes32[] memory classResourceTagsAfter = Entity.getResourceRelationTags(classId);
    assertEq(classResourceTagsAfter.length, 3);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId), true);
    assertEq(EntityTagMap.getTagIndex(classId, taggedSystemTagId), 0);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId2), true);
    assertEq(EntityTagMap.getTagIndex(classId, taggedSystemTagId2), 1);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId3), true);
    assertEq(EntityTagMap.getTagIndex(classId, taggedSystemTagId3), 2);
    ResourceRelationValue memory classResourceRelationTagValue1 = abi.decode(
      EntityTagMap.getValue(classId, taggedSystemTagId),
      (ResourceRelationValue)
    );
    assertEq(classResourceRelationTagValue1.relationType, "COMPOSITION");
    assertEq(classResourceRelationTagValue1.resourceType, TAGGED_SYSTEM_ID.getType());
    assertEq(classResourceRelationTagValue1.resourceIdentifier, TAGGED_SYSTEM_ID.getResourceName());
    ResourceRelationValue memory classResourceRelationTagValue2 = abi.decode(
      EntityTagMap.getValue(classId, taggedSystemTagId2),
      (ResourceRelationValue)
    );
    assertEq(classResourceRelationTagValue2.relationType, "COMPOSITION");
    assertEq(classResourceRelationTagValue2.resourceType, TAGGED_SYSTEM_ID_2.getType());
    assertEq(classResourceRelationTagValue2.resourceIdentifier, TAGGED_SYSTEM_ID_2.getResourceName());
    ResourceRelationValue memory classResourceRelationTagValue3 = abi.decode(
      EntityTagMap.getValue(classId, taggedSystemTagId3),
      (ResourceRelationValue)
    );
    assertEq(classResourceRelationTagValue3.relationType, "COMPOSITION");
    assertEq(classResourceRelationTagValue3.resourceType, TAGGED_SYSTEM_ID_3.getType());
    assertEq(classResourceRelationTagValue3.resourceIdentifier, TAGGED_SYSTEM_ID_3.getResourceName());
  }

  function test_removeTag() public {
    test_setTag();
    vm.startPrank(deployer);
    // add additional property and resource tags so we can test removing a tag from the middle of a list
    // a SHAPE property tag (with value SQUARE) for the class
    TagId SHAPE_TAG = TagIdLib.encode(TAG_TYPE_PROPERTY, bytes30("SHAPE"));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.setTag, (classId, TagParams(SHAPE_TAG, abi.encode("SQUARE")))));
    // another system resource tag for the class
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.setTag,
        (
          classId,
          TagParams(
            taggedSystemTagId2,
            abi.encode(
              ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID_2.getType(), TAGGED_SYSTEM_ID_2.getResourceName())
            )
          )
        )
      )
    );

    // reverts if entityId/tagId map not found
    vm.expectRevert(
      abi.encodeWithSelector(ITagSystem.Tag_TagNotFound.selector, unregisteredClassId, taggedSystemTagId)
    );
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (unregisteredClassId, taggedSystemTagId)));

    // reverts if entityId/tagId map not found
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_TagNotFound.selector, classId, untaggedSystemTagId));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (classId, untaggedSystemTagId)));

    // TAG_TYPE_PROPERTY
    // ONLY EntitySystem can remove CLASS, OBJECT, ENTITY_COUNT tags
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (classId, CLASS_PROPERTY_TAG)));

    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (objectId, OBJECT_PROPERTY_TAG)));

    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (classId, ENTITY_COUNT_PROPERTY_TAG)));

    // TAG_TYPE_ENTITY_RELATION
    // ONLY EntitySystem can remove INHERITANCE type ENTITY_RELATION tags
    vm.expectRevert(abi.encodeWithSelector(ITagSystem.Tag_InvalidCaller.selector, deployer));
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (objectId, OBJECT_RELATION_TAG)));

    // successfull calls

    // remove the entity relation tag from classId
    world.call(
      TAGS_SYSTEM_ID,
      abi.encodeCall(
        TagSystem.removeTag,
        (classId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(classId))))
      )
    );

    // remove the color tag from classId
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (classId, COLOR_TAG)));

    // remove the first tagged system tag from classId
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTag, (classId, taggedSystemTagId)));

    // check data state after
    assertEq(TagId.unwrap(Entity.getEntityRelationTag(classId)), bytes32(0));
    assertEq(
      EntityTagMap.getHasTag(classId, TagIdLib.encode(TAG_TYPE_ENTITY_RELATION, bytes30(bytes32(classId)))),
      false
    );

    bytes32[] memory classPropertyTagsAfter = Entity.getPropertyTags(classId);
    assertEq(classPropertyTagsAfter.length, 3);
    assertEq(classPropertyTagsAfter[0], TagId.unwrap(CLASS_PROPERTY_TAG));
    assertEq(classPropertyTagsAfter[1], TagId.unwrap(ENTITY_COUNT_PROPERTY_TAG));
    assertEq(classPropertyTagsAfter[2], TagId.unwrap(SHAPE_TAG));
    assertEq(EntityTagMap.getHasTag(classId, COLOR_TAG), false);
    assertEq(EntityTagMap.getHasTag(classId, SHAPE_TAG), true);
    assertEq(EntityTagMap.getTagIndex(classId, SHAPE_TAG), 2);
    string memory classShapeValue = abi.decode(EntityTagMap.getValue(classId, SHAPE_TAG), (string));
    assertEq(classShapeValue, "SQUARE");

    bytes32[] memory classSystemTagsAfter = Entity.getResourceRelationTags(classId);
    assertEq(classSystemTagsAfter.length, 1);
    assertEq(classSystemTagsAfter[0], TagId.unwrap(taggedSystemTagId2));
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId), false);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId2), true);
    ResourceRelationValue memory classResourceRelationTagValue = abi.decode(
      EntityTagMap.getValue(classId, taggedSystemTagId2),
      (ResourceRelationValue)
    );
    assertEq(classResourceRelationTagValue.relationType, "COMPOSITION");
    assertEq(classResourceRelationTagValue.resourceType, TAGGED_SYSTEM_ID_2.getType());
    assertEq(classResourceRelationTagValue.resourceIdentifier, TAGGED_SYSTEM_ID_2.getResourceName());

    vm.stopPrank();
  }

  function test_removeTags() public {
    test_setTags();
    vm.startPrank(deployer);
    // add three system resource tags for class 2
    TagParams[] memory tags = new TagParams[](3);
    tags[0] = TagParams(
      taggedSystemTagId,
      abi.encode(ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID.getType(), TAGGED_SYSTEM_ID.getResourceName()))
    );
    tags[1] = TagParams(
      taggedSystemTagId2,
      abi.encode(
        ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID_2.getType(), TAGGED_SYSTEM_ID_2.getResourceName())
      )
    );
    tags[2] = TagParams(
      taggedSystemTagId3,
      abi.encode(
        ResourceRelationValue("COMPOSITION", TAGGED_SYSTEM_ID_3.getType(), TAGGED_SYSTEM_ID_3.getResourceName())
      )
    );

    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.setTags, (classId2, tags)));

    // check data state before
    bytes32[] memory class1ResourceTagsBefore = Entity.getResourceRelationTags(classId);
    assertEq(class1ResourceTagsBefore.length, 3);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId), true);
    assertEq(EntityTagMap.getTagIndex(classId, taggedSystemTagId), 0);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId2), true);
    assertEq(EntityTagMap.getTagIndex(classId, taggedSystemTagId2), 1);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId3), true);
    assertEq(EntityTagMap.getTagIndex(classId, taggedSystemTagId3), 2);

    bytes32[] memory class2ResourceTagsBefore = Entity.getResourceRelationTags(classId2);
    assertEq(class2ResourceTagsBefore.length, 3);
    assertEq(EntityTagMap.getHasTag(classId2, taggedSystemTagId), true);
    assertEq(EntityTagMap.getTagIndex(classId2, taggedSystemTagId), 0);
    assertEq(EntityTagMap.getHasTag(classId2, taggedSystemTagId2), true);
    assertEq(EntityTagMap.getTagIndex(classId2, taggedSystemTagId2), 1);
    assertEq(EntityTagMap.getHasTag(classId2, taggedSystemTagId3), true);
    assertEq(EntityTagMap.getTagIndex(classId2, taggedSystemTagId3), 2);

    // remove tags
    TagId[] memory class1RemoveTags = new TagId[](2);
    class1RemoveTags[0] = taggedSystemTagId3;
    class1RemoveTags[1] = taggedSystemTagId;
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTags, (classId, class1RemoveTags)));

    TagId[] memory class2RemoveTags = new TagId[](2);
    class2RemoveTags[0] = taggedSystemTagId;
    class2RemoveTags[1] = taggedSystemTagId2;
    world.call(TAGS_SYSTEM_ID, abi.encodeCall(TagSystem.removeTags, (classId2, class2RemoveTags)));

    // check data state after
    bytes32[] memory class1ResourceTagsAfter = Entity.getResourceRelationTags(classId);
    assertEq(class1ResourceTagsAfter.length, 1);
    assertEq(class1ResourceTagsAfter[0], TagId.unwrap(taggedSystemTagId2));
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId), false);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId2), true);
    assertEq(EntityTagMap.getHasTag(classId, taggedSystemTagId3), false);

    bytes32[] memory class2ResourceTagsAfter = Entity.getResourceRelationTags(classId2);
    assertEq(class2ResourceTagsAfter.length, 1);
    assertEq(class2ResourceTagsAfter[0], TagId.unwrap(taggedSystemTagId3));
    assertEq(EntityTagMap.getHasTag(classId2, taggedSystemTagId), false);
    assertEq(EntityTagMap.getHasTag(classId2, taggedSystemTagId2), false);
    assertEq(EntityTagMap.getHasTag(classId2, taggedSystemTagId3), true);

    vm.stopPrank();
  }
}
