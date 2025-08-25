#!/usr/bin/env bash
#SBATCH --job-name=extract_frames_all
#SBATCH --output=extract_frames_all.%j.out
#SBATCH --error=extract_frames_all.%j.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --account=ACCOUNT_CODE

module load apps/amber/24.tools.24

# 1) Set where the shared inputs live, and where to dump your PDBs:
INPUT_DIR="./input"
OUTPUT_DIR="./output/pdb_frames"

mkdir -p "$OUTPUT_DIR"

# 2) Dynamically build your cpptraj input
cat > extract_frames.in <<EOF
parm ${INPUT_DIR}/system.parm7
trajin ${INPUT_DIR}/prod.nc 1 5000 1

strip :WAT,Cl-,Na+
strip !@N,CA,C,O,CB
autoimage

trajout ${OUTPUT_DIR}/frame pdb multi pdb nobox

go
EOF

# 3) Run cpptraj from the directory
cpptraj -i extract_frames.in

# 4) Post-process (renaming & residue/chain fixes)
cd "$OUTPUT_DIR"

# 4.1 Rename frame.N → frame_N.pdb
for f in frame.*; do
  num=${f#frame.}                  
  mv -- "$f" "frame_${num}.pdb"
done

# 4.2 Change MER → SER in columns 18–20
for f in frame_*.pdb; do
  sed -i 's/\(^.\{17\}\)MER/\1SER/' "$f"
  sed -i 's/^\(.\{21\}\).\{1\}/\1A/' "$f"
done
