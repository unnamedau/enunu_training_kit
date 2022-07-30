#!/bin/bash
# NOTE: the script is supposed to be used called from nnsvs recipes.
# Please don't try to run the shell script directry.

#------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2020 Ryuichi Yamamoto
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#------------------------------------------------------------------------------


if [ -d conf/train ]; then
    ext="--config-dir conf/train/timelag"
else
    ext=""
fi

if [ ! -z "${pretrained_expdir}" ]; then
    resume_checkpoint=$pretrained_expdir/timelag/best_loss.pth
else
    resume_checkpoint=
fi

# Hyperparameter search with Hydra + optuna
# mlflow is used to log the results of the hyperparameter search
if [[ ${timelag_hydra_optuna_sweeper_args+x} && ! -z $timelag_hydra_optuna_sweeper_args ]]; then
    hydra_opt="-m ${timelag_hydra_optuna_sweeper_args}"
    post_args="mlflow.enabled=true mlflow.experiment=${expname}_${timelag_model} hydra.sweeper.n_trials=${timelag_hydra_optuna_sweeper_n_trials}"
else
    hydra_opt=""
    post_args=""
fi

xrun $PYTHON_EXE -m nnsvs.bin.train $ext $hydra_opt \
    model=$timelag_model train=$timelag_train data=$timelag_data \
    data.train_no_dev.in_dir=$dump_norm_dir/$train_set/in_timelag/ \
    data.train_no_dev.out_dir=$dump_norm_dir/$train_set/out_timelag/ \
    data.dev.in_dir=$dump_norm_dir/$dev_set/in_timelag/ \
    data.dev.out_dir=$dump_norm_dir/$dev_set/out_timelag/ \
	data.in_scaler_path=$dump_norm_dir/in_timelag_scaler.joblib \
    data.out_scaler_path=$dump_norm_dir/out_timelag_scaler.joblib \
    train.out_dir=$expdir/timelag \
    train.resume.checkpoint=$resume_checkpoint $post_args
