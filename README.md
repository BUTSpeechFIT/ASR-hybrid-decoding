# ASR-hybrid-decoding
This is an extension of kaldi speech recognition software which allows to perform decoding of speech with hybrid word and phoneme graphs. The output is a mix of in-vocabulary words and phoneme sequences. This decoding is suitable for systems with only a small dictionary available and for further recovery of OOV words.

For this to work you'll need kaldi speech recognition toolkit installed: https://github.com/kaldi-asr/kaldi

This expancion of kaldi was been tested on the following databases:
1) LibriSpeech https://github.com/kaldi-asr/kaldi/tree/master/egs/librispeech
2) Wall Street Journal https://github.com/kaldi-asr/kaldi/tree/master/egs/wsj

First run kaldi recepies and then on top of them you can run hybrid decoding as presented here.
