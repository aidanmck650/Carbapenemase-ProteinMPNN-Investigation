#!/usr/bin/env python3
import argparse
import subprocess
import os
import glob
import numpy as np
import h5py
import sys


def convert_npz_to_h5(npz_path, h5_group):
    data = np.load(npz_path)
    # Squeeze and slice off the padding token
    log_p = np.squeeze(data["log_p"], axis=0)[:, :20]  # (L,20)
    probs = np.exp(log_p)  # (L,20)
    n_residues = probs.shape[0]

    # Ensure the dataset exists
    if "frames" not in h5_group:
        # Create an extensible dataset: frames × residues × aa
        maxshape = (None, n_residues, 20)
        h5_group.create_dataset(
            "frames",
            shape=(0, n_residues, 20),
            maxshape=maxshape,
            dtype="f4",
            compression="gzip",
            chunks=(1, n_residues, 20),
        )
    ds = h5_group["frames"]

    # Append this frame
    ds.resize(ds.shape[0] + 1, axis=0)
    ds[-1, :, :] = probs


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Batch run ProteinMPNN and store outputs in HDF5"
    )
    parser.add_argument("pdb_folder",    help="Directory containing .pdb files")
    parser.add_argument("model_weights", help="Path to vanilla_model_weights directory")
    parser.add_argument("model_name",    help="ProteinMPNN model name (e.g. v_48_020)")
    parser.add_argument("output_root",   help="Directory to write HDF5 results")
    args = parser.parse_args()

    pdb_folder  = os.path.abspath(args.pdb_folder)
    weights_path= os.path.abspath(args.model_weights)
    output_root = os.path.abspath(args.output_root)
    os.makedirs(output_root, exist_ok=True)

    pdb_paths = sorted(glob.glob(os.path.join(pdb_folder, "*.pdb")))

    folder_name = os.path.basename(pdb_folder.rstrip(os.sep))
    # open one HDF5 for all frames
    h5_path = os.path.join(output_root, f"{folder_name}.h5")
    h5f = h5py.File(h5_path, "w")

    # Process each PDB
    for pdb_path in pdb_paths:
        base     = os.path.splitext(os.path.basename(pdb_path))[0]
        pdb_dir  = os.path.dirname(pdb_path)
        workdir  = os.path.join(output_root, base)
        os.makedirs(workdir, exist_ok=True)

        # 1) Run ProteinMPNN
        subprocess.check_call([
            sys.executable,
            os.path.join(os.path.dirname(__file__), "ProteinMPNN", "protein_mpnn_run.py"),
            "--pdb_path", os.path.basename(pdb_path),
            "--path_to_model_weights", weights_path,
            "--model_name", args.model_name,
            "--unconditional_probs_only", "1",
            # "--save_probs", "1",
            "--out_folder", workdir
        ], cwd=pdb_dir)

        # 2) locate the NPZ and append into the one HDF5 file
        npz_file = os.path.join(workdir, "unconditional_probs_only", f"{base}.npz")
        grp      = h5f.require_group("all")
        convert_npz_to_h5(npz_file, grp)

    h5f.close()
    print(f"All {len(pdb_paths)} frames stored in {h5_path}")
