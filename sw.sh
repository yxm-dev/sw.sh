#! /bin/bash

installdir=$HOME/.config/sw.sh

# declaring arrays
    declare -a sw_topdir
    declare -a sw_mddir
    declare -a sw_alias
    declare -a sw_gitdir
    declare -a sw_commit
    declare -a sw_branch
    declare -a sw_remote
    declare -a sw_mdDIR
    declare -a sw_tpl
    declare -a sw_html
# including data
    source $installdir/data
# defining variables
    for i in ${!sw_alias[@]}; do
        sw_mdDIR[$i]=${sw_topdir[$i]}/${sw_mddir[$i]}
        sw_tpl[$i]=${sw_topdir[$i]}/tpl/tpl.html
        sw_html[$i]=${topdir[$i]}/html
    done
    
# SW FUNCTION
    function sw(){
## auxiliary functions
        function inv_sw_alias(){
            for i in ${!sw_alias[@]}; do
                if [[ "$1" == "${sw_alias[$i]}" ]]; then
                    x=$i
                fi
            done
        }
        error="option not defined for the \"sw\" function. Try \"sw --help\"."
        function aux(){
            has_math_1=$(grep -o "\$.\+\$" "$1")
            has_math_2=$(grep -o "\$\$.\+\$\$" "$1")
            if [[ ! -z "$has_math_1" ]] || [[ ! -z "$has_math_2" ]]; then
                filter_katex="--filter pandoc-static-katex"
                css_katex="--css https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.8.3/katex.min.css"
            else
                filter_katex=""
                css_katex=""
            fi
            name=$(basename $1)
            sed -r 's/(\[.+\])\(([^)]+)\)/\1(\2.html)/g; s/(\[\[.+\]\])/\1(\1.html)/g' < "$1" | pandoc -s $1 $filter_katex -t html5 $css_katex --template ${sw_tpl[$2]} | sed -r 's/<li>(.*)\[ \]/<li class="todo done0">\1/g; s/<li>(.*)\[X\]/<li class="todo done4">\1/g; s/https:(.*).html/https:\1/g; s/.md.html/.html/g;' > "$name.html"
        }
            if   [[ "$1" == "-c" ]] || [[ "$1" == "-cvt" ]] ||
                 [[ "$1" == "--convert" ]]; then
                if [[ "${sw_alias[@]}" =~ "$2" ]]; then
                    echo "deleting old html files..."
                    inv_sw_alias $2
                    rm -r ${sw_html[$x]}
                    mkdir ${sw_html[$x]}
                    echo "recreating the html/ dir..."
                    cp -r ${sw_mdDIR[$x]}/* ${sw_html[$x]}/
                    sw_htmlfiles=$(find ${sw_html[$x]} -type f -name "*.md")
                    for f in ${sw_htmlfiles[@]}; do
                        echo "converting $f..."
                        dir=$(dirname $f)
                        cd $dir
                        aux $f $x
                    done
                    echo "fixing possible errors..."
                    find ${sw_html[$x]} -type f -name "*.md" -delete
                    find ${sw_html[$x]} -name '*.md.html' -execdir bash -c 'mv -i "$1" "${1//.md.html/.html}"' bash {} \;
                    echo "Done!"
                elif [[ -z "$2" ]]; then
                    for i in ${!sw_alias[@]}; do
                        sw -c ${sw_alias[$i]}
                    done
                else
                    echo $error
                fi
            elif [[ "$1" == "-p" ]] || [[ "$1" == "--push" ]]; then
                if [[ "${sw_alias[@]}" =~ "$2" ]]; then
                    inv_sw_alias $2
                    rsync -av --progress --delete  --exclude '.git/*' --exclude '.domains' ${sw_html[$x]}/ ${sw_gitdir[$x]} 
                    cd ${sw_gitdir[$x]}
                    git add .
                    git commit -m "${sw_commit[$x]}"
                    git pull ${sw_remote[$x]} ${sw_branch[$x]}
                    git push ${sw_remote[$x]} ${sw_branch[$x]}
                    echo "Done!"
                elif [[ -z $2 ]]; then
                    for i in ${!sw_alias[@]}; do
                        sw -p ${alias[$i]}
                    done
                else
                    echo $error
                fi
            elif [[ "$1" == "-cf" ]] || [[ "$1" == "-cfg" ]] ||
                 [[ "$1" == "--config" ]] && [[ -z "$2" ]]; then
                echo "executing config..."
            elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] &&
                 [[ -z "$2" ]]; then
                echo "executing help..."
            elif [[ -z "$1" ]] || [[ "$1" == "-i" ]] ||
                 [[ "$1" == "--interactive" ]] && [[ -z "$2" ]]; then
                echo "interactive mode..."
            else 
                echo $error
            fi
            unset -f aux
            unset -f inv_sw_alias
        }
   
# ALIASES
    alias swc="sw -c"
    alias swp="sw -p"
    alias swh="sw -h"
    alias swcf="sw -cf"
