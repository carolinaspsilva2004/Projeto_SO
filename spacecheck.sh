 # funçao que permite a visualização do espaço
    # ocupado pelos ficheiros selecionados na(s) diretoria(s) que lhe é(são) passada(s) 
    # como argumento e em todas as subdiretorias destas.

    #!/bin/bash

    # Variáveis padrão
    show_all_files=1
    regex_filter=""
    max_modification_date=""
    min_file_size=""
    reverse_order=""
    sort_by_name=""
    limit_lines=""
    dir="."
    
    # Verificar se o diretório foi passado como argumento

    if [ -n "$1" ]; then
        dir="$1"
    else
        dir="."  # Defina o diretório padrão se nenhum diretório for especificado.
    fi

    # Função para calcular o espaço ocupado por um arquivo ou diretório
    function calcular_espaco() {
        local item="$1"
        local espaco="NA"

        if [ -e "$item" ]; then
            espaco=$(du -b "$item" 2>/dev/null | cut -f1)
            if [ -z "$espaco" ]; then
                espaco="NA"
            fi
        fi

        echo "$espaco"
    }

    function calcular_tamanho_total() {
        local diretorio="$1"
        local sum=0

        if [ -d "$diretorio" ]; then
            for item in "$diretorio"/*; do
                # Adicione uma verificação para ver se o arquivo corresponde ao filtro regex
                if [[ "$item" =~ $regex_filter ]] && [ -e "$item" ]; then
                    espaco=$(du -b "$item" 2>/dev/null | cut -f1)
                    if [ -n "$espaco" ]; then
                        sum=$((sum + espaco))
                    fi
                fi
            done
        fi

        echo "$sum"
    }

    # Função de ajuda
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

    # Processar argumentos
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

    # Gerar comando find baseado em opções
    find_cmd="find $dir"

    if [ -n "$regex_filter" ]; then
        find_cmd="$find_cmd -type f -regex "$regex_filter""
    else
        find_cmd="$find_cmd -type f"
    fi


    if [ -n "$max_modification_date" ]; then
        find_cmd="$find_cmd -newermt $max_modification_date"
    fi

    if [ -n "$min_file_size" ]; then
        find_cmd="$find_cmd -size +${min_file_size}c"
    fi

    # Executar o comando find e calcular espaço ocupado
    #!/bin/bash


    # Modifique a seção após o comentário "# Executar o comando find e calcular espaço ocupado"

    function print_subdirectories() {
        local directory="$1"

        find "$directory" -type d -print | while read -r subdir; do
            espaco=$(calcular_tamanho_total "$subdir")

            if [ "$espaco" -ne 0 ]; then
            printf "%s\t%s\n" "$espaco" "$subdir"
        fi
        done
    }

    if [ -n "$limit_lines" ]; then
        print_subdirectories "$dir" | ($sort_by_name && ($reverse_order && sort -k1,1 -rh || sort -k1,1 -h) || $reverse_order && sort -r -k1,1 -h || sort -k1,1 -h) | head -n "$limit_lines"
    else
        print_subdirectories "$dir" | ($sort_by_name && ($reverse_order && sort -k1,1 -rh || sort -k1,1 -h) || $reverse_order && sort -r -k1,1 -h || sort -k1,1 -h)
    fi