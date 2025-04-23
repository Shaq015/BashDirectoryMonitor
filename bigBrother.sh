#!/bin/bash

is_folder() 
{
    if [ -d $1 ]; then
        return 0
    else
        return 1
    fi
}

is_file() 
{
    if [ -f $1 ]; then
	return 0
    else
        return 1
    fi
}

created() 
{
    sorted_files=($(echo "${@}" | tr ' ' '\n' | sort))
    for file in "${sorted_files[@]}"; do
	if [ -d "$tracked_folder_name/$file" ]; then
            echo "Folder added: $file"
        elif [ -f "$tracked_folder_name/$file" ]; then
            echo "File added: $file"
        fi
    done
}

deleted() 
{
    sorted_files=($(echo "${@}" | tr ' ' '\n' | sort))
    for file in "${sorted_files[@]}"; do
        if [ -d "tracked_folder_copy/$tracked_folder_name/$file" ]; then
            echo "Folder deleted: $file" >&2
        elif [ -f "tracked_folder_copy/$tracked_folder_name/$file" ]; then
            echo "File deleted: $file" >&2
        fi
    done
}


if ! is_folder "$1" && [ ! -f file_state ];
then
    #There is no such path (first argument is not valid)
    echo "Must include valid path" >&2
elif [ ! -f file_state ] && is_folder "$1"
then
    #First call (first argument is valid)
    echo "Welcome to the Big Brother"
 
    touch file_state
    touch tracked_folder
    touch first_call_arguments
    touch num_args
    mkdir tracked_folder_copy
    
    chmod +rw file_state
    chmod +rw tracked_folder
    chmod +rw first_call_arguments
    chmod +rw num_args
    
    folder="$1"
    echo "$folder" > tracked_folder
    echo "${@:2}" > first_call_arguments
    ls "$folder" > file_state
    #cp -r "$folder" tracked_folder_copy
    
    if [ "$folder" = "`pwd`" ]; then
        cp "$folder" tracked_folder_copy
    else
        cp -r "$folder" tracked_folder_copy
    fi
    
    first_call_arguments_content=$(cat first_call_arguments)
    if [ -n "$first_call_arguments_content" ]; then
        echo "$first_call_arguments_content" | wc -w > num_args
    else
        echo "0" > num_args
    fi
    
else
    num_args=$(cat num_args)
    created_files=()
    deleted_files=()
    if [ "$num_args" -eq 0 ];
    then
        #Not the first call + no other arguments - check the whole folder
        
        tracked_folder_name=$(cat tracked_folder)
        current_state=$(ls -1 "$tracked_folder_name" | tr '\n' ' ')
        file_state_content=$(cat file_state | tr '\n' ' ')
	current_state_arr=($current_state)
	file_state_arr=($file_state_content)

        for file in "${file_state_arr[@]}"; do
            found=false
            for current_file in "${current_state_arr[@]}"; do
                if [ "$file" == "$current_file" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" == false ]; then
                deleted_files+=("$file")
            fi
        done

        for file in "${current_state_arr[@]}"; do
            found=false
            for file_state_file in "${file_state_arr[@]}"; do
                if [ "$file" == "$file_state_file" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" == false ]; then
                created_files+=("$file")
            fi
        done   
               
        if [ "${#created_files[@]}" -gt 0 ]; 
        then
            created "${created_files[@]}"
        fi

        if [ "${#deleted_files[@]}" -gt 0 ]; 
        then
            deleted "${deleted_files[@]}" 
        fi
        
        echo "${current_state[@]}" > file_state
	rm -r tracked_folder_copy
	mkdir tracked_folder_copy
	cp -r "$tracked_folder_name" tracked_folder_copy

    else
        #Not the first call + there were other arguments - check only them
        
        tracked_folder_name=$(cat tracked_folder)
        file_state_content=$(cat file_state)
        current_state=$(ls -1 "$tracked_folder_name" | tr '\n' ' ')
        first_call_arguments_content=$(cat first_call_arguments | tr '\n' ' ')
        file_state_content=$(cat file_state | tr '\n' ' ')
	file_state_arr=($file_state_content)
	current_state_arr=($current_state)
	arguments_arr=($first_call_arguments_content)
	
        for arg in "${arguments_arr[@]}"; do
            found_in_current=false
            found_in_file_state=false

            for current_file in "${current_state_arr[@]}"; do
                if [ "$arg" == "$current_file" ]; then
                    found_in_current=true
                    break
                fi
            done

            for file_state_file in "${file_state_arr[@]}"; do
                if [ "$arg" == "$file_state_file" ]; then
                    found_in_file_state=true
                    break
                fi
            done

            if [ "$found_in_current" == true ] && [ "$found_in_file_state" == false ]; then
                created_files+=("$arg")
            fi
        done

        for file_state_file in "${file_state_arr[@]}"; do
            found_in_current=false
            found_in_arguments=false

            for current_file in "${current_state_arr[@]}"; do
                if [ "$file_state_file" == "$current_file" ]; then
                    found_in_current=true
                    break
                fi
            done

            for arg in "${arguments_arr[@]}"; do
                if [ "$file_state_file" == "$arg" ]; then
                    found_in_arguments=true
                    break
                fi
            done

            if [ "$found_in_current" == false ] && [ "$found_in_arguments" == true ]; then
                deleted_files+=("$file_state_file")
            fi
        done
        
        if [ "${#created_files[@]}" -gt 0 ]; 
        then
            created "${created_files[@]}"
        fi

        if [ "${#deleted_files[@]}" -gt 0 ]; 
        then
            deleted "${deleted_files[@]}"
        fi
        
        echo "${current_state[@]}" > file_state
	rm -r tracked_folder_copy
	mkdir tracked_folder_copy
	cp -r "$tracked_folder_name" tracked_folder_copy
    fi
fi

