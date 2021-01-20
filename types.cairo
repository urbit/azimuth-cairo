const LEVELS = 16

# Types of hashes
const POINTS = 0
const RIGHTS = 1
const POINT  = 2
const DEED   = 3

struct Point:
  member encryption_key = 0
  member authentication_key = 1
  member life = 2
  member rift = 3
  member sponsor = 4
  const SIZE = 5
end

struct Deed:
  member owner = 0
  member manager = 1
  member spawner = 2
  member voter = 3
  member transfer = 4
  const SIZE = 5
end
