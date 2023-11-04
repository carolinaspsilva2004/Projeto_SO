#!/bin/bash

# Default Variables
regex=""
data_maxima=""
size_min=""
limite_l=""
dir="."
a=0
r=0

data_atual=$(date +'%Y%m%d')

# Function to calculate the space occupied by a file or directory
function calcular_tamanho_ficheiro() {
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
function calcular_tamanho_dir() {
    local diretorio="$1"
    local sum="NA"  # Initialize sum as "NA"

    if [ -d "$diretorio" ]; then
        # Check if the directory is accessible
        if [ -r "$diretorio" ]; then
            sum=0
            for item in "$diretorio"/*; do
                if [[ "$item" =~ $regex && -e "$item" && ( -z "$data_maxima" || "$(stat -c %Y "$item")" -le "$(date -d "$data_maxima" +%s)" ) && ( -z "$size_min" || "$(stat -c %s "$item")" -ge "$size_min" ) ]]; then
                    espaco=$(calcular_tamanho_ficheiro "$item")
                    if [ "$espaco" != "NA" ]; then
                        sum=$((sum + espaco))
                    fi
                fi
            done
        fi
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
        n) regex="$OPTARG" ;;
        d)
            # Check if data_maxima is a valid date
            if ! date -d "$OPTARG" &>/dev/null; then
                echo "Data inválida: $OPTARG"
                exit 1
            fi
            data_maxima="$OPTARG" ;;
        s)
            # Check if size_min is a positive integer
            if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                echo "Tamanho inválido: $OPTARG"
                exit 1
            fi
            size_min="$OPTARG" ;;
        r)
            r=1 ;;
        a)
            a=1 ;;
        l)
            # Check if limite_l is a positive integer
            if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                echo "Limite de linhas inválido: $OPTARG"
                exit 1
            fi
            limite_l="$OPTARG" ;;
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

if [ -n "$regex" ]; then
    find_cmd="$find_cmd -type f -regex '$regex'"
else
    find_cmd="$find_cmd -type f"
fi

if [ -n "$data_maxima" ]; then
    find_cmd="$find_cmd -newermt '$data_maxima 00:00:00'"
    # Formatar a data para o nome do ficheiro
    data_formatada=$(date -d "$data_maxima" +'%Y%m%d')

    nomeficheiro="spacecheck_$data_formatada.txt"
fi

if [ -n "$size_min" ]; then
    find_cmd="$find_cmd -size +${size_min}c"
fi

# Execute the 'find' command and calculate the space occupied
function print_subdirectories() {
    local directory="$1"
    local sort_order=""

    if [ "$a" -eq 1 ]; then
        sort_order="-d"
        if [ "$r" -eq 1 ]; then
            sort_order="-dr"
        fi
        find "$directory" -type d 2>/dev/null | sort "$sort_order" -t$'\t' | while read -r subdir; do
            if [ -d "$subdir" ]; then
                espaco=$(calcular_tamanho_dir "$subdir" "$regex" "$data_maxima" "$size_min")
                if [ "$espaco" != 0 ]; then
                    printf "%s\t%s\n" "$espaco" "$subdir"
                fi
            fi
        done 
    else
        sort_order="-k1,1nr"
        if [ "$r" -eq 1 ]; then
            sort_order="-k1,1n"
        fi
        find "$directory" -type d 2>/dev/null | while read -r subdir; do
            if [ -d "$subdir" ]; then
                espaco=$(calcular_tamanho_dir "$subdir" "$regex" "$data_maxima" "$size_min")
                if [ "$espaco" != 0 ]; then
                    printf "%s\t%s\n" "$espaco" "$subdir"
                fi
            fi
        done | sort -t$'\t' $sort_order
    fi
}


printf "SIZE\tNAME\t%s\t%s\n" "$data_atual" "$dir"

if [ -n "$limite_l" ]; then
    print_subdirectories "$dir" | head -n "$limite_l"
else
    print_subdirectories "$dir"
fi

# Imprimir o resultado para um ficheiro caso uma data seja fornecida
if [ -n "$nomeficheiro" ]; then
    print_subdirectories "$dir" > "$nomeficheiro"
fi