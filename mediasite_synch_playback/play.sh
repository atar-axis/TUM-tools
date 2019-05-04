#!/bin/bash

echo "automatic synchronous video playback script"
echo "---"
echo "available folders are:"

shopt -s nullglob
folders=(*/)
shopt -u nullglob


j=0
for i in "${folders[@]}"
do
   if [ "$i" != "_SEEN/" ] && [ "$i" != "_SKIPPED/" ]; then
    echo "[$j] $i"
    ((j++))
   fi
done

read -e -p "choose: " -i "0" sel_folder
sel_folder=${sel_folder:-"0"}
echo "---"
echo "available files in ${folders[$sel_folder]} are:"



shopt -s nullglob
files=(${folders[$sel_folder]}*)
shopt -u nullglob

j=0
for i in "${files[@]}"
do
   if [ "$i" != "_SEEN/" ] && [ "$i" != "_SKIPPED/" ]; then
    echo "[$j] $i"
    ((j++))
   fi
done


if (( j > 1 )); then

    read -e -p "choose the master: " -i "0" sel_master
    sel_master=${sel_master:-"0"}

    echo "---"

    if [ "$sel_master" == "1" ]; then
        sel_slave=0
    else
        sel_slave=1
    fi

    echo "will playback ${files[$sel_master]} as the master and ${files[$sel_slave]} as slave in just a second..."
    echo "NOTE! please don't close the slave windows before the master (this way vlc will become a zombie - MUARRRGGAA"

    (vlc ${files[$sel_master]} --input-slave ${files[$sel_slave]}) &> /dev/null

else

    echo "will playback ${files[0]} in just a second..."
    (vlc ${files[0]}) &> /dev/null

fi

read -e -p "video is over... wanna move it? (0: seen, 1: skipped, others: leave) " -i "0" sel_move
sel_move=${sel_move:-"-"}


if [ "$sel_move" == "0" ]; then
    mkdir -p _SEEN
    mv ${folders[$sel_folder]} _SEEN/${folders[$sel_folder]}
    echo "moved to _SEEN."
elif [ "$sel_move" == "1" ]; then
    mkdir -p _SKIPPED
    mv ${folders[$sel_folder]} _SKIPPED/${folders[$sel_folder]}
    echo "moved to _SKIPPED. "
else
    echo "no movement ;)"
fi

echo "goodbye!"
