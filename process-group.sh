#!/bin/bash
groups=()
while IFS= read -r line; do
    groups+=( "$line" )
done < <( oc get groups -o custom-columns=name:metadata.name --no-headers )

# Set - as delimiter
IFS='-'

# TODO filter out groups that are not created by group-sync from source azure


for group in "${groups[@]}"
do

    #Read the group names into an array based on comma delimiter
    read -r -a strarr <<< "$group"
    if [ -z "${strarr[2]}" ]; then
        echo "Group $group is not correct format"
    else
        echo "Processing Group Name : $group "
        echo "Portfolio Name : ${strarr[0]} "
        echo "Application Name : ${strarr[1]} "
        echo "Env : ${strarr[2]}"
        echo "oc patch group $group -p '{\"metadata\":{\"labels\":{\"portfolio\":\"${strarr[0]}\",\"application\":\"${strarr[1]}\",\"role\":\"${strarr[2]}\", \"group-sync-operator.redhat-cop.io/sync-provider\":\"override\"}}}}'" | bash
    fi
    echo -e "\n"
done