#!/bin/bash

# Default Variables
a=0
r=0
limite_l=""
file1=""
file2=""
sort_order=""

# Help function
function exibir_ajuda() {
    echo "Usage: $0 [-a] [-r] [-l <lines>] <file1> <file2>"
    echo "Options:"
    echo "  -r              Reverse order sorting"
    echo "  -a              Sort by file name"
    echo "  -l <lines>     Limit the number of table lines"
}

# Process optional arguments
# Process optional arguments
while getopts "arl:" opt; do
    case $opt in
        r) r=1 ;;
        a) a=1 ;;
        l)
            # Check if limite_l is a positive integer
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

# Now, you can directly access the remaining arguments as file1 and file2
if [ $# -eq 2 ]; then
    file1="$1"
    file2="$2"
else
    exibir_ajuda
    exit 1
fi

# Function to compare and display space changes
function comparar_ficheiros() {
    
    diff=0

    mapfile -t size1 < <(cut -f1 "$1")
    mapfile -t size2 < <(cut -f1 "$2")
    mapfile -t nomes1 < <(cut -f2 "$1")
    mapfile -t nomes2 < <(cut -f2 "$2")

    for ((i=0; i<${#nomes2[@]}; i++)); do
        for ((j=0; i<${#nomes1[@]}; i++)); do
            if [ "${nomes2[$i]}" == "${nomes1[$j]}" ]; then
                diff=$(( ${size2[$i]} - ${size1[$j]} ))
                echo -e "$diff\t${nomes2[$i]\n}"
            else
                echo -e "${size2[$i]}\t${nomes2[$i]}\tNEW\n"
            fi
        done
    done

    for ((j=0; j<${#nomes1[@]}; j++)); do
        presente=0  # Inicialize uma variável de controle

        for ((i=0; i<${#nomes2[@]}; i++)); do
            if [ "${nomes1[$j]}" == "${nomes2[$i]}" ]; then
                presente=1  # Define a variável de controle para 1 se o elemento estiver presente
                break 
            fi
        done

        if [ "$presente" -eq 0 ]; then
            echo -e "-${size1[$j]}\t${nomes1[$j]}\tREMOVED\n"
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
        sort_order="-k1,1r"
    fi
fi

# Call the function to compare and display space changes
if [ -n "$limite_l" ]; then
    comparar_ficheiros "$file1" "$file2" | sort "$sort_order" | head -n "$limite_l"
else
    comparar_ficheiros "$file1" "$file2" | sort "$sort_order"
fi
