import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  deploy: {
    customWorld: {
      sourcePath: "src/WorldWithContext.sol",
      name: "WorldWithContext",
    },
  },
  userTypes: {
    TagId: { type: "bytes32", filePath: "./src/libs/TagId.sol" },
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
        Entity: {
          schema: {
            entityId: "uint256",
            exists: "bool",
            accessRole: "bytes32",
            entityRelationTag: "TagId",
            propertyTags: "bytes32[]",
            resourceRelationTags: "bytes32[]",
          },
          key: ["entityId"],
        },
        EntityTagMap: {
          schema: {
            entityId: "uint256",
            tagId: "TagId",
            hasTag: "bool",
            tagIndex: "uint256",
            value: "bytes",
          },
          key: ["entityId", "tagId"],
        },
      },
    },
  },
});
