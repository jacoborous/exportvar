#!/bin/bash
function switch_array5() {
        local array5=${1}
        shift 1
        case ${array5} in
                1)
                        ${1}
                ;;
                2)
                        ${2}
                ;;
                3)
                        ${3}
                ;;
                4)
                        ${4}
                ;;
                5)
                        ${5}
                ;;
                *)
                        ${6}
                ;;
        esac
}

