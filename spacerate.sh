
#!/bin/bash

# Função para exibir a ajuda
function show_help() {
  echo "Uso: $0 [opções] arquivo1 arquivo2"
  echo "Opções:"
  echo "  -r         Ordenar a saída em ordem reversa"
  echo "  -a         Ordenar a saída por nome (ordem alfabética)"
  echo "  -n         Não diferenciar diretórios apenas em um arquivo"
  echo "  -l LIMIT   Limitar o número de linhas da tabela"
  echo "  -h         Mostrar esta ajuda"
  exit 1
}

# Inicialização de variáveis padrão
REVERSE_SORT=""
ALPHABETICAL_SORT=""
SHOW_ONLY_COMMON_DIRS=""
LIMIT=""

# Processar as opções de linha de comando
while getopts ":ranhl:" opt; do
  case $opt in
    r) REVERSE_SORT="true";;
    a) ALPHABETICAL_SORT="true";;
    n) SHOW_ONLY_COMMON_DIRS="true";;
    l) LIMIT="$OPTARG";;
    h) show_help;;
    \?) echo "Opção inválida: -$OPTARG" >&2; exit 1;;
  esac
done

# Verificar o número de argumentos
if [ $# -ne 2 ]; then
  echo "Erro: Forneça exatamente dois arquivos de saída do spacecheck para comparar."
  exit 1
fi

file1="$1"
file2="$2"

# Função para comparar dois arquivos de saída do spacecheck
function compare_spacecheck_files() {
  local file1="$1"
  local file2="$2"

  join -a 1 -a 2 -o 1.1 1.2 2.2 <(sort "$file1") <(sort "$file2")
}

# Comparar os dois arquivos de saída do spacecheck
compared_result=$(compare_spacecheck_files "$file1" "$file2")

# Exibir apenas diretórios comuns
if [ -n "$SHOW_ONLY_COMMON_DIRS" ]; then
  compared_result=$(echo "$compared_result" | awk '$2 == $3 || ($2 == "NEW" && $3 == "REMOVED")')
fi

# Ordenar os resultados com base nas opções
if [ -n "$REVERSE_SORT" ]; then
  compared_result=$(echo "$compared_result" | sort -r -k1,1 -h)
elif [ -n "$ALPHABETICAL_SORT" ]; then
  compared_result=$(echo "$compared_result" | sort -k2,2)
fi

# Limitar o número de linhas na saída
if [ -n "$LIMIT" ]; then
  compared_result=$(echo "$compared_result" | head -n "$LIMIT")
fi

# Exibir a tabela resultante
echo "SIZE NAME STATUS"
echo "$compared_result"
