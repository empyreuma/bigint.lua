#!/bin/sh
# Parse the table located at http://www.isthe.com/chongo/tech/math/number/tenpower.html
# to build table in lua where the index is the power and the value is the name

echo "number_names = {}"
curl -s http://www.isthe.com/chongo/tech/math/number/tenpower.html | \
    grep SUP | grep -vE "(ten|one hundred) " | \
    while read line
do
    power=$(awk -v FS="(10<SUP>|</SUP>)" '{print $2}' <<< "$line")
    name=$(awk -v FS="(<TD>one |</TD></TR>)" '{print $2}' <<< "$line")
    if ! [ -z "$power" ] && ! [ -z "$name" ]; then
        echo "number_names[$power] = \"$name\""
    fi
done
