from types import RIGHTS
from types import LEVELS
from types import DEED
from types import Deed
from hash import hash3
from hash import hash5
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.merkle_update import merkle_update
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import SignatureBuiltin
from starkware.cairo.common.signature import verify_ecdsa_signature

# Canonical deed hash
func hash_deed(hash_ptr : HashBuiltin*, deed : Deed*) -> (
    deed_hash, hash_ptr : HashBuiltin*):
  hash5(hash_ptr, DEED, deed.owner, deed.manager,
        deed.spawner, deed.voter, deed.transfer)
  return (...)
end

# Canonical update_deed tx hash
func hash_update_deed(
    hash_ptr : HashBuiltin*, ship, old_hash, new_hash) -> (
    message, hash_ptr : HashBuiltin*):
  hash3(hash_ptr, RIGHTS, ship, old_hash, new_hash)
  return (...)
end

# Get deed associated with `ship` in `rights`
#
# Hint arguments:
# rights - tree of deeds
#
func get_deed(hash_ptr : HashBuiltin*, rights, ship) -> (
    deed : Deed*, deed_hash, hash_ptr : HashBuiltin*):
  alloc_locals
  local deed : Deed
  %{
    deed = az.get_value(rights,ids.ship)
    print("rights", az.hash_tree(rights))
    ids.deed.owner    = deed.owner
    ids.deed.manager  = deed.manager
    ids.deed.spawner  = deed.spawner
    ids.deed.voter    = deed.voter
    ids.deed.transfer = deed.transfer
  %}

  let (__fp__, pc) = get_fp_and_pc()
  let (local deed_hash, hash_ptr) = hash_deed(hash_ptr, &deed)

  # assert it's the correct public key by providing merkle proof that
  # that the deed is at `ship` in `rights`
  %{ auth_path = az.get_path(rights,ids.ship) %}
  let (old_rights, new_rights, hash_ptr) = merkle_update(
    cast(hash_ptr,felt), LEVELS, deed_hash, deed_hash, ship)
  assert old_rights = new_rights
  assert new_rights = rights

  let (__fp__, pc) = get_fp_and_pc()
  return (&deed, deed_hash, cast(hash_ptr, HashBuiltin*))
end

# Update deed to ship
#
# Hint arguments:
# rights - tree of deeds
#
func update_deed(
    hash_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*,
    rights, ship, new_deed : Deed*, sig_r, sig_s) -> (
    prev_rights_root, new_rights_root,
    hash_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*):
  alloc_locals

  # fetch deed
  let (local old_deed : Deed*, local old_hash, hash_ptr) = get_deed(
    hash_ptr, rights, ship)

  # verify owner signed transaction
  let (local new_hash, hash_ptr) = hash_deed(hash_ptr, new_deed)
  let (local message, hash_ptr) = hash_update_deed(
    hash_ptr, ship, old_hash, new_hash)
  let (local ecdsa_ptr : SignatureBuiltin*) = verify_ecdsa_signature(
    ecdsa_ptr, message, old_deed.owner, sig_r, sig_s)

  # insert new deed into rights
  %{ auth_path = az.get_path(rights,ids.ship) %}
  let (old_rights, new_rights, hash_ptr) = merkle_update(
    cast(hash_ptr,felt), LEVELS, old_hash, new_hash, ship)
  assert old_rights = rights
  return (old_rights, new_rights, cast(hash_ptr, HashBuiltin*), ecdsa_ptr)
end
