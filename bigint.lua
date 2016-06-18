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
    if num then
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

-- Convert a big to a number or string
function bigint.unserialize(big, return_string)
    bigint.check(big)
    local num = ""
    if big.sign == "-" then
        num = "-"
    end
    for _, digit in pairs(big.digits) do
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

    local greater = false -- If big1.digits > big2.digits
    local equal = false

    if (#big1.digits > #big2.digits) or ((big1.sign == "+") and (big2.sign == "-")) then
        greater = true
    elseif (big1.sign == "-") and (big2.sign == "+") then
        greater = false
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

        -- If both numbers are negative, then the requirements for greater are
        -- reversed
        if (not equal) and (big1.sign == "-") and (big2.sign == "-") then
            greater = not greater
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
    assert(bigint.compare(big1, big2, ">"),
           bigint.unserialize(big1, true) .. " is less than "
           .. bigint.unserialize(big2, true))

    local result = big1
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

    return result
end

return bigint
