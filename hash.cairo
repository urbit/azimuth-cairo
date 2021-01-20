from starkware.cairo.common.cairo_builtins import HashBuiltin

# Hash a message with two words
func hash2(hash_ptr : HashBuiltin*, tag, one, two) -> (
    message, hash_ptr : HashBuiltin*):
  alloc_locals

  assert hash_ptr.x = tag
  assert hash_ptr.y = one
  let one_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  assert hash_ptr.x = one_hash
  assert hash_ptr.y = two
  let two_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  return (two_hash, hash_ptr)
end

# Hash a message with three words
func hash3(hash_ptr : HashBuiltin*, tag, one, two, tri) -> (
    message, hash_ptr : HashBuiltin*):
  alloc_locals

  assert hash_ptr.x = tag
  assert hash_ptr.y = one
  let one_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  assert hash_ptr.x = one_hash
  assert hash_ptr.y = two
  let two_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  assert hash_ptr.x = two_hash
  assert hash_ptr.y = tri
  let tri_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  return (tri_hash, hash_ptr)
end

# Hash a message with five words
func hash5(hash_ptr : HashBuiltin*, tag, one, two, tri, for, fyv) -> (
    message, hash_ptr : HashBuiltin*):
  alloc_locals

  assert hash_ptr.x = tag
  assert hash_ptr.y = one
  let one_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  assert hash_ptr.x = one_hash
  assert hash_ptr.y = two
  let two_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  assert hash_ptr.x = two_hash
  assert hash_ptr.y = tri
  let tri_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  assert hash_ptr.x = tri_hash
  assert hash_ptr.y = for
  let for_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  assert hash_ptr.x = for_hash
  assert hash_ptr.y = fyv
  let fyv_hash = hash_ptr.result
  let hash_ptr = hash_ptr + HashBuiltin.SIZE

  return (fyv_hash, hash_ptr)
end
