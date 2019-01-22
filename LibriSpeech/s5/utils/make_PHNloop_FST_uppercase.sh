#!/bin/bash

G_PHN_file=$1
word_sym_file=$2
UNK_Penalty=${3:-0}

old_first_node=`cat ${G_PHN_file} | grep "<s>" | awk '{print $1}'`
old_start_node=`cat ${G_PHN_file} | grep "<s>" | awk '{print $2}'`
old_end_node=`cat ${G_PHN_file} | grep "</s>" | head -n 1 | awk '{print $2}'`


echo -e "${old_first_node}\t${old_end_node}\t<eps>\t<eps>\t0"

cat ${G_PHN_file} | awk -v old_end_node=${old_end_node} -v old_start_node=${old_start_node} -v UNK_Penalty=${UNK_Penalty} '{
  if( maxnode < $1 ){maxnode=$1;}
  if( maxnode < $2 ){maxnode=$2;}
  if(NF==1){print; next}
  if($3 == "<s>"){next;}
  if($3 == "</s>"){print $1 "\t" $2 "\t<PHNSILSP>\t<eps>\t" $4+UNK_Penalty;next;}
  print $1 "\t" $2 "\t" $3 "\t<eps>\t" $4;next;
}
END{
  maxnode++;
  print old_end_node "\t" maxnode "\t<eps>\t<UNK>\t0";
  print maxnode "\t" old_start_node "\t<eps>\t<eps>\t0" ;
}'

#echo -e "${old_end_node}\t${old_start_node}\teps\t<unk>\t0"
#echo -e "${old_first_node}\t${old_end_node}\teps\teps\t0"

for i in `cat ${word_sym_file} | grep -v "<eps>"  | grep -v "<UNK>" | awk '{print $1}'` ; do
  echo -e "${old_end_node}\t${old_end_node}\t${i}\t${i}\t0"
done

