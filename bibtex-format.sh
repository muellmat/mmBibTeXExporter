#!/bin/bash
#  
#  bibtex-format.sh
#  
#  Created by muellmat on 25.07.10.
#  Copyright 2010 Matthias Mueller. All rights reserved.
#  

squeeze() {
	lwidth=$1
	mwidth=$(($1-$max-4))
	folded=$(echo "$3" | fold -s -w $mwidth)
	if [ "$(echo "$folded" | wc -l)" -eq 1 ]; then
		echo "$2 = $folded"
	else
		whitespace="$(printf "%"$(($lwidth-$mwidth))"s" "")"
		echo "$2 = $(echo "$folded" | head -n 1)"
		echo "$(echo "$folded" | sed -e '1d')" | while read line; do
			echo "$whitespace$line"
		done
	fi
}

if [ -n "$1" ]; then
	tmp=$(for i in $(grep " = " $1 | awk '{ print $1 }'); do echo $i | wc -m; done)
	max=$(echo $tmp | tr ' ' '\n' | sort -n -r | head -n 1)
	cat $1 | while read line; do 
		if [ -n "$(echo $line | grep " = ")" ]; then 
			s=$(echo $line | awk '{ print $1 }')
			r=$(printf "%"$max"s\n" $s)
			if [[ "$2" =~ ^[0-9]+$ ]] && [[ "$2" -gt 0 ]]; then
				squeeze $2 "$r" "$(echo $line | sed 's/'$s' = //')"
			else
				echo "$r"$(echo $line | sed 's/'$s'//')
			fi
		else
			echo $line;
		fi
	done
else
	echo "usage: $0 [file ...] [width]"
fi