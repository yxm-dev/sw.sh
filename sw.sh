#! /bin/bash

install_dir=$HOME/.config/sw.sh

# declaring arrays
    declare -a SW_topdir
    declare -a SW_mddir
    declare -a SW_alias
    declare -a SW_gitdir
    declare -a SW_commit
    declare -a SW_branch
    declare -a SW_remote
    declare -a SW_mdDIR
    declare -a SW_tpl
    declare -a SW_html
# including data
    source $install_dir/data
# defining variables
    for i in ${!SW_alias[@]}; do
        SW_mdDIR[$i]=${SW_topdir[$i]}/${SW_mddir[$i]}
        SW_tpl[$i]=${SW_topdir[$i]}/tpl/tpl.html
        SW_html[$i]=${SW_topdir[$i]}/html
    done
    
# SW FUNCTION
    function sw(){
## Auxiliary Functions
### inverse of "SW_alias" array
        function inv_SW_alias(){
            for i in ${!SW_alias[@]}; do
                if [[ "$1" == "${SW_alias[$i]}" ]]; then
                    x=$i
                fi
          done
        }
    
### verify if there is "$" symbols and, in this case, call "pandoc-static-katex" filter
        declare -f SW_math
        function SW_math(){
            has_math_1=$(grep -o "\$.\+\$" "$1")
            has_math_2=$(grep -o "\$\$.\+\$\$" "$1")
            if [[ ! -z "$has_math_1" ]] || [[ ! -z "$has_math_2" ]]; then
                filter_katex="--filter pandoc-static-katex"
                css_katex="--css https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.8.3/katex.min.css"
            else
                filter_katex=""
                css_katex=""
            fi
        }

        declare -f SW_option
        function SW_option(){
            if [[ "$1" == "-n" ]] || [[ "$1" == "-N" ]] ||
                 [[ "$1" == "-ns" ]] || [[ "$1" == "--number" ]] ||
                 [[ "$1" == "--number-sections" ]]; then
                    echo "adding option \"--number-sections\"."
                     number_section="--number-sections"
                 else
                     number_section=""
                fi
                if [[ "$1" == "-toc" ]] || [[ "$1" == "--toc" ]] ||
                   [[ "$1" == "--table-of-contents" ]]; then
                    echo "adding option \"--table-of-contents\"."
                    toc="--toc"
                 else
                     toc=""
                 fi
                 if [[ "$1" == "-o" ]] || [[ "$1" == "-opt" ]] ||
                    [[ "$1" == "--opt" ]] || [[ "$1" == "--option" ]]; then
                        if [[ ! "$2" == *--* ]]; then
                            echo "adding option \"--$2\"."
                            option="--$2"
                        else
                            echo "adding option \"$2\"."
                            option="$2"
                        fi
                 else
                     option=""
                 fi
        }

        declare -f SW_cvt        
        function SW_cvt(){
            SW_option $3 $4
            name=$(basename $1)
            for i in {3..4}; do
               echo "$i" > /dev/null
            done
            sed -r 's/(\[.+\])\(([^)]+)\)/\1(\2.html)/g; s/(\[\[.+\]\])/\1(\1.html)/g' < "$1" | pandoc -s $number_section $toc $option $1 $filter_katex -t html5 $css_katex --template ${SW_tpl[$2]} | sed -r 's/<li>(.*)\[ \]/<li class="todo done0">\1/g; s/<li>(.*)\[X\]/<li class="todo done4">\1/g; s/https:(.*).html/https:\1/g; s/.md.html/.html/g;' > "$name.html"
        }

### default error message
        error="option not defined for the \"sw\" function. Try \"sw --help\"."

## SW Function Properly
### "--convert" option
            if   [[ "$1" == "-c" ]] || [[ "$1" == "-cvt" ]] ||
                 [[ "$1" == "--convert" ]]; then
                if [[ -z "$2" ]]; then
                    for i in ${!SW_alias[@]}; do
                        sw -c ${SW_alias[$i]}
                    done
                elif [[ "${SW_alias[@]}" =~ "$2" ]]; then
                    echo "deleting old html files..."
                    inv_SW_alias $2
                    rm -r ${SW_html[$x]}
                    mkdir ${SW_html[$x]}
                    echo "recreating the html/ dir..."
                    cp -r ${SW_mdDIR[$x]}/* ${SW_html[$x]}/
                    SW_htmlfiles=$(find ${SW_html[$x]} -type f -name "*.md")
                    for f in ${SW_htmlfiles[@]}; do
                        echo "converting $f..."
                        dir=$(dirname $f)
                        cd $dir
                         SW_math $f
                         SW_cvt $f $x $3 $4
                    done
                    echo "fixing possible errors..."
                    find ${SW_html[$x]} -type f -name "*.md" -delete
                    find ${SW_html[$x]} -name '*.md.html' -execdir bash -c 'mv -i "$1" "${1//.md.html/.html}"' bash {} \;
                    echo "Done!"
                else
                    echo $error
                fi
### "--push" option 
            elif [[ "$1" == "-p" ]] || [[ "$1" == "--push" ]]; then
                if [[ "${SW_alias[@]}" =~ "$2" ]]; then
                    inv_SW_alias $2
                    rsync -av --progress --delete  --exclude '.git/*' --exclude '.domains' ${SW_html[$x]}/ ${SW_gitdir[$x]} 
                    cd ${SW_gitdir[$x]}
                    git add .
                    git commit -m "${SW_commit[$x]}"
                    git pull ${SW_remote[$x]} ${SW_branch[$x]}
                    git push ${SW_remote[$x]} ${SW_branch[$x]}
                    echo "Done!"
                elif [[ -z $2 ]]; then
                    for i in ${!SW_alias[@]}; do
                        sw -p ${alias[$i]}
                    done
                else
                    echo $error
                fi
### "--config" option
            elif [[ "$1" == "-cf" ]] || [[ "$1" == "-cfg" ]] ||
                 [[ "$1" == "--config" ]] && [[ -z "$2" ]]; then
                echo "executing config..."
### "--help" option
            elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] &&
                 [[ -z "$2" ]]; then
                echo "executing help..."
### with no options, start the interactive mode
            elif [[ -z "$1" ]] || [[ "$1" == "-i" ]] ||
                 [[ "$1" == "--interactive" ]] && [[ -z "$2" ]]; then
                echo "interactive mode..."
            else 
                echo $error
            fi
## Unseting Auxiliary Functions
            unset -f SW_option
            unset -f SW_math
            unset -f SW_cvt
            unset -f inv_SW_alias
        }
   
# ALIASES
    alias swc="sw -c"
    alias swp="sw -p"
    alias swh="sw -h"
    alias swcf="sw -cf"
