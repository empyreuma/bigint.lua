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
    print(string.format("bigint.add_raw(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.add_raw(bigint.new(n1), bigint.new(n2))))))
end

function demo_subtract_raw(n1, n2)
    print(string.format("bigint.subtract_raw(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.subtract_raw(bigint.new(n1), bigint.new(n2))))))
end

demo_serialize_unserialize(math.random(100))
demo_serialize_unserialize("-" .. tostring(math.random(100)))

demo_compare(math.random(100), math.random(100))
demo_compare(math.random(-100, 0), math.random(-100, 0))
demo_compare(math.random(-100, 100), math.random(-100, 100))

demo_add(math.random(100), math.random(100))
demo_add(math.random(100), math.random(100))
demo_add(math.random(100), math.random(100))

demo_subtract_raw(100, math.random(100))
demo_subtract_raw(100, math.random(100))
demo_subtract_raw(100, math.random(100))
