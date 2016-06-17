#!/usr/bin/env lua

bigint = require("bignum")

math.randomseed(os.time())

function rand()
    return math.random(100)
end

comparisons = {">", "<", "==", "~=", ">=", "<="}
function demo_compare(n1, n2)
    local cmp = comparisons[math.random(#comparisons)]
    print(string.format("bigint.compare(%s, %s, %s) -> %s", tostring(n1), tostring(n2), cmp, (bigint.compare(bigint.serialize(n1), bigint.serialize(n2), cmp) and "true" or "false")))
end

function demo_add(n1, n2)
    print(string.format("bigint.add(%s, %s) -> %s", tostring(n1), tostring(n2), tostring(bigint.unserialize(bigint.add(bigint.serialize(n1), bigint.serialize(n2))))))
end

demo_compare(rand(), rand())
demo_compare(rand(), rand())
demo_compare(rand(), rand())
demo_add(rand(), rand(), ">=")
demo_add(rand(), rand(), ">=")
demo_add(rand(), rand(), ">=")
