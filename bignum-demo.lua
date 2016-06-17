#!/usr/bin/env lua

bigint = require("bignum")

math.randomseed(os.time())

function rand()
    return math.random(100)
end

comparisons = {">", "<", "==", "~=", ">=", "<="}

function demo_serialize_unserialize(n)
    print(string.format("bigint.unserialize(bigint.new(%s)) -> %s", tostring(n), tostring(bigint.unserialize(bigint.new(n)))))
end

function demo_compare(n1, n2)
    local cmp = comparisons[math.random(#comparisons)]
    print(string.format("bigint.compare(%s, %s, %s) -> %s", tostring(n1), tostring(n2), cmp, (bigint.compare(bigint.new(n1), bigint.new(n2), cmp) and "true" or "false")))
end

function demo_add(n1, n2)
    print(string.format("bigint.add(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.add(bigint.new(n1), bigint.new(n2))))))
end

demo_serialize_unserialize(rand())
demo_serialize_unserialize("-" .. tostring(rand()))
demo_compare(rand(), rand())
demo_compare(rand(), rand())
demo_compare(rand(), rand())
demo_add(rand(), rand(), ">=")
demo_add(rand(), rand(), ">=")
demo_add(rand(), rand(), ">=")
