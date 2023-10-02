#!/bin/bash

eval $(opam env)

while read line; do
    export "$line"
done < .env

dune exec application.exe "$1"
