// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";

import { PuppetMaster } from "@latticexyz/world-modules/src/modules/puppet/PuppetMaster.sol";
import { toTopic } from "@latticexyz/world-modules/src/modules/puppet/utils.sol";

import { EveSystem } from "@eveworld/smart-object-framework/src/systems/internal/EveSystem.sol";
import { STATIC_DATA_DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";

import { AccessModified } from "../access/systems/AccessModified.sol";
import { StaticDataGlobalTable } from "../../codegen/tables/StaticDataGlobalTable.sol";
import { StaticDataTable } from "../../codegen/tables/StaticDataTable.sol";
import { IStaticDataSystem } from "../static-data/interfaces/IStaticDataSystem.sol";
import { Utils as StaticDataUtils } from "../static-data/Utils.sol";

import { IERC721Receiver } from "./IERC721Receiver.sol";
import { IERC721Mintable } from "./IERC721Mintable.sol";
import { IERC721Metadata } from "./IERC721Metadata.sol";

import { OperatorApproval } from "../../codegen/tables/OperatorApproval.sol";
import { Owners } from "../../codegen/tables/Owners.sol";
import { TokenApproval } from "../../codegen/tables/TokenApproval.sol";
import { Balances } from "../../codegen/tables/Balances.sol";

import { Utils } from "./Utils.sol";

contract ERC721System is AccessModified, IERC721Mintable, IERC721Metadata, EveSystem, PuppetMaster {
  using WorldResourceIdInstance for ResourceId;
  using Utils for bytes14;
  using StaticDataUtils for bytes14;

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public virtual returns (uint256) {
    if (owner == address(0)) {
      revert ERC721InvalidOwner(address(0));
    }
    return Balances.get(_namespace().balancesTableId(), owner);
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public virtual returns (address) {
    return _requireOwned(tokenId);
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public virtual returns (string memory) {
    return StaticDataGlobalTable.getName(_systemId());
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public virtual returns (string memory) {
    return StaticDataGlobalTable.getSymbol(_systemId());
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public virtual returns (string memory) {
    _requireOwned(tokenId);

    string memory baseURI = _baseURI();
    string memory _tokenURI = StaticDataTable.getCid(tokenId);
    _tokenURI = bytes(_tokenURI).length > 0 ? _tokenURI : string(abi.encodePacked(tokenId));
    return bytes(baseURI).length > 0 ? string.concat(baseURI, _tokenURI) : _tokenURI;
  }

  /**
   * @dev bridge gap solution to make it possible to change the default Token CID
   */
  function setCid(uint256 tokenId, string memory cid) public onlyAdmin {
    world().call(
      STATIC_DATA_DEPLOYMENT_NAMESPACE.staticDataSystemId(),
      abi.encodeCall(IStaticDataSystem.setCid, (tokenId, cid))
    );
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`.
   */
  function _baseURI() internal virtual returns (string memory) {
    return StaticDataGlobalTable.getBaseURI(_namespace().erc721SystemId());
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual {
    _approve(to, tokenId, _msgSender(), true);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public virtual returns (address) {
    _requireOwned(tokenId);

    return _getApproved(tokenId);
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public virtual returns (bool) {
    return OperatorApproval.get(_namespace().operatorApprovalTableId(), owner, operator);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   * noAccess - currently SSUs, SmartTurrets, SmartGates, and SmartCharacters are soulbound
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual noAccess hookable(tokenId, _systemId()) {
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
    // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
    address previousOwner = _update(to, tokenId, _msgSender());
    if (previousOwner != from) {
      revert ERC721IncorrectOwner(from, tokenId, previousOwner);
    }
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
    transferFrom(from, to, tokenId);
    _checkOnERC721Received(from, to, tokenId, data);
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - caller must own the namespace
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function mint(
    address to,
    uint256 tokenId
  ) public virtual onlyAdmin hookable(uint256(ResourceId.unwrap(_systemId())), _systemId()) {
    _mint(to, tokenId);
  }

  /**
   * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
   *
   * Requirements:
   *
   * - caller must own the namespace
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeMint(
    address to,
    uint256 tokenId
  ) public onlyAdmin hookable(uint256(ResourceId.unwrap(_systemId())), _systemId()) {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-safeMint-address-uint256-}[`safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual onlyAdmin hookable(uint256(ResourceId.unwrap(_systemId())), _systemId()) {
    _safeMint(to, tokenId, data);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   * - caller must own the namespace
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function burn(uint256 tokenId) public onlyAdmin {
    _burn(tokenId);
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   *
   * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
   * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
   * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
   * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
   */
  function _ownerOf(uint256 tokenId) internal virtual returns (address) {
    return Owners.get(_namespace().ownersTableId(), tokenId);
  }

  /**
   * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
   */
  function _getApproved(uint256 tokenId) internal virtual returns (address) {
    return TokenApproval.get(_namespace().tokenApprovalTableId(), tokenId);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
   * particular (ignoring whether it is owned by `owner`).
   *
   * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
   * assumption.
   */
  function _isAuthorized(address owner, address spender, uint256 tokenId) internal virtual returns (bool) {
    return
      spender != address(0) &&
      (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
  }

  /**
   * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
   * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
   * the `spender` for the specific `tokenId`.
   *
   * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
   * assumption.
   */
  function _checkAuthorized(address owner, address spender, uint256 tokenId) internal virtual {
    if (!_isAuthorized(owner, spender, tokenId)) {
      if (owner == address(0)) {
        revert ERC721NonexistentToken(tokenId);
      } else {
        revert ERC721InsufficientApproval(spender, tokenId);
      }
    }
  }

  /**
   * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
   *
   * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
   * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
   *
   * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
   * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
   * remain consistent with one another.
   */
  function _increaseBalance(address account, uint128 value) internal virtual {
    ResourceId balanceTableId = _namespace().balancesTableId();
    unchecked {
      Balances.set(balanceTableId, account, Balances.get(balanceTableId, account) + value);
    }
  }

  /**
   * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
   * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
   *
   * The `auth` argument is optional. If the value passed is non 0, then this function will check that
   * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
   *
   * Emits a {Transfer} event.
   *
   * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
   */
  function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
    ResourceId balanceTableId = _namespace().balancesTableId();
    address from = _ownerOf(tokenId);

    // Perform (optional) operator check
    if (auth != address(0)) {
      _checkAuthorized(from, auth, tokenId);
    }

    // Execute the update
    if (from != address(0)) {
      // Clear approval. No need to re-authorize or emit the Approval event
      _approve(address(0), tokenId, address(0), false);

      unchecked {
        Balances.set(balanceTableId, from, Balances.get(balanceTableId, from) - 1);
      }
    }

    if (to != address(0)) {
      unchecked {
        Balances.set(balanceTableId, to, Balances.get(balanceTableId, to) + 1);
      }
    }

    Owners.set(_namespace().ownersTableId(), tokenId, to);

    // Emit Transfer event on puppet
    puppet().log(Transfer.selector, toTopic(from), toTopic(to), toTopic(tokenId), new bytes(0));

    return from;
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal {
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    address previousOwner = _update(to, tokenId, address(0));
    if (previousOwner != address(0)) {
      revert ERC721InvalidSender(address(0));
    }
  }

  /**
   * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
    _mint(to, tokenId);
    _checkOnERC721Received(address(0), to, tokenId, data);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal {
    address previousOwner = _update(address(0), tokenId, address(0));
    if (previousOwner == address(0)) {
      revert ERC721NonexistentToken(tokenId);
    }
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address from, address to, uint256 tokenId) internal {
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    address previousOwner = _update(to, tokenId, address(0));
    if (previousOwner == address(0)) {
      revert ERC721NonexistentToken(tokenId);
    } else if (previousOwner != from) {
      revert ERC721IncorrectOwner(from, tokenId, previousOwner);
    }
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
   * are aware of the ERC721 standard to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is like {safeTransferFrom} in the sense that it invokes
   * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `tokenId` token must exist and be owned by `from`.
   * - `to` cannot be the zero address.
   * - `from` cannot be the zero address.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(address from, address to, uint256 tokenId) internal {
    _safeTransfer(from, to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
    _transfer(from, to, tokenId);
    _checkOnERC721Received(from, to, tokenId, data);
  }

  /**
   * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
   * emitted in the context of transfers.
   */
  function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
    // Avoid reading the owner unless necessary
    if (emitEvent || auth != address(0)) {
      address owner = _requireOwned(tokenId);

      // We do not use _isAuthorized because single-token approvals should not be able to call approve
      if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
        revert ERC721InvalidApprover(auth);
      }

      if (emitEvent) {
        // Emit Approval event on puppet
        puppet().log(Approval.selector, toTopic(owner), toTopic(to), toTopic(tokenId), new bytes(0));
      }
    }

    TokenApproval.set(_namespace().tokenApprovalTableId(), tokenId, to);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Requirements:
   * - operator can't be the address zero.
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    if (operator == address(0)) {
      revert ERC721InvalidOperator(operator);
    }
    OperatorApproval.set(_namespace().operatorApprovalTableId(), owner, operator, approved);

    // Emit ApprovalForAll event on puppet
    puppet().log(ApprovalForAll.selector, toTopic(owner), toTopic(operator), abi.encode(approved));
  }

  /**
   * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
   * Returns the owner.
   *
   * Overrides to ownership logic should be done to {_ownerOf}.
   */
  function _requireOwned(uint256 tokenId) internal returns (address) {
    address owner = _ownerOf(tokenId);
    if (owner == address(0)) {
      revert ERC721NonexistentToken(tokenId);
    }
    return owner;
  }

  /**
   * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
   * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   */
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
    if (to.code.length > 0) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
        if (retval != IERC721Receiver.onERC721Received.selector) {
          revert ERC721InvalidReceiver(to);
        }
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert ERC721InvalidReceiver(to);
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  function _systemId() internal returns (ResourceId) {
    return _namespace().erc721SystemId();
  }
}
