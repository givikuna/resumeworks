#!/usr/bin/env elvish

use os
use str

# --- Locate the data directory bundled by the Nix wrapper ---

if (not (has-env RESUMEWORKS_ROOT)) {
    echo 'resumeworks: ERROR: RESUMEWORKS_ROOT is not set (run via the Nix wrapper)' >&2
    exit 1
}

var root = $E:RESUMEWORKS_ROOT

var mode     = ''
var versions = []

for a $args {
    if (or (== $a '--help') (== $a '-h')) {
        set mode = 'help'
    } elif (== $a '--list') {
        set mode = 'list'
    } elif (== $a '--pdf') {
        set mode = 'pdf'
    } elif (== $a '--tex') {
        set mode = 'tex'
    } elif (str:has-prefix $a '--') {
        echo 'resumeworks: unknown option: '$a >&2
        exit 2
    } else {
        set versions = [$@versions $a]
    }
}

if (or (== $mode '') (== $mode 'help')) {
    echo 'usage: resumeworks (--list | --pdf <version>... | --tex <version>...)'
    echo ''
    echo '  --list              list available resume versions'
    echo '  --pdf <version>...  build <version>.pdf into the current directory'
    echo '  --tex <version>...  render <version>.tex into the current directory'
    if (== $mode '') { exit 2 } else { exit 0 }
}


var config = (from-json < $root/versions.json)

if (== $mode 'list') {
    for k [(keys $config)] {
        echo $k
    }

    exit 0
}

if (== (count $versions) 0) {
    echo 'resumeworks: no version specified' >&2
    exit 2
}

fn items-or-empty {|spec k|
    if (has-key $spec $k) { put $spec[$k] } else { put [] }
}

fn format-snippets {|category items|
    for item $items {
        var p = $root/snippets/$category/$item.tex

        if (not (os:exists $p)) {
            echo 'resumeworks: missing snippet: '$p >&2
            exit 1
        }

        put '\input{'$p'}'
    } | str:join "\n  "
}

fn render {|version|
    var spec     = $config[$version]
    var template = (slurp < $root/common.tex)

    var edu-block  = (format-snippets education  (items-or-empty $spec education))
    var exp-block  = (format-snippets experience (items-or-empty $spec experience))
    var proj-block = (format-snippets projects   (items-or-empty $spec projects))

    var step1 = (str:replace '%%EDUCATION%%'  $edu-block  $template)
    var step2 = (str:replace '%%EXPERIENCE%%' $exp-block  $step1)

    put (str:replace '%%PROJECTS%%' $proj-block $step2)
}

for version $versions {
    if (not (has-key $config $version)) {
        echo 'resumeworks: unknown version: '$version >&2
        exit 1
    }

    var tex = (render $version)

        if (== $mode 'tex') {
        echo $tex > $version.tex
        echo 'wrote ./'$version'.tex'
    } elif (== $mode 'pdf') {
        var tmp = (mktemp -d)
        echo $tex > $tmp/$version.tex

        var ok = $true
        try {
            pdflatex -interaction=nonstopmode -halt-on-error \
            -output-directory=$tmp $tmp/$version.tex
        } except e {
            set ok = $false
        }

        if (not $ok) {
            echo 'resumeworks: pdflatex failed for '$version >&2

            if (os:exists $tmp/$version.log) {
                echo 'resumeworks: last 30 lines of log:' >&2
                tail -n 30 $tmp/$version.log >&2
            }

            rm -rf $tmp

            exit 1
        }

        cp $tmp/$version.pdf $version.pdf
        rm -rf $tmp

        echo 'wrote ./'$version'.pdf'
    }
}
