#!/usr/bin/env lua
-- Sorry for how ugly this script is! It's not really meant to be maintained.

local bigint = require("bigint")
local bigint_extra = require("bigint-extra")
local comparisons = {">", "<", "==", "~=", ">=", "<="}

math.randomseed(os.time())

function printf(...)
    print(string.format(...))
end

function demo_serialize_unserialize(n)
    printf("bigint.unserialize(bigint.new(%s)) -> %s", tostring(n), tostring(bigint.unserialize(bigint.new(n), "string")))
end

function demo_compare(n1, n2, cmp)
    cmp = cmp or comparisons[math.random(#comparisons)]
    printf("bigint.compare(%s, %s, %s) -> %s", tostring(n1), tostring(n2), cmp, (bigint.compare(bigint.new(n1), bigint.new(n2), cmp) and "true" or "false"))
end

function demo_add(n1, n2)
    printf("bigint.add(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.add(bigint.new(n1), bigint.new(n2)), "string")))
end

function demo_subtract(n1, n2)
    printf("bigint.subtract(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.subtract(bigint.new(n1), bigint.new(n2)), "string")))
end

function demo_multiply(n1, n2)
    printf("bigint.multiply(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.multiply(bigint.new(n1), bigint.new(n2)), "string")))
end

function demo_exponentiate(n1, n2)
    printf("bigint.exponentiate(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.exponentiate(bigint.new(n1), bigint.new(n2)), "string")))
end

function demo_divide(n1, n2)
    local result, remainder = bigint.divide(bigint.new(n1), bigint.new(n2))
    printf("bigint.divide(%s, %s) -> %s R %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(result), "string"), tostring(bigint.unserialize(remainder), "string"))
end

function demo_random(n1, n2)
    if (n2) then
        printf("bigint.random(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint_extra.random(bigint.new(n1), bigint.new(n2)), "string")))
    else
        printf("bigint.random(%s) -> %s", tostring(n1), tostring(bigint.unserialize(bigint_extra.random(bigint.new(n1)), "string")))
    end
end

print("-- Serialize number")
demo_serialize_unserialize(math.random(100))
print("-- Serialize string")
demo_serialize_unserialize("-" .. tostring(math.random(100)))
print()

print("-- Random comparison of two positives")
demo_compare(math.random(100), math.random(100))
print("-- Random comparison of two negatives")
demo_compare(math.random(-100, 0), math.random(-100, 0))
print("-- Random comparison of a positive and a negative")
demo_compare(math.random(-100, 0), math.random(100))
print()

print("-- Add two positives")
demo_add(math.random(100), math.random(100))
print("-- Add two negatives")
demo_add(math.random(-100, 0), math.random(-100, 0))
print("-- Add a negative and a positive")
demo_add(math.random(-100, 0), math.random(100))
print()

print("-- Raise a positive to a power")
demo_exponentiate(math.random(100), math.random(100))
print("-- Raise a negative to a power")
demo_exponentiate(math.random(-100, 0), math.random(100))
print()

print("-- Subtract two positives")
demo_subtract(math.random(100), math.random(100))
print("-- Subtract two negatives")
demo_subtract(math.random(-100, 0), math.random(-100, 0))
print("-- Subtract a positive from a negative")
demo_subtract(math.random(-100, 0), math.random(100))
print("-- Subtract a negative from a positive")
demo_subtract(math.random(100), math.random(-100, 0))
print()

print("-- Multiply two positives")
demo_multiply(math.random(100), math.random(100))
print("-- Multiply two negatives")
demo_multiply(math.random(-100, 0), math.random(-100, 0))
print("-- Multiply a negative and a positive")
demo_multiply(math.random(-100, 0), math.random(100))
print("-- Multiply by zero")
demo_multiply(0, math.random(100))
print("-- Multiply two very large numbers: RSA-1536 * RSA-2048")
rsa_1536 = "1847699703211741474306835620200164403018549338663410171471785774910651696711161249859337684305435744585616061544571794052229717732524660960646946071249623720442022269756756687378427562389508764678440933285157496578843415088475528298186726451339863364931908084671990431874381283363502795470282653297802934916155811881049844908319545009848393775227257052578591944993870073695755688436933812779613089230392569695253261620823676490316036551371447913932347169566988069"
rsa_2048 = "25195908475657893494027183240048398571429282126204032027777137836043662020707595556264018525880784406918290641249515082189298559149176184502808489120072844992687392807287776735971418347270261896375014971824691165077613379859095700097330459748808428401797429100642458691817195118746121515172654632282216869987549182422433637259085141865462043576798423387184774447920739934236584823824281198163815010674810451660377306056201619676256133844143603833904414952634432190114657544454178424020924616515723350778707749817125772467962926386356373289912154831438167899885040445364023527381951378636564391212010397122822120720357"
rsa_mult = bigint.unserialize(bigint.multiply(bigint.new(rsa_1536), bigint.new(rsa_2048)), "string")
os.execute("echo -n 'Checking answer with GNU arbitrary precision calculator... '; [ $(bc <<< " .. rsa_1536 .. "*" .. rsa_2048 .. " | tr -d '" .. '\n\\' .. "' 2> /dev/null) = " .. rsa_mult .. " ] && echo success || echo failure")
print()

print("-- Divide two positives")
demo_divide(math.random(10000), math.random(100))
print("-- Divide two negatives")
demo_divide(math.random(-10000, 0), math.random(-100, 0))
print("-- Divide a negative and a positive")
demo_divide(math.random(-10000, 0), math.random(100))
print("-- (Cannot demo divide by zero because of assertion failure)")
print()

print("-- Generate a random bigint between 1 and 100 with the internal PRNG")
demo_random(100)
print("-- Generate a random bigint between -100 and -1 with the internal PRNG")
demo_random(-100, -1)
demo_subtract(-100, -1)
print("-- Generate a random bigint between -100 and 100 with the internal PRNG")
demo_random(-100, 100)
print()

print("-- Unserialize large random number to a number")
print(bigint.unserialize(bigint_extra.random(bigint.new("100000000000000000000000000000000000000000000000000000000000000000000")), "number"))
print("-- Unserialize large random number to a string")
print(bigint.unserialize(bigint_extra.random(bigint.new("100000000000000000000000000000000000000000000000000000000000000000000")), "string"))
print("-- Unserialize large random number to a human-readable string")
print(bigint.unserialize(bigint_extra.random(bigint.new("100000000000000000000000000000000000000000000000000000000000000000000")), "human-readable"))
print("-- Unserialize large random number to a scientific notation string")
print(bigint.unserialize(bigint_extra.random(bigint.new("100000000000000000000000000000000000000000000000000000000000000000000")), "scientific"))
print()
