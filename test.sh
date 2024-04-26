#!/bin/bash
for file in Tests/*.c; do
    output=$(./structit "$file" 2>&1)
    if [[ $output == *"Segmentation fault"* ]]; then
        echo -e "\033[31mSegmentation fault: $file\033[0m"
    elif [[ $output == *"error"* || $output == *"Error"* ]]; then
        echo -e "\033[31mFailed: $file\033[0m"
    else
        echo -e "\033[32mPassed\033[0m"
    fi
done
