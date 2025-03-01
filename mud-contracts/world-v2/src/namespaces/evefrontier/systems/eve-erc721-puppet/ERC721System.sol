// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { PuppetMaster } from "@latticexyz/world-modules/src/modules/puppet/PuppetMaster.sol";
import { toTopic } from "@latticexyz/world-modules/src/modules/puppet/utils.sol";

import { IERC721Mintable } from "./IERC721Mintable.sol";
import { IERC721Receiver } from "./IERC721Receiver.sol";

import { Balances } from "../../codegen/tables/Balances.sol";
import { ERC721Metadata } from "../../codegen/tables/ERC721Metadata.sol";
import { OperatorApproval } from "../../codegen/tables/OperatorApproval.sol";
import { Owners } from "../../codegen/tables/Owners.sol";
import { TokenApproval } from "../../codegen/tables/TokenApproval.sol";
import { TokenURI } from "../../codegen/tables/TokenURI.sol";

import { _balancesTableId, _metadataTableId, _tokenUriTableId, _operatorApprovalTableId, _ownersTableId, _tokenApprovalTableId } from "./utils.sol";
import { LibString } from "@latticexyz/world-modules/src/modules/erc721-puppet/libraries/LibString.sol";

import { StaticDataSystem } from "../static-data/StaticDataSystem.sol";
import { StaticData, StaticDataMetadata } from "../../codegen/index.sol";

contract ERC721System is IERC721Mintable, SmartObjectFramework, PuppetMaster {
  using WorldResourceIdInstance for ResourceId;
  using LibString for uint256;

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual returns (uint256) {
    if (owner == address(0)) {
      revert ERC721InvalidOwner(address(0));
    }
    return Balances.get(_balancesTableId(_namespace()), owner);
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    return _requireOwned(tokenId);
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual returns (string memory) {
    return ERC721Metadata.getName(_metadataTableId(_namespace()));
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual returns (string memory) {
    return ERC721Metadata.getSymbol(_metadataTableId(_namespace()));
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    _requireOwned(tokenId);

    string memory baseURI = _baseURI();
    string memory _tokenURI = StaticData.get(tokenId);
    _tokenURI = bytes(_tokenURI).length > 0 ? _tokenURI : tokenId.toString();
    return bytes(baseURI).length > 0 ? string.concat(baseURI, _tokenURI) : _tokenURI;
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return StaticDataMetadata.get();
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual {
    _approve(to, tokenId, _msgSender());
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual returns (address) {
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
  function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
    return OperatorApproval.get(_operatorApprovalTableId(_namespace()), owner, operator);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(address from, address to, uint256 tokenId) public virtual {
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
  function mint(address to, uint256 tokenId) public virtual context access(tokenId) {
    //_requireOwner(); TODO: This is messing stuff up with access control and how systems should be able to mint, e.g. Smart character
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
  function safeMint(address to, uint256 tokenId) public context access(tokenId) {
    _requireOwner();
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-safeMint-address-uint256-}[`safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function safeMint(address to, uint256 tokenId, bytes memory data) public virtual context access(tokenId) {
    _requireOwner();
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
  function burn(uint256 tokenId) public context access(tokenId) {
    _requireOwner();
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
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return Owners.get(_ownersTableId(_namespace()), tokenId);
  }

  /**
   * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
   */
  function _getApproved(uint256 tokenId) internal view virtual returns (address) {
    return TokenApproval.get(_tokenApprovalTableId(_namespace()), tokenId);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
   * particular (ignoring whether it is owned by `owner`).
   *
   * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
   * assumption.
   */
  function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
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
  function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
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
    ResourceId balanceTableId = _balancesTableId(_namespace());
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
    ResourceId balanceTableId = _balancesTableId(_namespace());
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

    Owners.set(_ownersTableId(_namespace()), tokenId, to);

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
   * @dev Approve `to` to operate on `tokenId`
   *
   * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
   * either the owner of the token, or approved to operate on all tokens held by this owner.
   *
   * Emits an {Approval} event.
   *
   * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
   */
  function _approve(address to, uint256 tokenId, address auth) internal {
    _approve(to, tokenId, auth, true);
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

    TokenApproval.set(_tokenApprovalTableId(_namespace()), tokenId, to);
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
    OperatorApproval.set(_operatorApprovalTableId(_namespace()), owner, operator, approved);

    // Emit ApprovalForAll event on puppet
    puppet().log(ApprovalForAll.selector, toTopic(owner), toTopic(operator), abi.encode(approved));
  }

  /**
   * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
   * Returns the owner.
   *
   * Overrides to ownership logic should be done to {_ownerOf}.
   */
  function _requireOwned(uint256 tokenId) internal view returns (address) {
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

  function _namespace() internal view returns (bytes14 namespace) {
    ResourceId systemId = SystemRegistry.get(address(this));
    return systemId.getNamespace();
  }

  function _requireOwner() internal view {
    AccessControl.requireOwner(SystemRegistry.get(address(this)), _msgSender());
  }
}
