from types import POINTS
from types import LEVELS
from types import POINT
from types import Deed
from types import Point
from hash import hash3
from hash import hash5
from rights import get_deed
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.merkle_update import merkle_update
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import SignatureBuiltin
from starkware.cairo.common.signature import verify_ecdsa_signature

# Canoncial point hash
func hash_point(hash_ptr : HashBuiltin*, point : Point*) -> (
    point_hash, hash_ptr : HashBuiltin*):
  hash5(hash_ptr, POINT, point.encryption_key, point.authentication_key,
        point.life, point.rift, point.sponsor)
  return (...)
end

# Canonical update_point tx hash
func hash_update_point(
    hash_ptr : HashBuiltin*, ship, old_hash, new_hash) -> (
    message, hash_ptr : HashBuiltin*):
  hash3(hash_ptr, POINTS, ship, old_hash, new_hash)
  return (...)
end

# Get point associated with `ship` in `points`
#
# Hint arguments:
# points - tree of points
#
func get_point(hash_ptr : HashBuiltin*, points, ship) -> (
    point : Point*, point_hash, hash_ptr : HashBuiltin*):
  alloc_locals
  local point : Point
  %{
    point = az.get_value(points,ids.ship)
    ids.point.encryption_key     = point.encryption_key
    ids.point.authentication_key = point.authentication_key
    ids.point.life               = point.life
    ids.point.rift               = point.rift
    ids.point.sponsor            = point.sponsor
  %}

  let (__fp__, pc) = get_fp_and_pc()
  let (local point_hash, hash_ptr) = hash_point(hash_ptr, &point)

  # assert it's the correct public key by providing merkle proof that
  # that the point is at `ship` in `points`
  %{ auth_path = az.get_path(points,ids.ship) %}
  let (old_points, new_points, hash_ptr) = merkle_update(
    cast(hash_ptr,felt), LEVELS, point_hash, point_hash, ship)
  assert old_points = new_points
  assert new_points = points

  let (__fp__, pc) = get_fp_and_pc()
  return (&point, point_hash, cast(hash_ptr, HashBuiltin*))
end

# Update point
#
# Hint arguments:
# rights - tree of deeds
# points - tree of points
#
func update_point(
    hash_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*,
    rights, points, ship, new_point : Point*, sig_r, sig_s) -> (
    prev_points_root, new_points_root,
    hash_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*):
  alloc_locals

  # fetch deed and point
  let (local deed : Deed*, deed_hash, hash_ptr) = get_deed(
    hash_ptr, rights, ship)
  let (local old_point : Point*, old_hash, hash_ptr) = get_point(
    hash_ptr, points, ship)

  # verify owner signed transaction
  let (local new_hash, hash_ptr) = hash_point(hash_ptr, new_point)
  let (local message, hash_ptr) = hash_update_point(
    hash_ptr, ship, old_hash, new_hash)
  let (local ecdsa_ptr : SignatureBuiltin*) = verify_ecdsa_signature(
    ecdsa_ptr, message, deed.owner, sig_r, sig_s)

  # insert point
  %{ auth_path = az.get_path(points,ids.ship) %}
  let (old_points, new_points, hash_ptr) = merkle_update(
    cast(hash_ptr,felt), LEVELS, old_hash, new_hash, ship)
  return (old_points, new_points, cast(hash_ptr, HashBuiltin*), ecdsa_ptr)
end
