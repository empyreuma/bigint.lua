First of all, thank you very much for showing an interest in contributing! Or
maybe you just saw the big caps and got curious. I don't know, it's possible.

Either way, if you were planning on contributing (or are now planning on
contributing after learning what this file is about), please keep the following
guidelines in mind before you go create stuff and submit a pull request. This
ensures that the codebase of this project remains nice and consistent.

# Style

STAY WITHIN 80 COLUMNS!!! Most text editors should have an option to place a
mark on the 80th column to warn you. If you need to, put arguments or parts of
an expression on new lines. Good examples of this can be found at the bottom of
the bigint.compare() function and in the logic part of bigint.add\_raw. If this
is still too long, you probably have a problem with your naming convention.

Use four spaces instead of tabs. Spaces are necessary to align arguments, and
using both spaces and tabs will be very messy.

Do not use camelCase. Instead, you should use\_underscores\_for\_everything.

All variables should concisely but clearly summarize what they describe.

Arguments should(be, separated, by, spaces).

If you are using more than 4 levels of indentation, try to see if you can
reimplement your functionality to use less. Ways of doing that include writing
new functions or restructuring your function's flow.

# Function structure

Functions should be set up as follows:

    -- Global variables (functions with these should probably be in
    -- bigint-extra) or constants should be declared outside the function.

    -- Include a brief comment about what your function does, what the types of
    -- its arguments are, and what it returns.
    function bigint.your_function_name(big1, big2, ...)
        -- Type checking, if not done by a later function, should be at the very
        -- top. If type checking is done later, add a comment explaining what
        -- function is doing the type checking.

        -- Initialization of necessary variables, all local, should be next.

        -- If a bigint is being returned, then initialize a new bigint with
        local result = bigint.new()
        -- Or
        local result = big1:clone()

        -- In the middle section is where all the logic goes. You should stick
        -- to builtin functions instead of reimplementing them if you can get
        -- the job done by using them. You should avoid creating new functions
        -- if at all possible. This allows improvements to the core functions to
        -- impact the entire code base.

        -- Near the end of your function, include any necessary sanity checks
        -- like removing leading zeroes or doing last minute tweaks to the
        -- result.

        -- At the end:
        return result
    end

If a function is not a core arithmetic function, such as differentiation or
random number generation, put it in bigint-extra.

You may split a function into a frontend and backend version. Backend versions
should be labeled as function\_name\_raw. For example, the backend functions of
bigint.add are bigint.add\_raw and bigint.subtract\_raw.

If you copy functionality from another part of bigint, add a very prominent
comment saying so. This allows that functionality to later be reimplemented as
its own internal function if it is reused too much.

# That's all! Happy hacking!
