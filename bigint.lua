#!/usr/bin/env lua
-- If this variable is true, then strict type checking is performed for all
-- operations. This may result in slower code, but it will allow you to catch
-- errors and bugs earlier.
local strict = true

-------------------------------------------------------------------------------

bigint = {}

-- Create a new bigint or convert a number or string into a big
-- Returns an empty, positive bigint if no number or string is given
function bigint.new(num)
    local self = {
        sign = "+",
        digits = {}
    }
    if (num) then
        local num_string = tostring(num)
        for digit in string.gmatch(num_string, "[0-9]") do
            table.insert(self.digits, tonumber(digit))
        end
        if string.sub(num_string, 1, 1) == "-" then
            self.sign = "-"
        end
    end
    return self
end

-- Check the type of a big
-- Normally only runs when global variable "strict" == true, but checking can be
-- forced by supplying "true" as the second argument.
function bigint.check(big, force)
    if (strict or force) then
        assert(#big.digits > 0, "bigint is empty")
        assert(type(big.sign) == "string", "bigint is unsigned")
        for _, digit in pairs(big.digits) do
            assert(type(digit) == "number", digit .. " is not a number")
            assert(digit < 10, digit .. " is greater than or equal to 10")
        end
    end
    return true
end

-- Create a new big with the same digits but with a positive sign (absolute
-- value)
function bigint.abs(big)
    bigint.check(big)
    local result = bigint.new()
    result.digits = big.digits
    return result
end

-- Convert a big to a number or string
function bigint.unserialize(big, as_string)
    bigint.check(big)
    local num = ""
    if big.sign == "-" then
        num = "-"
    end
    for _, digit in pairs(big.digits) do
        num = num .. math.floor(digit) -- lazy way of getting rid of .0$
    end
    if as_string then
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

    local greater = false -- If big1.digits > big2.digits
    local equal = false

    if (big1.sign == "-") and (big2.sign == "+") then
        greater = false
    elseif (#big1.digits > #big2.digits)
    or ((big1.sign == "+") and (big2.sign == "-")) then
        greater = true
    elseif (#big1.digits == #big2.digits) then
        -- Walk left to right, comparing digits
        for digit = 1, #big1.digits do
            if (big1.digits[digit] > big2.digits[digit]) then
                greater = true
                break
            elseif (big2.digits[digit] > big1.digits[digit]) then
                break
            elseif (digit == #big1.digits)
                   and (big1.digits[digit] == big2.digits[digit]) then
                equal = true
            end
        end

    end

    -- If both numbers are negative, then the requirements for greater are
    -- reversed
    if (not equal) and (big1.sign == "-") and (big2.sign == "-") then
        greater = not greater
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

-- BACKEND: Add big1 and big2, ignoring signs
function bigint.add_raw(big1, big2)
    bigint.check(big1)
    bigint.check(big2)

    local max_digits = 0
    local result = bigint.new()
    local carry = 0

    if (#big1.digits >= #big2.digits) then
        max_digits = #big1.digits
    else
        max_digits = #big2.digits
    end

    -- Walk backwards right to left, like in long addition
    for digit = 0, max_digits - 1 do
        local sum = (big1.digits[#big1.digits - digit] or 0)
                  + (big2.digits[#big2.digits - digit] or 0)
                  + carry

        if (sum >= 10) then
            carry = 1
            sum = sum - 10
        else
            carry = 0
        end

        result.digits[max_digits - digit] = sum
    end

    -- Leftover carry in cases when #big1.digits == #big2.digits and sum > 10, ex. 7 + 9
    if carry == 1 then
        table.insert(result.digits, 1, 1)
    end

    return result

end

-- BACKEND: Subtract big2 from big1, ignoring signs
function bigint.subtract_raw(big1, big2)
    -- Type checking is done by bigint.compare
    assert(bigint.compare(bigint.abs(big1), bigint.abs(big2), ">="),
           "Size of " .. bigint.unserialize(big1, true) .. " is less than "
           .. bigint.unserialize(big2, true))

    local result = bigint.new()
    result.digits = big1.digits
    local max_digits = #big1.digits
    local borrow = 0

    -- Logic mostly copied from bigint.add_raw --------------------------------
    -- Walk backwards right to left, like in long subtraction
    for digit = 0, max_digits - 1 do
        local diff = (big1.digits[#big1.digits - digit] or 0)
                   - (big2.digits[#big2.digits - digit] or 0)
                   - borrow

        if (diff < 0) then
            borrow = 1
            diff = diff + 10
        else
            borrow = 0
        end

        result.digits[max_digits - digit] = diff
    end
    ---------------------------------------------------------------------------


    -- Strip leading zero if any, but not if 0 is the only digit
    if (#result.digits > 1) and (result.digits[1] == 0) then
        table.remove(result.digits, 1)
    end

    return result
end

-- FRONTEND: Addition and subtraction operations, accounting for signs
function bigint.add(big1, big2)
    -- Type checking is done by bigint.compare

    local result

    -- If adding numbers of different sign, subtract the smaller sized one from
    -- the bigger sized one and take the sign of the bigger sized one
    if (big1.sign ~= big2.sign) then
        if (bigint.compare(bigint.abs(big1), bigint.abs(big2), ">")) then
            result = bigint.subtract_raw(big1, big2)
            result.sign = big1.sign
        else
            result = bigint.subtract_raw(big2, big1)
            result.sign = big2.sign
        end

    elseif (big1.sign == "+") and (big2.sign == "+") then
        result = bigint.add_raw(big1, big2)

    elseif (big1.sign == "-") and (big2.sign == "-") then
        result = bigint.add_raw(big1, big2)
        result.sign = "-"
    end

    return result
end
function bigint.subtract(big1, big2)
    -- Type checking is done by bigint.compare in bigint.add
    -- Subtracting is like adding a negative
    local big2_local = bigint.new()
    big2_local.digits = big2.digits
    if (big2.sign == "+") then
        big2_local.sign = "-"
    else
        big2_local.sign = "+"
    end
    return bigint.add(big1, big2_local)
end

-- VERY BUGGY!!!! FOR TESTING PURPOSES ONLY!!! A BETTER GENERATOR TO COME SOON!!
-- Generate a random bigint using lua's math.random() random number generator
-- big2 is optional, just like with math.random()
function bigint.random(big1, big2)
    if (big2) then
        -- Type checking is done by bigint.compare
        assert(bigint.compare(big1, big2, "<"),
               bigint.unserialize(big1) .. " is greater than or equal to " ..
               bigint.unserialize(big2))

        local result = bigint.new()
        local range

        -- Find the difference between big1 and big2
        -- Sign can be ignored for now since we are only operating on digits
        if (big1.sign == "-") and (big2.sign == "-") then
            range = bigint.subtract(big1, big2)
        else
            range = bigint.subtract(big2, big1)
        end

        -- Generate a random bigint between 0 and the range
        for digit = 1, #range.digits do
            local max = range.digits[digit]
            if (max == 0) then
                max = 9
            end
            result.digits[digit] = math.random(0, max)
        end

        -- Strip leading zero if any, but not if 0 is the only digit
        if (#result.digits > 1) and (result.digits[1] == 0) then
            table.remove(result.digits, 1)
        end

        -- Bring the result back between big1 and big2
        result = bigint.add(result, big1)
        if (big1.sign == "-") and (big2.sign == "-") then
            result = bigint.add(result, big2)
        end

        return result
    else
        return bigint.random(bigint.new(1), big1)
    end
end

return bigint
