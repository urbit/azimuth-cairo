import sys
import json
import collections
import functools
from starkware.cairo.lang.vm.crypto import pedersen_hash
import starkware.crypto.signature as signature

LEVELS = 16
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481

POINTS = 0
RIGHTS = 1
POINT  = 2
DEED   = 3

Point = collections.namedtuple('point',[
  'encryption_key',
  'authentication_key',
  'life',
  'rift',
  'sponsor'])

Deed = collections.namedtuple('deed',[
  'owner',
  'manager',
  'spawner',
  'voter',
  'transfer'])

Tree = collections.namedtuple('tree',['left','rite'])

priv_key = 2641752209470687828810961086602029945093408962677445227017106029765310864002
pub_key = signature.private_to_stark_key(priv_key)

@functools.lru_cache(None)
def hash_point(point):
  return  pedersen_hash(
            pedersen_hash(
              pedersen_hash(
                pedersen_hash(
                  pedersen_hash(
                    POINT,
                    point.encryption_key),
                  point.authentication_key),
                point.life),
              point.rift),
            point.sponsor)

@functools.lru_cache(None)
def hash_deed(deed):
  return  pedersen_hash(
            pedersen_hash(
              pedersen_hash(
                pedersen_hash(
                  pedersen_hash(
                    DEED,
                    deed.owner),
                  deed.manager),
                deed.spawner),
              deed.voter),
            deed.transfer)

@functools.lru_cache(None)
def hash_tree(tree):
  if type(tree).__name__ == 'point':
    return hash_point(tree)
  if type(tree).__name__ == 'deed':
    return hash_deed(tree)
  if type(tree).__name__ == 'tree':
    return pedersen_hash(hash_tree(tree.left),hash_tree(tree.rite))
  raise "bad tree"

@functools.lru_cache(None)
def init_points(level=0):
  if level == LEVELS:
    return Point(0,0,0,0,0)
  return Tree(init_points(level+1),init_points(level+1))

@functools.lru_cache(None)
def init_rights(level=0):
  if level == LEVELS:
    return Deed(pub_key,0,0,0,0)
  return Tree(init_rights(level+1),init_rights(level+1))

def reverse_bits(index):
  xedni = 0
  for i in range(LEVELS):
    xedni = (xedni << 1) | index & 1
    index >>= 1
  return xedni

def update_tree(tree,index,point):
  def loop(tree,xedni):
    if type(tree).__name__ != 'tree':
      assert xedni == 0
      return point
    if xedni % 2 == 0:
      return Tree(loop(tree.left,xedni // 2),tree.rite)
    else:
      return Tree(tree.left,loop(tree.rite,xedni // 2))
  return loop(tree,reverse_bits(index))

def get_path(tree,index):
  if type(tree).__name__ != 'tree':
    assert index == 0
    return []
  if index % 2 == 0:
    return [hash_tree(tree.rite)] + get_path(tree.left,index // 2)
  else:
    return [hash_tree(tree.left)] + get_path(tree.rite,index // 2)

def get_value(tree,index):
  xedni = reverse_bits(index)
  while type(tree).__name__ == 'tree':
    if xedni % 2 == 0:
      tree = tree.left
      xedni //= 2
    else:
      tree = tree.rite
      xedni //= 2
  assert xedni == 0
  return tree

def polarize(prime,num):
  if num < prime // 2:
    return num
  else:
    return -1 * (prime - num)

def sign_points_tx(sk,points,ship,point):
  message = \
    pedersen_hash(
      pedersen_hash(
        pedersen_hash(
          POINTS,
          ship),
        hash_point(get_value(points,ship))),
      hash_point(point))
  sig = signature.sign(message,sk)
  print(json.dumps({
      "function": POINTS,
      "ship": ship,
      "encryption_key": point.encryption_key,
      "authentication_key": point.authentication_key,
      "life": point.life,
      "rift": point.rift,
      "sponsor": point.sponsor,
      "sig_r": sig[0],
      "sig_s": sig[1]},
    indent=2))

def sign_rights_tx(sk,rights,ship,deed):
  message = \
    pedersen_hash(
      pedersen_hash(
        pedersen_hash(
          RIGHTS,
          ship),
        hash_deed(get_value(rights,ship))),
      hash_deed(deed))
  sig = signature.sign(message,sk)
  print(json.dumps({
      "function": RIGHTS,
      "ship": ship,
      "owner": deed.owner,
      "manager": deed.manager,
      "spawner": deed.spawner,
      "voter": deed.voter,
      "transfer": deed.transfer,
      "sig_r": sig[0],
      "sig_s": sig[1]},
    indent=2))

def main():
  ship = int(sys.argv[1])
  points = init_points()
  rights = init_rights()

  point = Point(13337,73331,1,0,0)
  deed = Deed(1,2,3,4,5)

  # sign_points_tx(priv_key,points,ship,point)
  sign_rights_tx(priv_key,rights,ship,deed)

if __name__ == "__main__":
  main()
