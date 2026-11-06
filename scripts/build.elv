#!/usr/bin/env elvish

use os
use str

mkdir -p versions

var config   = (from-json < versions.json)
var template = (slurp < common.tex)

fn format-snippets {|category items|
    for item $items {
        var path = snippets/$category/$item.tex
        if (not (os:exists $path)) {
            echo 'ERROR: missing snippet file '$path
            exit 1
        }

        slurp < $path
    } | str:join "\n "
}

fn build-version {|ver|
    var spec = $config[$ver]

    var edu-block  = (format-snippets education  $spec[education])
    var exp-block  = (format-snippets experience $spec[experience])
    var proj-block = (format-snippets projects   $spec[projects])

    var step1     = (str:replace '%%EDUCATION%%'  $edu-block $template)
    var step2     = (str:replace '%%EXPERIENCE%%' $exp-block $step1)
    var final-tex = (str:replace '%%PROJECTS%%'   $proj-block $step2)

    var tex-path = versions/$ver.tex

    echo $final-tex > $tex-path
    echo 'Generated '$tex-path

    pdflatex -interaction=nonstopmode -halt-on-error -output-directory=versions $tex-path > /dev/null
    echo 'compiled  versions/'$ver'.pdf'

    rm -f versions/$ver.aux versions/$ver.log versions/$ver.out versions/$ver.fdb_latexmk versions/$ver.fls versions/$ver.synctex.gz
}

if (== 0 (count $args)) {
    for ver [(keys $config)] {
        build-version $ver
    }
} else {
    for ver $args {
        build-version $ver
    }
}
