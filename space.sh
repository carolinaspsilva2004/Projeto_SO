#!/bin/bash

# Função para exibir a ajuda
function show_help() {
  echo "Uso: $0 [opções] diretório"
  echo "Opções:"
  echo "  -n PATTERN  Filtrar por nome de arquivo usando uma expressão regular"
  echo "  -d DATE    Filtrar por data de modificação (exemplo: 'Sep 10 10:00')"
  echo "  -s SIZE    Filtrar por tamanho mínimo (em bytes)"
  echo "  -r         Ordenar a saída em ordem reversa"
  echo "  -a         Ordenar a saída por nome (ordem alfabética)"
  echo "  -l LIMIT   Limitar o número de linhas na saída"
  echo "  -h         Mostrar esta ajuda"
  exit 1
}

# Inicialização de variáveis padrão
FILTER_NAME=""
FILTER_DATE=""
FILTER_SIZE=""
REVERSE_SORT=""
ALPHABETICAL_SORT=""
LIMIT=""
DIRECTORY=""

# Processar as opções de linha de comando
while getopts ":n:d:s:rahl:" opt; do
  case $opt in
    n) FILTER_NAME="$OPTARG";;
    d) FILTER_DATE="$OPTARG";;
    s) FILTER_SIZE="$OPTARG";;
    r) REVERSE_SORT="true";;
    a) ALPHABETICAL_SORT="true";;
    l) LIMIT="$OPTARG";;
    h) show_help;;
    \?) echo "Opção inválida: -$OPTARG" >&2; exit 1;;
  esac
done

# Obter o diretório como o último argumento não processado
shift $((OPTIND - 1))
DIRECTORY="$1"

# Verificar se o diretório existe
if [ ! -d "$DIRECTORY" ]; then
  echo "Erro: O diretório especificado não existe."
  exit 1
fi

# Função para listar os arquivos que correspondem aos critérios
function list_files() {
  local dir="$1"
  local filter_name="$2"
  local filter_date="$3"
  local filter_size="$4"

  find "$dir" -type f | while read -r file; do
    # Verificar os critérios de filtro
    if [ -z "$filter_name" ] || [[ "$(basename "$file")" =~ $filter_name ]]; then
      if [ -z "$filter_date" ] || [[ "$(date -r "$file" +"%b %d %H:%M")" == $filter_date ]]; then
        if [ -z "$filter_size" ] || [ "$(stat -c %s "$file")" -ge $filter_size ]; then
          echo "$(stat -c %s "$file") $(realpath --relative-to="$DIRECTORY" "$file") $(date -r "$file" +"%b %d %H:%M")"
        fi
      fi
    fi
  done
}

# Listar os arquivos que correspondem aos critérios
files=$(list_files "$DIRECTORY" "$FILTER_NAME" "$FILTER_DATE" "$FILTER_SIZE")

# Ordenar os arquivos com base nas opções de ordenação
if [ -n "$REVERSE_SORT" ]; then
  files=$(echo "$files" | sort -nr)
elif [ -n "$ALPHABETICAL_SORT" ]; then
  files=$(echo "$files" | sort)
fi

# Limitar o número de linhas na saída
if [ -n "$LIMIT" ]; then
  files=$(echo "$files" | head -n "$LIMIT")
fi

# Exibir a tabela resultante
echo "SIZE NAME DATE"
echo "$files"
