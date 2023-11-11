#!/bin/bash

# Variáveis globais
a=0
r=0
file1=""
file2=""
sort_order=""

# Função para exibir a ajuda
function exibir_ajuda() {
    echo "Usage: $0 [-a] [-r] <file1> <file2>"
    echo "Options:"
    echo "  -r              Reverse order sorting"
    echo "  -a              Sort by file name"
}

# Processar argumentos
while getopts "ar" opt; do
    case $opt in
        r) r=1 ;;
        a) a=1 ;;
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

    declare -A DirA
    declare -A DirN

    # Ler e alocar os tamanhos e nomes dos ficheiros do primeiro diretório num array associativo
    while IFS=$'\t' read -r size name; do
        DirA["$name"]=$size
    done < <(tail -n +2 "$1")

    # Ler e alocar os tamanhos e nomes dos ficheiros do segundo diretório num array associativo
    while IFS=$'\t' read -r size name; do
        DirN["$name"]=$size
    done < <(tail -n +2 "$2")


    # Comparar os dois arrays associativos
    for file in "${!DirN[@]}"; do
        if [ -n "${DirA[$file]}" ]; then
            size1="${DirA[$file]}"
            size2="${DirN[$file]}"
            diff=$((size2 - size1))
            # Se a diferença de tamanho for não-negativa, imprimir como uma atualização
            if [ "$diff" -ge 0 ]; then
                echo -e "$diff\t$file"
            fi
        # Se o arquivo for novo (não existia no primeiro diretório), marcá-lo como "NEW"
        else
            diff="${DirN[$file]}"
            echo -e "$diff\t$file\tNEW"
        fi
    done

    for file in "${!DirA[@]}"; do
        # Se o arquivo não existir no segundo diretório, marcá-lo como "REMOVED"
        if [ -z "${DirN[$file]}" ]; then
            diff=$(( ${DirA[$file]} - 2*${DirA[$file]} ))
            echo -e "$diff\t$file\tREMOVED"
        fi
    done
}

# Atribuir o valor da variável sort_order de acordo com os argumentos fornecidos
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

comparar_ficheiros "$file1" "$file2" | sort -t $'\t' "$sort_order"
