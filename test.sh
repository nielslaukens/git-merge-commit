#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

WD=$( mktemp -d -t git_test )

function cleanup {
  rm -rf "$WD"
}
trap cleanup EXIT

cd "$WD"
git init

# Generate a history like this:
#  A-----B---E---F
#   \       /   /
#    `---C-´   /
#     \       /
#      `-D---´

cat > test <<EOT
a
b
c
d
e
f
g
EOT

git add test
git commit -m 'initial'
A=$(git rev-parse HEAD)
git branch i

cat > test <<EOT
a
bee
c
d
e
f
g
EOT
git add test
git commit -m 'bee'
B=$(git rev-parse HEAD)

git checkout -b d i
cat > test <<EOT
a
b
c
dee
e
f
g
EOT
git add test
git commit -m 'dee'
C=$(git rev-parse HEAD)
git checkout master
git merge --no-edit d
git branch -d d
E=$(git rev-parse HEAD)

git checkout -b f i
cat > test <<EOT
a
b
c
d
e
ef
g
EOT
git add test
git commit -m 'ef'
D=$(git rev-parse HEAD)
git checkout master
git merge --no-edit f
git branch -d f
F=$(git rev-parse HEAD)

git ll --all

FAILED=0
function test {
	EXPECTED="$1"; shift
	GOT="$( PATH="$DIR:$PATH" git merge-commit "$@" )"
	if [ "$GOT" == "$EXPECTED" ]; then
		echo "$@  ->  $EXPECTED : OK"
	else
		echo "$@  ->  $GOT : FAIL, expected $EXPECTED"
		FAILED=$(( $FAILED + 1 ))
	fi
}

# Test cases
test $A $A
test $B $A $B
test $E $A $B $C
test $E $B $C
test $E $B $C $E
test $F $B $D

if [ $FAILED -ne 0 ]; then
	exit 1
fi
