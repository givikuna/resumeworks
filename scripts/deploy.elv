#!usr/bin/env elvish

use os

if (== 0 (count $args)) {
    echo 'usage: deploy-resume <version>'
    exit 1
}

var ver = $args[0]

try {
    build-resume $ver
} catch e {
    echo 'failed to build resume: '$e
    exit 1
}

mkdir -p deploy

var src  = 'versions/'$ver'.pdf'
var dest = 'deploy/Givi Tsvariani Resume.pdf'

if (not (os:exists $src)) {
    echo 'ERROR: '$src' not found after this build'
    exit 1
}

cp $src $dest
echo 'ready to use'
