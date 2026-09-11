#!/bin/bash

# A simple function that takes a name and greats it
greet() {
	local name="$1"
	echo "Hello, $name! This is a Bash function."
}

# Calling the function, passing "Tayo" as the first argument ($1 inside the function)
greet "Tayo"
greet "DevOps"
