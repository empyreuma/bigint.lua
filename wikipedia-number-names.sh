#!/bin/sh
# Parse the table located at
# https://en.wikipedia.org/wiki/List_of_notable_numbers#English_names_for_powers_of_10
# to generate commands to build table in lua where the index is the power and
# the value is the name

last_power=

echo "number_names = {}"
curl -s https://en.wikipedia.org/wiki/List_of_notable_numbers | \
    sed -n "/English names for powers of 10/,/Proposed systematic names for powers of 10/p" | \
    grep sup.*sup -A 1 | \
    while read line
do
    power=$(awk -v FS="(<sup>|</sup>)" '{print $2}' <<< "$line")
    if ! [ -z "$power" ]; then
        last_power="$power"
    fi
    name=$(awk -v FS="(<td>|</td>)" '{print $2}' <<< "$line")
    if ! [ -z "$last_power" ] && \
       ! [ -z "$name" ] && \
       [ "$(tr -cd [:alpha:] <<< "$name")" = "$name" ]
    then
        echo "number_names[$last_power] = \"$name\""
    fi
done
