phn_dir=$4 #/mnt/matylda6/iegorova/kaldi_hybrid_subword_clustering/s5c_my/data/lang_phn_graph
wrd_dir=$5 #/mnt/matylda6/iegorova/kaldi_hybrid_subword_clustering/s5c_my/data/lang_wrd_graph
comb_dir=$6 #/mnt/matylda6/iegorova/kaldi_hybrid_subword_clustering/s5c_my/data/lang_wrdphn_graph
PWIP=$1     #-4		#phoneme word insertion penalty - added to log likelihood of phoneme lattice links (subtracted as we work with negaitve log likelihoods)
PLMSF=$2      #0.5 	#phoneme LM scaling factor - multiplied with log likelihood of phoneme links
PC=$3		#-6		#phoneme cost - addad to <unk> link log likelihood (subtracted as we work with negative log likelihoods)
#UNK_PENALTY=-0.0

phn_graph_dir=$phn_dir/../phn_graphs_hybrid/PWIP_${PWIP}_PLMSF_${PLMSF}_PC_${PC}
wrd_graph_dir=$wrd_dir/../wrd_graphs_hybrid/PWIP_${PWIP}_PLMSF_${PLMSF}_PC_${PC}

echo "make phoneme graph"
./utils/format_lm_sri_phn.sh --srilm-opts "-subset -prune-lowprobs -order 3" $phn_dir $phn_dir/phn.3gram.lm $phn_dir/phn.dict $phn_graph_dir

mv $phn_graph_dir/G.fst $phn_graph_dir/G_PHN.fst
fstprint --isymbols=$phn_graph_dir/words.txt $phn_graph_dir/G_PHN.fst | awk -v PLMSF=$PLMSF -v PWIP=$PWIP '{if($5!=""){if(($5*PLMSF+PWIP) > 0){print ($1 "\t" $2 "\t" $3 "\t" ($5*PLMSF+PWIP))}else{print($1 "\t" $2 "\t" $3 "\t0")}} else if($3!=""){print ($1"\t"$2"\t"$3)} else {print $1}}' > $phn_graph_dir/G_PHN.txt #was $5*PLMSF-PWIP until 1000 trials including !!!
fstcompile --acceptor=true --isymbols=$phn_graph_dir/words.txt < $phn_graph_dir/G_PHN.txt > $phn_graph_dir/G_PHN.fst
fstprint --acceptor=true --isymbols=$phn_graph_dir/words.txt < $phn_graph_dir/G_PHN.fst | sed 's/<eps>/PSI1/g' > $phn_graph_dir/G_PHN_psi.txt
cat $phn_graph_dir/words.txt | sed 's/<eps>/PSI1/g' > $phn_graph_dir/words_psi1.txt

echo "make word graph"
./utils/format_lm_sri.sh --srilm-opts "-subset -prune-lowprobs -unk -map-unk <UNK> -order 3" $wrd_dir $wrd_dir/word.3gram.lm $wrd_dir/lexicon.txt $wrd_graph_dir
mv $wrd_graph_dir/G.fst $wrd_graph_dir/G_WRD.fst
fstprint --isymbols=$wrd_graph_dir/words.txt $wrd_graph_dir/G_WRD.fst | awk '{if($5!=""){print ($1"\t"$2"\t"$3"\t"$5)} else if($3!=""){print ($1"\t"$2"\t"$3)} else {print $1}}' > $wrd_graph_dir/G_WRD.txt

echo "add word loop to phoneme graph"
utils/make_PHNloop_FST_uppercase.sh $phn_graph_dir/G_PHN_psi.txt $wrd_graph_dir/words.txt ${UNK_PENALTY} > $phn_graph_dir/G_PHNm.txt

echo "make list of common symbols"
mkdir -p $comb_dir
cat $wrd_graph_dir/words.txt $phn_graph_dir/words_psi1.txt | grep -v "<eps>" | awk '{print $1;}' | sort -u | awk 'BEGIN { print "<eps> 0"; }{ printf("%s %d\n", $1, NR); }' > $comb_dir/words.txt || exit 1;

echo "recode in common symbols"
fstcompile --acceptor=false --isymbols=$comb_dir/words.txt --osymbols=$comb_dir/words.txt < $phn_graph_dir/G_PHNm.txt > $phn_graph_dir/G_PHNm.fst
fstcompile --acceptor=true --isymbols=$comb_dir/words.txt < $wrd_graph_dir/G_WRD.txt > $wrd_graph_dir/G_WRD.fst

echo "lattice modification"
fstrmepsilon < $phn_graph_dir/G_PHNm.fst | fstarcsort --sort_type=olabel > $phn_graph_dir/G_PHNmes.fst
fstarcsort --sort_type=ilabel < $wrd_graph_dir/G_WRD.fst > $wrd_graph_dir/G_WRDmes.fst

echo "composition"
fstcompose $phn_graph_dir/G_PHNmes.fst $wrd_graph_dir/G_WRDmes.fst > $comb_dir/G_WRDPHN.fst

echo "formating resulting lattice"
fstprint --isymbols=$comb_dir/words.txt --osymbols=$comb_dir/words.txt < $comb_dir/G_WRDPHN.fst > $comb_dir/G_WRDPHN.txt
cat $comb_dir/G_WRDPHN.txt | awk -v PC=$PC '{if($3 != $4){if($4 == "<UNK>"){if(($5+PC) > 0){print ($1 "\t" $2 "\t" $4 "\t" $4 "\t" ($5+PC));}else{print ($1 "\t" $2 "\t" $4 "\t" $4)}}else{print $1 "\t" $2 "\t" $3 "\t" $3 "\t" $5;}}else{print;}}' | awk '{if($3 == "#0"){print $1 "\t" $2 "\t#0\t<eps>\t" $5;}else{print;}}' > $comb_dir/G_WRDPHNm.txt  #| awk '{if($3 == "#0"){print $1 "\t" $2 "\t#0\t<eps>\t" $5;}else{print;}}' > $comb_dir/G_WRDPHNm.txt #| awk '{if($3 == "#0"){print $1 "\t" $2 "\t<eps>\t<eps>\t" $5;}else{print;}}' > $comb_dir/G_WRDPHNm.txt 
#echo "determinization"
fstcompile --acceptor=false --isymbols=$comb_dir/words.txt --osymbols=$comb_dir/words.txt < $comb_dir/G_WRDPHNm.txt > $comb_dir/G_WRDPHNm.fst #fstrmepsilon| fstarcsort --sort_type=ilabel | fstdeterminizestar > $comb_dir/G_WRDPHNm.fst
echo "ark sorting"
fstarcsort --sort_type=ilabel $comb_dir/G_WRDPHNm.fst > $comb_dir/G_WRDPHNm_arc_sort.fst

fstprint --isymbols=$comb_dir/words.txt --osymbols=$comb_dir/words.txt $comb_dir/G_WRDPHNm_arc_sort.fst > $comb_dir/G_WRDPHNm_final.txt
mv $comb_dir/G_WRDPHNm_arc_sort.fst $comb_dir/G.fst
