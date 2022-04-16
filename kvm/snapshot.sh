#!/bin/bash

HOST=localhost
KVM_GUESTS=()

if ! which virsh > /dev/null 2>&1;then
    echo "virsh not found" && exit 1
fi

if [ "$(id -u)" != "0" ];then
    v="sudo virsh"
else
    v="virsh"
fi

get_kvm_guests(){
    index=1
    for g in $($v list --name --all);do
        KVM_GUESTS+=($g)
    done
    echo
    echo "########### KVM guests ################# "
    echo
    for g in ${KVM_GUESTS[@]};do
        echo "$index. $g"
        index=$(($index+1))
    done    
}

list_snapshot(){
    g=$1
    echo
    if [ $($v snapshot-list $g --name|egrep -v ^$|wc -l) != 0 ];then
        echo "################# Snapshots of $g #####################"
        echo
        $v snapshot-list $g
    else
        echo
        echo "$g has no active snapshot"
    fi
}

create_snapshot(){
    g=$1
    echo
    read -p "Do you want to create a snapshot: [y/N(default)] " choice
    if [ "${choice^^}" == "Y" ];then
        echo
        read -p "Snapshot name: " input
        read -p "Continue [Y/n]: " choice
        if [ "${choice^^}" == "Y" ] || [ -z $choice ];then
            $v snapshot-create-as $g --name $input --disk-only
        else
            echo "Bye!"
        fi
    elif [ "${choice^^}" == "N" ] || [ -z $choice ];then
        echo "Bye!" && exit 0
    else
        echo "Error! Invalid input" && exit 2
    fi
}

delete_snapshot(){
    g=$1
    echo
    read -p "Do you want to create a snapshot: [y/N(default)] " choice
    
}
select_guest(){
    get_kvm_guests
    echo "0. Exit [default]"
    echo
    read -p "Select KVM guest: " choice
    
    if ! [[ $choice =~ ^[0-9] ]];then
        echo "Error! invalid input" && exit 1
    elif [ "$choice" -gt "${#KVM_GUESTS[@]}" ];then
        echo "Error! $choice is out of index" && exit 1
    elif [ "$choice" == "0" ] || [ -z $choice ];then
        echo "Bye!" && exit 0
    fi

    gindex=$(($choice-1))
    selected_vm=${KVM_GUESTS[$gindex]}
    echo
    echo "Selected KVM guest: $selected_vm"
    echo
    list_snapshot "$selected_vm"
    create_snapshot "$selected_vm"
}

select_guest

