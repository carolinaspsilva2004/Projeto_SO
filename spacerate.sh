#!/bin/bash

# Variáveis por defeito
a=0
r=0
limite_l=""
file1=""
file2=""
sort_order=""

# Função para exibir a ajuda
function exibir_ajuda() {
    echo "Usage: $0 [-a] [-r] [-l <lines>] <file1> <file2>"
    echo "Options:"
    echo "  -r              Reverse order sorting"
    echo "  -a              Sort by file name"
    echo "  -l <lines>     Limit the number of table lines"
}

# Processar argumentos
while getopts "arl:" opt; do
    case $opt in
        r) r=1 ;;
        a) a=1 ;;
        l)
            # Verificar se o argumento é um número inteiro
            if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                echo "Invalid line limit: $OPTARG"
                exibir_ajuda
                exit 1
            fi
            limite_l="$OPTARG" ;;
        \?) exibir_ajuda; exit 1 ;;
    esac
done

shift $((OPTIND-1))

if [ $# -eq 2 ]; then
    file1="$1"
    file2="$2"
else
    exibir_ajuda
    exit 1
fi

# Função para comparar os dois ficheiros
function comparar_ficheiros() {

    declare -A size1_dict
    declare -A size2_dict

    # Read and allocate the sizes and names of the files from the first directory into an associative array
    while IFS=$'\t' read -r size name; do
        size1_dict["$name"]=$size
    done < "$1"

    # Read and allocate the sizes and names of the files from the second directory into an associative array
    while IFS=$'\t' read -r size name; do
        size2_dict["$name"]=$size
    done < "$2"

    # Compare the two directories
    for file in "${!size2_dict[@]}"; do
        if [ -n "${size1_dict[$file]}" ]; then
            size1="${size1_dict[$file]}"
            size2="${size2_dict[$file]}"
            diff=$((size2 - size1))
            if [ "$diff" -ge 0 ]; then
                echo -e "$diff\t$file"
            fi
        else
            diff="${size2_dict[$file]}"
            echo -e "$diff\t$file\tNEW"
        fi
    done

    for file in "${!size1_dict[@]}"; do
        if [ -z "${size2_dict[$file]}" ]; then
            diff=$(( ${size1_dict[$file]} - 2*${size1_dict[$file]} ))
            echo -e "$diff\t$file\tREMOVED"
        fi
    done
}


if [ "$a" -eq 1 ]; then
    sort_order="-k2,2"
    if [ "$r" -eq 1 ]; then
        sort_order="-k2,2r"
    fi
else
    sort_order="-k1,1"
    if [ "$r" -eq 1 ]; then
        sort_order="-k1,1n"
    else
        sort_order="-k1,1nr"  
    fi
fi


if [ -n "$limite_l" ]; then
    comparar_ficheiros "$file1" "$file2" | sort -t $'\t' "$sort_order" | head -n "$limite_l"
else
    comparar_ficheiros "$file1" "$file2" | sort -t $'\t' "$sort_order"
fi
