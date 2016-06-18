#!/usr/bin/env lua

bigint = require("bigint")

math.randomseed(os.time())

comparisons = {">", "<", "==", "~=", ">=", "<="}

function demo_serialize_unserialize(n)
    print(string.format("bigint.unserialize(bigint.new(%s)) -> %s", tostring(n), tostring(bigint.unserialize(bigint.new(n)))))
end

function demo_compare(n1, n2, cmp)
    cmp = cmp or comparisons[math.random(#comparisons)]
    print(string.format("bigint.compare(%s, %s, %s) -> %s", tostring(n1), tostring(n2), cmp, (bigint.compare(bigint.new(n1), bigint.new(n2), cmp) and "true" or "false")))
end

function demo_add(n1, n2)
    print(string.format("bigint.add(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.add(bigint.new(n1), bigint.new(n2))))))
end

function demo_subtract(n1, n2)
    print(string.format("bigint.subtract(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.subtract(bigint.new(n1), bigint.new(n2))))))
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
print("-- Add a positive and a negative")
demo_add(math.random(-100, 0), math.random(100))
print()

print("-- Subtract two positives")
demo_subtract(math.random(100), math.random(100))
print("-- Subtract two negatives")
demo_subtract(math.random(-100, 0), math.random(-100, 0))
print("-- Subtract a positive from a negative")
demo_subtract(math.random(-100, 0), math.random(100))
print("-- Subtract a negative from a positive")
demo_subtract(math.random(100), math.random(-100, 0))
