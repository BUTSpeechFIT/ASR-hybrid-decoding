PWIP=$1 # phoneme word insertion penalty, 0 is neutral
PLMSF=$2 # phonmeme LM scaling factor, 1 is neutral
PC=$3 # phoneme cost, 0 is neutral
stage=$4

postfix=PWIP_${PWIP}_PLMSF_${PLMSF}_PC_${PC}
baseline_lang=lang_baseline_ngram_oovs
hybrid_lang=data/lang_hybrid_$postfix

. ./cmd.sh
. ./path.sh

#stage=6

if [ $stage -le 0 ]; then
  echo "prepare dictionary and lang file with oovs from list OOV_list_1000.txt excluded"
  local/prepare_dict_ngram_oovs.sh --stage 3 --nj 30 --cmd "$train_cmd" data/local/lm data/local/lm data/local/dict_hybrid/
  utils/prepare_lang.sh data/local/dict_hybrid/ "<UNK>" data/local/$baseline_lang data/$baseline_lang
fi

if [ $stage -le 1 ]; then
  echo "make word and phoneme lang folders and LMs"
  ./utils/prepare_lang_WRDPHN.sh data/local/dict_hybrid/ "<UNK>" data/local/lang_wrdphn_hybrid data/lang_wrd_hybrid/ data/lang_phn_hybrid
  cat data/local/dict_hybrid/lexicon_raw_nosil.txt | sed 's/[0-9]*//g' | awk '{for (i=2; i<=NF; i++) printf "PHN_"$i " "; print "\n"}' | grep -v '^\s*$' > ./data/lang_phn_hybrid/lm_train_text.txt 
  ngram-count -text data/lang_phn_hybrid/lm_train_text.txt -order 3 -wbdiscount -interpolate -lm - > data/lang_phn_hybrid/phn.3gram.lm

  echo "filter OOVs from word LM"
  cat data/local/dict_hybrid/lexicon.txt | awk '{print $1}' > vocab_hybrid.txt
  change-lm-vocab -vocab vocab_hybrid.txt -lm data/local/lm/lm_tgsmall.arpa.gz -write-vocab lm_vocab_hybrid.txt -write-lm data/lang_wrd_hybrid/word.3gram.lm -subset -prune-lowprobs -unk -map-unk "<UNK>" -order 3
fi


if [ $stage -le 2 ]; then
  echo "create new combined lang folder"
  utils/make_hybrid_fst_3gram.sh $PWIP $PLMSF $PC data/lang_phn_hybrid data/lang_wrd_hybrid data/test_hybrid/${postfix}
  mkdir -p $hybrid_lang
  cp -r data/$baseline_lang/* $hybrid_lang/
  fstcompile --acceptor=false --isymbols=$hybrid_lang/words.txt --osymbols=$hybrid_lang/words.txt < data/test_hybrid/${postfix}/G_WRDPHNm_final.txt | fstarcsort --sort_type=ilabel > $hybrid_lang/G.fst
fi


if [ $stage -le 3 ]; then
  echo "make combined graph"
  utils/mkgraph.sh $hybrid_lang exp/nnet5a_clean_100_gpu exp/nnet5a_clean_100_gpu/graph_hybrid_${postfix}
fi

if [ $stage -le 4 ]; then
  echo "WER calculate on test set"
  #Note that it's normal if WER is slightly bigger in hybrid model, it's mostly due to insertions
  steps/nnet2/decode.sh --nj 20 --cmd "$decode_cmd" --transform-dir exp/tri4b/decode_tgsmall_test_clean exp/nnet5a_clean_100_gpu/graph_hybrid_${postfix} data/test_clean exp/nnet5a_clean_100_gpu/decode_test_hybrid_${postfix}
fi


