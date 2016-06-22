bigint.lua is a library that attempts to remove the restrictions on number size
built into vanilla Lua. In order to achieve this, all numbers using operations
that this library provides must first be passed through the bigint.new(num)
function, which converts the number into a table in which every index is a
single digit:

    bigint.new(132) -> {
        sign: "+",
        digits: { 1.0, 3.0, 2.0 }
    }

To simplify the documentation, serialized strings will, from here on out, be
referred to as being of the imaginary type "bigint".

Strings can also be passed into this function. If the number to be serialized is
already too big to exist in lua (inf), you can pass it as a string:

    bigint.new("132") -> {
        sign: "+",
        digits: { 1.0, 3.0, 2.0 }
    }

To convert a big back into a number, use the unserialize() function:

    big = bigint.new("5880")
    bigint.unserialize(big) -> 5880

Currently, only ints are supported. Floats may be added in the future.

Supported operations:
* bigint.new(num or string) - Create a new bigint
* bigint.check(bigint) - Check if a variable's "type" is bigint - can be forced 
    internally on all operations if the "strict" variable in bigint.lua is set
    to true (default behavior)
* bigint.abs(bigint) - Create a new, positive bigint with the same digits
* bigint.unserialize(bigint, bool as\_string) - Convert a bigint into to a number
    or a string
* bigint.compare(bigint, bigint, string comparison (see bigint.lua))
* bigint.add\_raw(bigint, bigint) - Backend addition operation that ignores
    signs
* bigint.subtract\_raw(bigint, bigint) - Backend subtraction operation that
    ignores signs
* bigint.add(bigint, bigint) - Frontend addition, accounting for signs
* bigint.subtract(bigint, bigint) - Frontend subtraction, accounting for signs
* bigint.multiply\_single(bigint, bigint) - Backend multiplication operation that
    multiplies a multi-digit big by a single digit and ignores signs
* bigint.multiply(bigint, bigint) - Frontend multiplication operation that
    multiplies two multi-digi bigs and accounts for signs
* bigint.random - VERY BUGGY AND MISBEHAVING RANDOM NUMBER GENERATOR!!!! DO NOT
    USE FOR IMPORTANT THINGS!!!! A BETTER ONE WILL BE CREATED AFTER MODULUS!!!!
* bigint.exponentiate(bigint, bigint) - Raise a bigint to a big power (positive
    integer powers only for now)
* bigint.divide\_raw(bigint, bigint) - DO NOT USE: Backend division operation
    that only supports positive integers, returning a result and remainder
* bigint.divide(bigint, bigint) - Frontend division operation that accounts for
    signs and translates arguments into their absolute values for use in
    bigint.divide\_raw(), returning a result and remainder
* bigint.modulus - Frontend for the already frontend bigint.divide() function
    that only returns the remainder and makes sure that the remainder has the
    same sign as the dividend, as per C standard

TODO:
* bigint.eval - Evaluate an expression, following the order of operations
* bigint-extra.lua library to extend the standard bigint library with extra
    things like pseudorandom number generation

For more detailed documentation, see bigint.lua. The operations appear in the
order that they are listed above.
