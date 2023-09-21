#!/usr/bin/env lua
-- If this variable is true, then strict type checking is performed for all
-- operations. This may result in slower code, but it will allow you to catch
-- errors and bugs earlier.
local strict = true

--------------------------------------------------------------------------------

local bigint = {}

local named_powers = require("named-powers-of-ten")

-- Create a new bigint or convert a number or string into a big
-- Returns an empty, positive bigint if no number or string is given
function bigint.new(num)
    local self = {
        sign = "+",
        digits = {}
    }

    -- Return a new bigint with the same sign and digits
    function self:clone()
        local newint = bigint.new()
        newint.sign = self.sign
        for _, digit in pairs(self.digits) do
            newint.digits[#newint.digits + 1] = digit
        end
        return newint
    end

    setmetatable(self, {
        __add = function(lhs, rhs)
            return bigint.add(lhs, rhs)
        end,
        __unm = function()
            if (self.sign == "+") then
                self.sign = "-"
            else
                self.sign = "+"
            end
            return self
        end,
        __sub = function(lhs, rhs)
            return bigint.subtract(lhs, rhs)
        end,
        __mul = function(lhs, rhs)
            return bigint.multiply(lhs, rhs)
        end,
        __div = function(lhs, rhs)
            return bigint.divide(lhs, rhs)
        end,
        __mod = function(lhs, rhs)
            local result, remainder = bigint.divide(lhs, rhs)
            return result
        end,
        __pow = function(lhs, rhs)
            return bigint.exponentiate(lhs, rhs)
        end
    })

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

-- Return a new big with the same digits but with a positive sign (absolute
-- value)
function bigint.abs(big)
    bigint.check(big)
    local result = big:clone()
    result.sign = "+"
    return result
end

-- Convert a big to a number or string
function bigint.unserialize(big, output_type, precision)
    bigint.check(big)

    local num = ""
    if big.sign == "-" then
        num = "-"
    end


    if ((output_type == nil)
    or (output_type == "number")
    or (output_type == "n")
    or (output_type == "string")
    or (output_type == "s")) then
        -- Unserialization to a string or number requires reconstructing the
        -- entire number

        for _, digit in pairs(big.digits) do
            num = num .. math.floor(digit) -- lazy way of getting rid of .0$
        end

        if ((output_type == nil)
        or (output_type == "number")
        or (output_type == "n")) then
            return tonumber(num)
        else
            return num
        end

    else
        -- Unserialization to human-readable form or scientific notation only
        -- requires reading the first few digits
        if (precision == nil) then
            precision = 3
        else
            assert(precision > 0, "Precision cannot be less than 1")
            assert(math.floor(precision) == precision,
                   "Precision must be a positive integer")
        end

        -- num is the first (precision + 1) digits, the first being separated by
        -- a decimal point from the others
        num = num .. big.digits[1]
        if (precision > 1) then
            num = num .. "."
            for i = 1, (precision - 1) do
                num = num .. big.digits[i + 1]
            end
        end

        if ((output_type == "human-readable")
        or (output_type == "human")
        or (output_type == "h")) then
            -- Human-readable output contributed by 123eee555

            local name
            local walkback = 0 -- Used to enumerate "ten", "hundred", etc

            -- Walk backwards in the index of named_powers starting at the
            -- number of digits of the input until the first value is found
            for i = (#big.digits - 1), (#big.digits - 4), -1 do
                name = named_powers[i]
                if (name) then
                    if (walkback == 1) then
                        name = "ten " .. name
                    elseif (walkback == 2) then
                        name = "hundred " .. name
                    end
                    break
                else
                    walkback = walkback + 1
                end
            end

            return num .. " " .. name

        else
            return num .. "*10^" .. (#big.digits - 1)
        end

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
            and ((not greater) and (not equal)) and true)
        or (((comparison == ">") or (comparison == "gt"))
            and ((greater) and (not equal)) and true)
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

    local result = bigint.new()
    local max_digits = 0
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
    if (carry == 1) then
        table.insert(result.digits, 1, 1)
    end

    return result

end

-- BACKEND: Subtract big2 from big1, ignoring signs
function bigint.subtract_raw(big1, big2)
    -- Type checking is done by bigint.compare
    assert(bigint.compare(bigint.abs(big1), bigint.abs(big2), ">="),
           "Size of " .. bigint.unserialize(big1, "string") .. " is less than "
           .. bigint.unserialize(big2, "string"))

    local result = big1:clone()
    local max_digits = #big1.digits
    local borrow = 0

    -- Logic mostly copied from bigint.add_raw ---------------------------------
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
    ----------------------------------------------------------------------------


    -- Strip leading zeroes if any, but not if 0 is the only digit
    while (#result.digits > 1) and (result.digits[1] == 0) do
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
    local big2_local = big2:clone()
    if (big2.sign == "+") then
        big2_local.sign = "-"
    else
        big2_local.sign = "+"
    end
    return bigint.add(big1, big2_local)
end

-- BACKEND: Multiply a big by a single digit big, ignoring signs
function bigint.multiply_single(big1, big2)
    bigint.check(big1)
    bigint.check(big2)
    assert(#big2.digits == 1, bigint.unserialize(big2, "string")
                              .. " has more than one digit")

    local result = bigint.new()
    local carry = 0

    -- Logic mostly copied from bigint.add_raw ---------------------------------
    -- Walk backwards right to left, like in long multiplication
    for digit = 0, #big1.digits - 1 do
        local this_digit = big1.digits[#big1.digits - digit]
                         * big2.digits[1]
                         + carry

        if (this_digit >= 10) then
            carry = math.floor(this_digit / 10)
            this_digit = this_digit - (carry * 10)
        else
            carry = 0
        end

        result.digits[#big1.digits - digit] = this_digit
    end

    -- Leftover carry in cases when big1.digits[1] * big2.digits[1] > 0
    if (carry > 0) then
        table.insert(result.digits, 1, carry)
    end
    ----------------------------------------------------------------------------

    return result
end

-- FRONTEND: Multiply two bigs, accounting for signs
function bigint.multiply(big1, big2)
    -- Type checking done by bigint.multiply_single

    local result = bigint.new(0)
    local larger, smaller -- Larger and smaller in terms of digits, not size

    if (bigint.unserialize(big1) == 0) or (bigint.unserialize(big2) == 0) then
        return result
    end

    if (#big1.digits >= #big2.digits) then
        larger = big1
        smaller = big2
    else
        larger = big2
        smaller = big1
    end

    -- Walk backwards right to left, like in long multiplication
    for digit = 0, #smaller.digits - 1 do
        -- Sorry for going over column 80! There's lots of big names here
        local this_digit_product = bigint.multiply_single(larger,
                                                          bigint.new(smaller.digits[#smaller.digits - digit]))

        -- "Placeholding zeroes"
        if (digit > 0) then
            for placeholder = 1, digit do
                table.insert(this_digit_product.digits, 0)
            end
        end

        result = bigint.add(result, this_digit_product)
    end

    if (larger.sign == smaller.sign) then
        result.sign = "+"
    else
        result.sign = "-"
    end

    return result
end


-- Raise a big to a positive integer or big power (TODO: negative integer power)
function bigint.exponentiate(big, power)
    -- Type checking for big done by bigint.multiply
    assert(bigint.compare(power, bigint.new(0), ">"),
           " negative powers are not supported")
    local exp = power:clone()

    if (bigint.compare(exp, bigint.new(0), "==")) then
        return bigint.new(1)
    elseif (bigint.compare(exp, bigint.new(1), "==")) then
        return big
    else
        local result = big:clone()

        while (bigint.compare(exp, bigint.new(1), ">")) do
            result = bigint.multiply(result, big)
            exp = bigint.subtract(exp, bigint.new(1))
        end

        return result
    end

end

-- BACKEND: Divide two bigs (decimals not supported), returning big result and
-- big remainder
-- WARNING: Only supports positive integers
function bigint.divide_raw(big1, big2)
    -- Type checking done by bigint.compare
    if (bigint.compare(big1, big2, "==")) then
        return bigint.new(1), bigint.new(0)
    elseif (bigint.compare(big1, big2, "<")) then
        return bigint.new(0), big1:clone()
    else
        assert(bigint.compare(big2, bigint.new(0), "!="), "error: divide by zero")
        assert(big1.sign == "+", "error: big1 is not positive")
        assert(big2.sign == "+", "error: big2 is not positive")

        local result = bigint.new()

        local dividend = bigint.new() -- Dividend of a single operation, not the
                                      -- dividend of the overall function
        local divisor = big2:clone()
        local factor = 1

        -- Walk left to right among digits in the dividend, like in long
        -- division
        for _, digit in pairs(big1.digits) do
            dividend.digits[#dividend.digits + 1] = digit

            -- The dividend is smaller than the divisor, so a zero is appended
            -- to the result and the loop ends
            if (bigint.compare(dividend, divisor, "<")) then
                if (#result.digits > 0) then -- Don't add leading zeroes
                    result.digits[#result.digits + 1] = 0
                end
            else
                -- Find the maximum number of divisors that fit into the
                -- dividend
                factor = 0
                while (bigint.compare(divisor, dividend, "<=")) do
                    divisor = bigint.add(divisor, big2)
                    factor = factor + 1
                end

                -- Append the factor to the result
                if (factor == 10) then
                    -- Fixes a weird bug that introduces a new bug if fixed by
                    -- changing the comparison in the while loop to "<="
                    result.digits[#result.digits] = 1
                    result.digits[#result.digits + 1] = 0
                else
                    result.digits[#result.digits + 1] = factor
                end

                -- Subtract the divisor from the dividend to obtain the
                -- remainder, which is the new dividend for the next loop
                dividend = bigint.subtract(dividend,
                                           bigint.subtract(divisor, big2))

                -- Reset the divisor
                divisor = big2:clone()
            end

        end

        -- The remainder of the final loop is returned as the function's
        -- overall remainder
        return result, dividend
    end
end

-- FRONTEND: Divide two bigs (decimals not supported), returning big result and
-- big remainder, accounting for signs
function bigint.divide(big1, big2)
    local result, remainder = bigint.divide_raw(bigint.abs(big1),
                                                bigint.abs(big2))
    if (big1.sign == big2.sign) then
        result.sign = "+"
    else
        result.sign = "-"
    end

    return result, remainder
end

-- FRONTEND: Return only the remainder from bigint.divide
function bigint.modulus(big1, big2)
    local result, remainder = bigint.divide(big1, big2)

    -- Remainder will always have the same sign as the dividend per C standard
    -- https://en.wikipedia.org/wiki/Modulo_operation#Remainder_calculation_for_the_modulo_operation
    remainder.sign = big1.sign
    return remainder
end

return bigint
