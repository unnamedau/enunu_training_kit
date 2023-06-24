#!/bin/bash

##########
# customized for Portable ENUNU Training Kit on Windows
##########
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

function xrun () {
    set -x
    $@
    set +x
}

# use embed python executional file
PYTHON_ROOT="python-3.8.10-embed-amd64"
PYTHON_EXE="python3.9"
PYTHON_SCRIPTS_ROOT="$PYTHON_ROOT/Scripts"
CONFIG_PATH="config.yaml"

script_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

# changed-----------------------------------------------
# NNSVS_ROOT="nnsvs"
# NNSVS_COMMON_ROOT="nnsvs/egs/_common/spsvs"
# . "$NNSVS_ROOT/utils/yaml_parser.sh" || exit 1;
# to----------------------------------------------------
NNSVS_SHELL_SCRIPTS_ROOT="nnsvs_shell_scripts"
. $NNSVS_SHELL_SCRIPTS_ROOT/yaml_parser.sh || exit 1;
# ------------------------------------------------------

eval $(parse_yaml $CONFIG_PATH "")

train_set="train_no_dev"
dev_set="dev"
eval_set="eval"
datasets=($train_set $dev_set $eval_set)
testsets=($dev_set $eval_set)

dumpdir=dump
dump_org_dir="$dumpdir/$spk/org"
dump_norm_dir="$dumpdir/$spk/norm"

stage=0
stop_stage=-1

# changed-----------------------------------------------
# . $NNSVS_ROOT/parse_options.sh || exit 1;
# to----------------------------------------------------
. $NNSVS_SHELL_SCRIPTS_ROOT/parse_options.sh || exit 1;
# ------------------------------------------------------

# exp name
if [ -z ${tag:=} ]; then
    expname="${spk}"
else
    expname="${spk}_${tag}"
fi
expdir="exp/$expname"


# Prepare files in singing-database for training
if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    echo "#########################################"
    echo "#                                       #"
    echo "#  stage 0: Data preparation            #"
    echo "#                                       #"
    echo "#########################################"
    rm -rf $out_dir
    rm -f preprocess_data.py.log
    python3.8 preprocess_data.py $CONFIG_PATH || exit 1;
    echo ""
fi


# Analyze .wav and .lab files
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 1: Feature generation           #"
    echo "#                                        #"
    echo "##########################################"
    rm -rf $dumpdir
    # changed-----------------------------------------------
    # . $NNSVS_COMMON_ROOT/feature_generation.sh || exit 1;
    # to----------------------------------------------------
    . $NNSVS_SHELL_SCRIPTS_ROOT/feature_generation.sh || exit 1;
    # ------------------------------------------------------
    echo ""
fi


# Train time-lag model
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 2: Time-lag model training      #"
    echo "#                                        #"
    echo "##########################################"
    # changed-----------------------------------------------
    # . $NNSVS_COMMON_ROOT/train_timelag.sh || exit 1;
    # to----------------------------------------------------
    . $NNSVS_SHELL_SCRIPTS_ROOT/train_timelag.sh || exit 1;
    # ------------------------------------------------------
    echo ""
fi


# Train duration model
if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 3: Duration model training      #"
    echo "#                                        #"
    echo "##########################################"
    # changed-----------------------------------------------
    # . $NNSVS_COMMON_ROOT/train_duration.sh || exit 1;
    # to----------------------------------------------------
    . $NNSVS_SHELL_SCRIPTS_ROOT/train_duration.sh || exit 1;
    # ------------------------------------------------------
    echo ""
fi


# Train acoustic model
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 4: Training acoustic model      #"
    echo "#                                        #"
    echo "##########################################"
    # changed-----------------------------------------------
    # . $NNSVS_COMMON_ROOT/train_acoustic.sh || exit 1;
    # to----------------------------------------------------
    . $NNSVS_SHELL_SCRIPTS_ROOT/train_acoustic.sh || exit 1;
    # ------------------------------------------------------
    echo ""
fi


# Generate models from timelag/duration/acoustic models
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 5: Feature generation           #"
    echo "#                                        #"
    echo "##########################################"
    # changed-----------------------------------------------
    # . $NNSVS_COMMON_ROOT/generate.sh || exit 1;
    # to----------------------------------------------------
    . $NNSVS_SHELL_SCRIPTS_ROOT/generate.sh || exit 1;
    # ------------------------------------------------------
    echo ""
fi

#
# # Synthesis wav files
# if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
#     echo "##########################################"
#     echo "#                                        #"
#     echo "#  stage 6: Waveform synthesis           #"
#     echo "#                                        #"
#     echo "##########################################"
#     . $NNSVS_COMMON_ROOT/synthesis.sh
#     echo ""
# fi
#

# Setup postfilter
if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 7: Prepare postfilter           #"
    echo "#                                        #"
    echo "##########################################"
    . $NNSVS_SHELL_SCRIPTS_ROOT/prepare_postfilter.sh || exit 1;
    echo ""
fi

# Train mgc postfilter
if [ ${stage} -le 8 ] && [ ${stop_stage} -ge 8 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 8: Training mgc postfilter      #"
    echo "#                                        #"
    echo "##########################################"
	postfilter_model="postfilter_mgc"
	postfilter_train="mgc"
    . $NNSVS_SHELL_SCRIPTS_ROOT/train_postfilter.sh || exit 1;
    echo ""
fi

# Train bap postfilter
if [ ${stage} -le 9 ] && [ ${stop_stage} -ge 9 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 9: Training bap postfilter      #"
    echo "#                                        #"
    echo "##########################################"
	postfilter_model="postfilter_bap"
	postfilter_train="bap"
    . $NNSVS_SHELL_SCRIPTS_ROOT/train_postfilter.sh || exit 1;
    echo ""
fi

# Merge postfilter models
if [ ${stage} -le 10 ] && [ ${stop_stage} -ge 10 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 10: Merge postfilter models     #"
    echo "#                                        #"
    echo "##########################################"
    python3.8 $NNSVS_SHELL_SCRIPTS_ROOT/merge_postfilters.py $expdir/postfilter_mgc/latest.pth $expdir/postfilter_bap/latest.pth $expdir/postfilter_merged || exit 1;
    echo ""
fi

# Copy the models to release directory
if [ ${stage} -le 99 ] && [ ${stop_stage} -ge 99 ]; then
    echo "##########################################"
    echo "#                                        #"
    echo "#  stage 99: Release preparation         #"
    echo "#                                        #"
    echo "##########################################"
    python3.8 prepare_release.py $CONFIG_PATH || exit 1;
    echo ""
fi
