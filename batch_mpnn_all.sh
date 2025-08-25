#!/usr/bin/env bash
#SBATCH --job-name=batch_mpnn_all
#SBATCH --account=ACCOUNT_CODE
#SBATCH --partition=gpu_short
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --time=06:00:00
#SBATCH --output=logs/batch_mpnn_%A_%a.out
#SBATCH --error=logs/batch_mpnn_%A_%a.err
#SBATCH --array=1-3

# 0) Ensure log directory exists
mkdir -p logs

# 1) Activate conda env
# (replace "initMamba.sh" with your site’s init script if different)
source ~/initMamba.sh
conda activate mlfold

# 2) Define enzyme directory
# (example on TEM1)
ENZYME="TEM1"

# 3) Compute which replicate this task is working on:
IDX=$SLURM_ARRAY_TASK_ID

# 4) Build paths from that
INPUT_FRAMES="./$ENZYME/${ENZYME}_${IDX}/pdb_frames"
WEIGHTS_DIR="./mpnn_code/ProteinMPNN/vanilla_model_weights"
OUTPUT_DIR="./$ENZYME/${ENZYME}_${IDX}/${ENZYME}_${IDX}_mpnn_out"

mkdir -p "$OUTPUT_DIR"

# 5) Run python command
python ~/mpnn_code/batch_mpnn_h5.py \
  "$INPUT_FRAMES" \
  "$WEIGHTS_DIR" \
  v_48_020 \
  "$OUTPUT_DIR"

