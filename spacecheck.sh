#!/bin/bash

# Variáveis globais
regex=""
data_maxima=""
size_min=""
limite_l=""
dir="."
a=0
r=0

arguments="$*"

data_atual=$(date +'%Y%m%d')

# Função para calcular o tamanho de um ficheiro
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

# Função para calcular o tamanho de um diretório
function calcular_tamanho_dir() {
    local diretorio="$1"
    local sum="NA"  # Iniciar com NA para diretórios inacessíveis

    if [ -d "$diretorio" ]; then
        # Verificar se o diretório é legível
        if [ -r "$diretorio" ]; then
            sum=0
            # Usar um loop while + read + find para evitar problemas com nomes de ficheiros contendo espaços
            while IFS= read -r -d '' item; do
                if [[ "$item" =~ $regex && -e "$item" && ( -z "$data_maxima" || "$(stat -c %Y "$item")" -le "$(date -d "$data_maxima" +%s)" ) && ( -z "$size_min" || "$(stat -c %s "$item")" -ge "$size_min" ) ]]; then
                    espaco=$(calcular_tamanho_ficheiro "$item")
                    if [ "$espaco" != "NA" ]; then
                        sum=$((sum + espaco))
                    fi
                fi
            done < <(find "$diretorio" -type f -print0)
        fi
    fi

    echo "$sum"
}


# Função para exibir a ajuda
function exibir_ajuda() {
    echo "Uso: $0 [-n <expressão>] [-d <data>] [-s <tamanho>] [-r] [-a] [-l <limitação>] <diretório>"
    echo "Opções disponíveis:"
    echo "  -n <expressão>  Filtrar por padrão de nome de arquivo"
    echo "  -d <data>       Filtrar por data máxima de modificação (formato AAAA-MM-DD)"
    echo "  -s <tamanho>    Filtrar por tamanho mínimo de arquivo (em bytes)"
    echo "  -r              Classificar em ordem inversa"
    echo "  -a              Classificar por nome de arquivo"
    echo "  -l <limitação>  Limitar a quantidade de linhas na tabela de saída"
    echo "  <diretório>     Diretório a ser examinado (predefinido: diretório atual)"
}

# Processar argumentos
while getopts "n:d:s:ral:" opt; do
    case $opt in
        n) regex="$OPTARG" ;;
        d)
            # Verificar se a data é válida
            if ! date -d "$OPTARG" &>/dev/null; then
                echo "Data inválida: $OPTARG"
                exit 1
            fi
            data_maxima="$OPTARG" ;;
        s)
            # Veirificar se o tamanho é um inteiro positivo
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
            # Verificar se o limite é um inteiro positivo
            if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                echo "Limite de linhas inválido: $OPTARG"
                exit 1
            fi
            limite_l="$OPTARG" ;;
        \?) exibir_ajuda; exit 1 ;;
    esac
done

shift $((OPTIND-1))

# Verificar se um diretório foi fornecido
if [ -n "$1" ]; then
    dir="$1"
else
    dir="."
fi

# Gerar o comando 'find' com base nos argumentos fornecidos
find_cmd="find $dir"

if [ -n "$regex" ]; then
    find_cmd="$find_cmd -type f -regex '$regex'"
else
    find_cmd="$find_cmd -type f"
fi

if [ -n "$data_maxima" ]; then
    find_cmd="$find_cmd -newermt '$data_maxima 00:00:00'"
fi

if [ -n "$size_min" ]; then
    find_cmd="$find_cmd -size +${size_min}c"
fi

# Função para imprimir os subdiretórios
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

# Imprimir cabeçalho
printf "SIZE\tNAME\t%s\n" "$data_atual $arguments" 

# Aplicar o filtro limite lines e exectar as funções
if [ -n "$limite_l" ]; then
    print_subdirectories "$dir" | head -n "$limite_l"
else
    print_subdirectories "$dir"
fi
