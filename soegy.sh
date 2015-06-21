#!/bin/bash

#-- Simple and open exam generator: SOEGy --

question=1
default=0

temp1=$(mktemp)
temp2=$(mktemp)

#TEST
temp3=$(mktemp)
#
args=($1 $2 $3)

soegyfullpath=$(readlink -f "$0")
soegypath=$(dirname "$soegyfullpath")
qanda=$soegypath/qanda.csv


#Help Argument
if [[ $(echo ${args[@]} | grep -c "\--help" ) -eq 1 ]]
  then
  echo "HELP!!"
  exit
fi

#Argument "-q="
questioncount=$(echo ${args[@]} | grep -o "\-q=[0-9]\{1,9\}$" | tr -d "\-q=")

if [[ -n $questioncount ]]
   then
  question=$questioncount
  default=1
questioncount=$(echo ${args[@]} | grep -o "\-q=[1-65536]$" | tr -d "\-q=")
fi

##MEHR ARGUMENTE

#Initialisierung
if [[ $default -eq 0  ]]
   then
  echo "---Initialisierung mit DEFAULT---"

else
  echo "---Initialisierung mit NO-DEFAULT---"

fi

echo "Anzahl der Fragen: $question"
echo "---------"
echo ""
#csv check


if [[ $(expr $(wc -l $qanda | cut -f 1 -d " ") \* 3) -ne $(grep -o "\;" $qanda | wc -l)  ]]
   then
  echo "FEHLER"
  exit
fi


command="cut -d \";\" -f 2 $qanda | grep -n \"server:web\" | cut -d \":\" -f 1"

cachename=$(echo $command | md5sum | cut -d " " -f1)

touch $soegypath\/cache\/$cachename

eval $command >> $temp1


if [[ $(head -n 1 $soegypath\/cache\/$cachename | cut -d " " -f1) != $(md5sum $qanda | cut -d " " -f1)  ]]
   then

echo $(md5sum $qanda | cut -d " " -f1) > $soegypath\/cache\/$cachename

while read linematch
 do


sed -n $(echo $linematch\p) $qanda >> $soegypath\/cache\/$cachename

done < $temp1

fi

rm -f $temp1

##DEBUG
doc=example/example1.fodt
##

docpre=$(grep -n "</text:sequence-decls>" $soegypath/$doc | cut -d ":" -f1)
head -n $docpre $soegypath/$doc > $temp2

###gogo
# shuf -i
maxline=$(wc -l  $soegypath\/cache\/$cachename | cut -d " " -f1)

currentline=0
seq 2 $maxline | shuf | while read shufline
do
  currentline=$(expr $currentline + 1)

#  echo '<text:p text:style-name="P1">TEST</text:p>' >> $temp2


echo -n '<text:p text:style-name="P1">' $(sed -n $(echo $shufline\p) $soegypath\/cache\/$cachename |cut -d ";" -f3 ) >> $temp2
echo '</text:p>' >>$temp2

  if [[ $currentline -eq $question ]]; then
    break
  fi
done



echo '</office:text>' >> $temp2
echo '</office:body>' >> $temp2
echo '</office:document>' >> $temp2

#cat $temp2

cp $temp2 /tmp/test3.fodt

rm -rf $temp2
