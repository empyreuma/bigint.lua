#!/usr/bin/env lua
local bigint = require("bigint")
local bigint_extra = {}

local zero = bigint.new(0)
local one = bigint.new(1)
local three = bigint.new(3)
local four = bigint.new(4)

-- Implementation of the Blum Blum Shub PRNG
local p = bigint.new(15487151)
local q = bigint.new(29731279)
assert(bigint.compare(bigint.modulus(p, four), three, "=="), "p mod 4 != 3")
assert(bigint.compare(bigint.modulus(q, four), three, "=="), "q mod 4 != 3")
local m = bigint.multiply(p, q)
local x = bigint.multiply(bigint.new(os.time()), bigint.new(1000)) -- the seed

-- BACKEND: Completely functional but requires two arguments
function bigint_extra.random_raw(low, high)
    -- Type checking done by bigint.compare
    local range, result

    assert(bigint.compare(low, high, "<"), bigint.unserialize(low)
                                            .. " is not less than "
                                            .. bigint.unserialize(high))
    range = bigint.add(bigint.subtract(high, low), one)

    x = bigint.modulus(bigint.multiply(x, x), m)

    return bigint.add(bigint.divide(bigint.multiply(x, range), m), low)
end

-- FRONTEND: Fill in missing arguments
function bigint_extra.random(low, high)
    if (low and high) then -- Output between low and high
        if (bigint.compare(low, high, "==")) then
            return low:clone()
        else
            return bigint_extra.random_raw(low, high)
        end
    elseif (low) then -- Output between one and low
        return bigint_extra.random_raw(one, low)
    else -- Output one or zero
        return bigint_extra.random(zero, one)
    end
end

bigint_extra.random(); bigint_extra.random(); bigint_extra.random() -- Initialize PRNG
return bigint_extra
