import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  deploy: {
    customWorld: {
      sourcePath: "src/WorldWithContext.sol",
      name: "WorldWithContext",
    },
  },
  userTypes: {
    Id: { type: "bytes32", filePath: "./src/libs/Id.sol" },
    ResourceId: { type: "bytes32", filePath: "@latticexyz/store/src/ResourceId.sol" },
  },
  excludeSystems: ["SmartObjectFramework"],
  namespaces: {
    sofaccess: {
      systems: {
        SOFAccessSystem: {
          name: "SOFAccessSystem",
          openAccess: true,
        },
      },
    },
    evefrontier: {
      systems: {
        AccessConfigSystem: {
          name: "AccessConfigSyst",
          openAccess: true,
        },
        RoleManagementSystem: {
          name: "RoleManagementSy",
          openAccess: true,
        },
        EntitySystem: {
          name: "EntitySystem",
          openAccess: true,
        },
        TagSystem: {
          name: "TagSystem",
          openAccess: true,
        },
      },
      tables: {
        /*******************
         * ACCESS CONFIG, ROLE, AND ROLE MEMBERSHIP DATA *
         *******************/
        AccessConfig: {
          schema: {
            target: "bytes32",
            configured: "bool",
            targetSystemId: "ResourceId",
            targetFunctionId: "bytes4",
            accessSystemId: "ResourceId",
            accessFunctionId: "bytes4",
            enforcement: "bool",
          },
          key: ["target"],
        },
        Role: {
          schema: {
            role: "bytes32",
            exists: "bool",
            admin: "bytes32",
          },
          key: ["role"],
        },
        HasRole: {
          schema: {
            role: "bytes32",
            account: "address",
            hasRole: "bool",
          },
          key: ["role", "account"],
        },
        /*******************
         * ENTITES and ENTITY MAPPED DATA *
         *******************/
        Classes: {
          schema: {
            classId: "Id",
            exists: "bool",
            accessRole: "bytes32",
            systemTags: "bytes32[]",
            objects: "bytes32[]",
          },
          key: ["classId"],
        },
        ClassSystemTagMap: {
          schema: {
            classId: "Id",
            tagId: "Id",
            hasTag: "bool",
            classIndex: "uint256",
            tagIndex: "uint256",
          },
          key: ["classId", "tagId"],
        },
        ClassObjectMap: {
          schema: {
            classId: "Id",
            objectId: "Id",
            instanceOf: "bool",
            objectIndex: "uint256",
          },
          key: ["classId", "objectId"],
        },
        Objects: {
          schema: {
            objectId: "Id",
            exists: "bool",
            class: "Id",
            accessRole: "bytes32",
            systemTags: "bytes32[]",
          },
          key: ["objectId"],
        },
        ObjectSystemTagMap: {
          schema: {
            objectId: "Id",
            tagId: "Id",
            hasTag: "bool",
            objectIndex: "uint256",
            tagIndex: "uint256",
          },
          key: ["objectId", "tagId"],
        },
        /*******************
         * TAGS *
         *******************/
        SystemTags: {
          schema: {
            tagId: "Id",
            exists: "bool",
            classes: "bytes32[]",
            objects: "bytes32[]",
          },
          key: ["tagId"],
        },
      },
    },
  },
});
