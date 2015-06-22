#!/bin/bash

#-- Simple and open exam generator: SOEGy --

question=1
default=0
#tempfiles
temp1=$(mktemp)
temp2=$(mktemp)
temp3=$(mktemp)
#Arguments
args=($1 $2 $3 $4)

#PATH to soegyroot, soegy.sh and qanda.csv
soegyfullpath=$(readlink -f "$0")
soegypath=$(dirname "$soegyfullpath")
qanda=$soegypath/qanda.csv
#

#Help Argument
if [[ $(echo ${args[@]} | grep -c "\--help" ) -eq 1 ]]
  then
  #Display Helptext
  echo "HELP!!"
  exit
fi
#

#Argument "-q=", how many questions?
questioncount=$(echo ${args[@]} | grep -o "\-q=[0-9]\{1,9\}$" | tr -d "\-q=")


if [[ -n $questioncount ]]
   then

  question=$questioncount
  default=1


#questioncount=$(echo ${args[@]} | grep -o "\-q=[1-65536]$" | tr -d "\-q=")
fi
#


#show initialisierung
if [[ $default -eq 0  ]]
   then
  echo "---Initialisierung mit DEFAULT---"

else
  echo "---Initialisierung mit NO-DEFAULT---"

fi

echo "Anzahl der Fragen: $question"
echo "---------"
echo ""
#


#csv check
if [[ $(expr $(wc -l $qanda | cut -f 1 -d " ") \* 3) -ne $(grep -o "\;" $qanda | wc -l)  ]]
   then
  echo "FEHLER"
  exit
fi
#

#Cache creation
#DEBUG
#Replace with user input
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
#


#DEBUG
doc=example/example1.fodt
#

#fodt part
#where is the text part?
docpre=$(grep -n "</text:sequence-decls>" $soegypath/$doc | cut -d ":" -f1)
head -n $docpre $soegypath/$doc > $temp2
head -n $docpre $soegypath/$doc > $temp3
maxline=$(wc -l  $soegypath\/cache\/$cachename | cut -d " " -f1)

#Shuffle
currentline=0
x=0
seq 2 $maxline | shuf | while read shufline
do
  currentline=$(expr $currentline + 1)


x=$(( $x+1 ))

#The questions into fodt
echo -n '<text:p text:style-name="Standard"></text:p>' >> $temp2
echo -n '<text:p text:style-name="Standard">' $x")" $(sed -n $(echo $shufline\p) $soegypath\/cache\/$cachename |cut -d ";" -f3 ) >> $temp2
#The answer into fodt
echo -n '<text:p text:style-name="Standard">' $x")" $(sed -n $(echo $shufline\p) $soegypath\/cache\/$cachename |cut -d ";" -f4 ) >> $temp3
echo '</text:p>' >>$temp3
#echo -n '<text:p text:style-name="Standard"></text:p>' >> $temp3
#echo -n '<text:p text:style-name="Standard"></text:p>' >> $temp3
#The answer into fodt
#The questions into fodt
echo '</text:p>' >>$temp2
echo -n '<text:p text:style-name="Standard"></text:p>' >> $temp2
echo -n '<text:p text:style-name="Standard">_______________________________________________________________</text:p>' >> $temp2
echo -n '<text:p text:style-name="Standard"></text:p>' >> $temp2
echo -n '<text:p text:style-name="Standard">_______________________________________________________________</text:p>' >> $temp2
echo -n '<text:p text:style-name="Standard"></text:p>' >> $temp2



#break if enought questions are there
  if [[ $currentline -eq $question ]]; then
    break
  fi

done
#end fodt
echo '</office:text>' >> $temp2
echo '</office:body>' >> $temp2
echo '</office:document>' >> $temp2
echo '</office:text>' >> $temp3
echo '</office:body>' >> $temp3
echo '</office:document>' >> $temp3

#Some DEBUG
cp $temp2 /tmp/test3.fodt
cp $temp3 /tmp/test3_antworten.fodt

rm -rf $temp2
rm -rf $temp3
