#!/bin/sh
set -x
cat $1.h bootico.c >ico.c
make ico
./ico  >$1.s