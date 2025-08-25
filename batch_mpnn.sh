#!/usr/bin/env bash
#SBATCH --job-name=batch_mpnn
#SBATCH --account=ACCOUNT_CODE           
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2              
#SBATCH --gres=gpu:1                    
#SBATCH --mem=64G                      
#SBATCH --time=12:00:00                
#SBATCH --output=batch_mpnn_%j.out
#SBATCH --error=batch_mpnn_%j.err

# 1) Activate your conda env
# (replace "initMamba.sh" with your site’s init script if different)
source ~/initMamba.sh
conda activate mlfold

# 2) Make sure the output directory exists
# (example on BlaC run 1)
mkdir -p ~/BlaC/BlaC_1/BlaC_1_mpnn_out

# 3) Run the batch script on the test folder
cd ~

python mpnn_code/batch_mpnn_h5.py \
  BlaC/BlaC_1/pdb_frames \
  mpnn_code/ProteinMPNN/vanilla_model_weights \
  v_48_020 \
  BlaC/BlaC_1/BlaC_1_mpnn_out

