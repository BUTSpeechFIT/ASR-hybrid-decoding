# ASR-hybrid-decoding
This is an extension of kaldi speech recognition software which allows to perform decoding of speech with hybrid word and phoneme graphs. The output is a mix of in-vocabulary words and phoneme sequences. This decoding is suitable for systems with only a small dictionary available and for further recovery of OOV words. 

## Theory:

Brief description of the hybrid decoding system can be found in a [paper](http://www.fit.vutbr.cz/research/groups/speech/publi/2018/egorova_icassp2018_0005919.pdf) and generally follows an approach in an [earlier paper](http://www.fit.vutbr.cz/research/groups/speech/publi/2008/szoke_sigir2008.pdf)

## Requirements:

For this to work you'll need [kaldi speech recognition toolkit](https://github.com/kaldi-asr/kaldi) installed

This expansion of kaldi was been tested on the following databases:
1) [LibriSpeech](https://github.com/kaldi-asr/kaldi/tree/master/egs/librispeech)
2) [Wall Street Journal](https://github.com/kaldi-asr/kaldi/tree/master/egs/wsj)

## How to run:

First run kaldi recipies and then on top of them you can run hybrid decoding as presented here. The file structure in this repository is the same as kaldi file structure, so it suffices to copy scripts from this repository to corresponding folders in your kaldi system build. After that, run run_hybrid_decoding.sh script, which will build the hybrid decoding graph and perform the decofing.

## LibriSpeech setup:

OOV_list_1000.txt has a selection of 1000 words to perform as OOVs for this database. For a detailed description of how they were chosen, see subsection 3.1 in [paper](http://www.fit.vutbr.cz/research/groups/speech/publi/2018/egorova_icassp2018_0005919.pdf)
