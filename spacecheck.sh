#!/bin/bash

# Default Variables
show_all_files=1
regex_filter=""
max_modification_date=""
min_file_size=""
reverse_order=""
sort_by_name=""
limit_lines=""
dir="."

# Function to calculate the space occupied by a file or directory
function calcular_espaco() {
    local item="$1"
    local espaco="NA"

    if [ -e "$item" ]; then
        espaco=$(du -bs "$item" 2>/dev/null | cut -f1)
        if [ -z "$espaco" ]; then
            espaco="NA"
        fi
    fi

    echo "$espaco"
}

# Function to calculate the total size of a directory
function calcular_tamanho_total() {
    local diretorio="$1"
    local sum=0
    local regex_filter="$2"
    local max_modification_date="$3"
    local min_file_size="$4"

    if [ -d "$diretorio" ]; then
        for item in "$diretorio"/*; do
            if [[ "$item" =~ $regex_filter && -e "$item" && ( -z "$max_modification_date" || "$(stat -c %Y "$item")" -le "$(date -d "$max_modification_date" +%s)" ) && ( -z "$min_file_size" || "$(stat -c %s "$item")" -ge "$min_file_size" ) ]]; then
                espaco=$(calcular_espaco "$item")
                if [ "$espaco" != "NA" ]; then
                    sum=$((sum + espaco))
                fi
            fi
        done
    fi

    echo "$sum"
}

# Help function
function exibir_ajuda() {
    echo "Uso: $0 [-n <regex>] [-d <data>] [-s <tamanho>] [-r] [-a] [-l <linhas>] <diretório>"
    echo "Opções:"
    echo "  -n <regex>      Filtrar por expressão regular no nome do arquivo"
    echo "  -d <data>       Filtrar por data máxima de modificação (formato AAAA-MM-DD)"
    echo "  -s <tamanho>    Filtrar por tamanho mínimo de arquivo (em bytes)"
    echo "  -r              Ordenar em ordem reversa"
    echo "  -a              Ordenar por nome de arquivo"
    echo "  -l <linhas>     Limitar o número de linhas da tabela"
    echo "  <diretório>     Diretório a ser analisado (padrão: diretório atual)"
}

# Process arguments
while getopts "n:d:s:ral:" opt; do
    case $opt in
        n) regex_filter="$OPTARG" ;;
        d) max_modification_date="$OPTARG" ;;
        s) min_file_size="$OPTARG" ;;
        r) reverse_order=1 ;;
        a) sort_by_name=1 ;;
        l) limit_lines="$OPTARG" ;;
        \?) exibir_ajuda; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Check if a directory was provided as an argument
if [ -n "$1" ]; then
    dir="$1"
else
    dir="."
fi

# Generate the 'find' command based on options
find_cmd="find $dir"

if [ -n "$regex_filter" ]; then
    find_cmd="$find_cmd -type f -regex '$regex_filter'"
else
    find_cmd="$find_cmd -type f"
fi

if [ -n "$max_modification_date" ]; then
    find_cmd="$find_cmd -newermt '$max_modification_date 00:00:00'"
fi

if [ -n "$min_file_size" ]; then
    find_cmd="$find_cmd -size +${min_file_size}c"
fi

# Execute the 'find' command and calculate the space occupied
function print_subdirectories() {
    local directory="$1"

    find "$directory" -type d -print | sort $sort_option | while read -r subdir; do
        espaco=$(calcular_tamanho_total "$subdir" "$regex_filter" "$max_modification_date" "$min_file_size")

        if [ "$espaco" -ne 0 ]; then
            printf "%s\t%s\n" "$espaco" "$subdir"
        fi
    done
}

if [ -n "$limit_lines" ]; then
    print_subdirectories "$dir" | ($sort_by_name && ($reverse_order && sort -t$'\t' -k1,1 -rh || sort -t$'\t' -k1,1 -h) || $reverse_order && sort -t$'\t' -k1,1 -r -h || sort -t$'\t' -k1,1 -h) | head -n "$limit_lines"
else
    print_subdirectories "$dir" | ($sort_by_name && ($reverse_order && sort -t$'\t' -k1,1 -rh || sort -t$'\t' -k1,1 -h) || $reverse_order && sort -t$'\t' -k1,1 -r -h || sort -t$'\t' -k1,1 -h)
fi