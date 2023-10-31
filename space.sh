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

    # Função para calcular o espaço ocupado por um arquivo ou diretório
    function calcular_espaco() {
      local item="$1"
      local espaco="NA"

      if [ -e "$item" ]; then
          espaco=$(du -b -sh "$item" 2>/dev/null | cut -f1)
          if [ -z "$espaco" ]; then
              espaco="NA"
          fi
      fi

      echo "$espaco"
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

    function processar_diretorio() {
      local dir="$1"
      
      find_cmd="find $dir"

      if [ -n "$regex_filter" ]; then
          find_cmd="$find_cmd -type f -regex "$regex_filter""
      fi

      if [ -n "$max_modification_date" ]; then
          find_cmd="$find_cmd -type f -newermt $max_modification_date"
      fi

      if [ -n "$min_file_size" ]; then
          find_cmd="$find_cmd -type f -size +${min_file_size}c"
      fi

      if [ -n "$regex_filter" ] || [ -n "$max_modification_date" ] || [ -n "$min_file_size" ]; then
          find_cmd="$find_cmd -printf '%p\n'"
      else
          find_cmd="$find_cmd -type d -printf '%p\n'"
      fi

      if [ "$sort_by_name" = true ]; then
          sort_cmd="sort"
      elif [ "$reverse" = true ]; then
          sort_cmd="sort -rh"
      else
          sort_cmd="sort -h"
      fi

      eval $find_cmd | while IFS= read -r item; do
          total_size=$(du -sh "$item" | cut -f1)
          printf "%s: %s\n" "$total_size" "$item"
      done | $sort_cmd

      if [ -n "$limit_lines" ]; then
          head -n $limit_lines
      fi
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


    # Verificar se o diretório foi passado como argumento

    if [ -n "$1" ]; then
        dir="$1"
    else
        dir="."  # Defina o diretório padrão se nenhum diretório for especificado.
    fi


    # Gerar comando find baseado em opções
    processar_diretorio "$dir"

