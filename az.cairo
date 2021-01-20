# Super minimal implementation of some of Azimuth's functionality
#
# Eventually the idea is to duplicate most of the functionality here:
#
# https://github.com/urbit/azimuth/blob/master/contracts/Azimuth.sol

%builtins output pedersen ecdsa

from types import POINTS
from types import RIGHTS
from types import LEVELS
from types import Deed
from types import Point
from points import update_point
from rights import update_deed
from starkware.cairo.common.merkle_update import merkle_update
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import SignatureBuiltin
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.signature import verify_ecdsa_signature

struct AzOutput:
  member points_root_old = 0
  member points_root_new = 1
  member rights_root_old = 2
  member rights_root_new = 3
  const SIZE = 4
end

func run_points(
    output_ptr : felt*, hash_ptr : HashBuiltin*,
    ecdsa_ptr : SignatureBuiltin*, rights, points) -> (
    output_ptr : felt*, pedersen_ptr : HashBuiltin*,
    ecdsa_ptr : SignatureBuiltin*):
  alloc_locals

  local ship
  local new_point : Point
  local sig_r
  local sig_s
  %{
    ids.ship                         = program_input['ship']
    ids.sig_r                        = program_input['sig_r']
    ids.sig_s                        = program_input['sig_s']
    ids.new_point.encryption_key     = program_input['encryption_key']
    ids.new_point.authentication_key = program_input['authentication_key']
    ids.new_point.life               = program_input['life']
    ids.new_point.rift               = program_input['rift']
    ids.new_point.sponsor            = program_input['sponsor']
  %}
  let (__fp__, pc) = get_fp_and_pc()
  let (prev_points, new_points, hash_ptr, ecdsa_ptr) = update_point(
    hash_ptr, ecdsa_ptr, rights, points, ship, &new_point, sig_r, sig_s)
  assert points = prev_points
  let output = cast(output_ptr,AzOutput*)
  assert output.points_root_new = new_points
  assert output.rights_root_new = rights

  return (output_ptr + AzOutput.SIZE, hash_ptr, ecdsa_ptr)
end

func run_rights(
    output_ptr : felt*, hash_ptr : HashBuiltin*,
    ecdsa_ptr : SignatureBuiltin*, rights, points) -> (
    output_ptr : felt*, pedersen_ptr : HashBuiltin*,
    ecdsa_ptr : SignatureBuiltin*):
  alloc_locals

  local ship
  local new_deed : Deed
  local sig_r
  local sig_s
  %{
    ids.ship              = program_input['ship']
    ids.sig_r             = program_input['sig_r']
    ids.sig_s             = program_input['sig_s']
    ids.new_deed.owner    = program_input['owner']
    ids.new_deed.manager  = program_input['manager']
    ids.new_deed.spawner  = program_input['spawner']
    ids.new_deed.voter    = program_input['voter']
    ids.new_deed.transfer = program_input['transfer']
  %}

  let (__fp__, pc) = get_fp_and_pc()
  let (prev_rights, new_rights, hash_ptr, ecdsa_ptr) = update_deed(
    hash_ptr, ecdsa_ptr, rights, ship, &new_deed, sig_r, sig_s)

  assert rights = prev_rights
  let output = cast(output_ptr,AzOutput*)
  assert output.points_root_new = points
  assert output.rights_root_new = new_rights

  return (output_ptr + AzOutput.SIZE, hash_ptr, ecdsa_ptr)
end

func main(
    output_ptr : felt*, pedersen_ptr : HashBuiltin*,
    ecdsa_ptr : SignatureBuiltin*) -> (
    output_ptr : felt*, pedersen_ptr : HashBuiltin*,
    ecdsa_ptr : SignatureBuiltin*):

  alloc_locals

  let hash_ptr = pedersen_ptr
  let output = cast(output_ptr,AzOutput*)

  local rights
  local points
  local function
  %{
    import az
    points = az.init_points()
    rights = az.init_rights()
    ids.points = az.hash_tree(points)
    ids.rights = az.hash_tree(rights)
    ids.function = program_input['function']
  %}

  assert output.points_root_old = points
  assert output.rights_root_old = rights

  if function == POINTS:
    run_points(output_ptr, hash_ptr, ecdsa_ptr, rights, points)
    return (...)
  end

  if function == RIGHTS:
    run_rights(output_ptr, hash_ptr, ecdsa_ptr, rights, points)
    return (...)
  end

  assert 0 = 1
  ret
end
