#!/usr/bin/env lua
--[[

This code is released under the 3-Clause BSD License.

bignum.lua is a library that attempts to remove the restrictions on number size
built into vanilla Lua. In order to achieve this, all numbers using operations
that this library provides must first be passed through the serialize(num)
function, which converts the number into a table in which every index is a
single digit:

  serialize(132) -> [ 1.0, 3.0, 2.0 ]

To simplify the documentation, serialized strings will, from here on out, be
referred to as being of the imaginary type "big".

Strings can also be passed into this function bigint.if the number to be serialized is
already too big to exist in lua (inf):

  serialize("132") -> [ 1.0, 3.0, 2.0 ]

To convert a big back into a number, use the unserialize() function:

  big = serialize("5880")
  unserialize(big) -> 5880

Supported operations:
  check - Check if a variable's "type" is big - can be used internally on all
    operations if the "strict" variable below is set to true
  serialize
  unserialize
  compare
  add

Planned operations:
  random
  subtract
  multiply
  power
  divide
  modulus

For more detailed documentation, scroll down. The operations appear in the order
that they are listed above.

--]]

-- If this variable is true then strict type checking is performed for all
-- operations. This may result in slower code, but it will allow you to catch
-- errors and bugs earlier.
local strict = true

--[[

Copyright (c) Emily "empyreuma" 2016
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--]]

local bigint = {}

-- Create a new big
function bigint.new()
    return {}
end

-- Check the type of a big
-- Normally only runs when global variable "strict" == true, but checking can be
-- forced by supplying "true" as the second argument.
function bigint.check(big, force)
    if (strict or force) then
        for _, digit in pairs(big) do
            assert(type(digit) == "number", digit .. " is not a number")
            assert(digit < 10, digit .. " is greater than or equal to 10")
        end
    end
    return true
end

-- Convert a number or string into a big
function bigint.serialize(num)
    local big = bigint.new()
    for digit in string.gmatch(tostring(num), ".") do
        table.insert(big, tonumber(digit))
    end
    return big
end

-- Convert a big to a number or string
function bigint.unserialize(big, return_string)
    bigint.check(big)
    local num = ""
    for _, digit in pairs(big) do
        num = num .. math.floor(digit) -- lazy way of getting rid of .0$
    end
    if return_string then
        return num
    else
        return tonumber(num)
    end
end

-- Basic comparisons
-- Accepts symbols (<, >=, ~=) and Unix shell-like options (lt, ge, ne)
function bigint.compare(big1, big2, comparison)
    bigint.check(big1)
    bigint.check(big2)

    local greater = false -- If big1 > big2
    local equal = false

    if (#big1 > #big2) then
        greater = true
    elseif (#big1 == #big2) then
        -- Walk left to right, comparing digits
        for digit = 1, #big1 do
            if (big1[digit] > big2[digit]) then
                greater = true
                break
            elseif (big2[digit] > big1[digit]) then
                break
            elseif (digit == #big1) and (big1[digit] == big2[digit]) then
                equal = true
            end
        end
    end

    return (((comparison == "<") or (comparison == "lt"))
            and (not greater) and true)
        or (((comparison == ">") or (comparison == "gt"))
            and (greater) and true)
        or (((comparison == "==") or (comparison == "eq"))
            and (equal) and true)
        or (((comparison == ">=") or (comparison == "ge"))
            and (equal or greater) and true)
        or (((comparison == "<=") or (comparison == "le"))
            and (equal or not greater) and true)
        or (((comparison == "~=") or (comparison == "!=") or (comparison == "ne"))
            and (not equal) and true)
        or false
end

-- Add two bigs and return a big
function bigint.add(big1, big2)
    bigint.check(big1)
    bigint.check(big2)

    local max_digits = 0
    local result = {}
    local carry = 0

    if (#big1 >= #big2) then
        max_digits = #big1
    else
        max_digits = #big2
    end

    -- Walk backwards right to left, like in long addition
    for digit = 0, max_digits - 1 do
        local sum = (big1[#big1 - digit] or 0)
                  + (big2[#big2 - digit] or 0)
                  + carry

        if (sum >= 10) then
            carry = 1
            sum = sum - 10
        else
            carry = 0
        end

        result[max_digits - digit] = sum
    end

    -- Leftover carry in cases when #big1 == #big2 and sum > 10, ex. 7 + 9
    if carry == 1 then
        table.insert(result, 1, 1)
    end

    return result

end

return bigint
