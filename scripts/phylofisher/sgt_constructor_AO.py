#!/mnt/smart/scratch/emm2/aleix/miniforge3/envs/phylofisher/bin/python

import os
import subprocess
from pathlib import Path
from phylofisher import help_formatter
import configparser

SNAKEFILE_PATH = f'{os.path.dirname(os.path.realpath(__file__))}/sgt_constructor_AO.smk'


def get_initial_genes(input_dir):
    """
    Gets gene names from fasta files in the input directory.
    """
    return [
        os.path.splitext(f)[0]
        for f in os.listdir(input_dir)
        if f.endswith(('.fas', '.fasta', '.fa'))
    ]


def make_config(args):
    """
    Builds a Snakemake-compatible config string.
    All string values are quoted for safety.
    """
    genes_list = get_initial_genes(args.input)

    cfg = {
        "out_dir": args.output,
        "in_dir": args.input,
        "genes": ",".join(genes_list),
        "trees_only": args.trees_only,
        "no_trees": args.no_trees,
        "tree_colors": args.color_conf,
        "metadata": args.metadata,
        "input_metadata": args.input_metadata,
        "max_threads": args.threads // 5 if args.threads > 5 else 1,
    }

    return " ".join(
        f'{k}="{v}"' if isinstance(v, str) else f'{k}={v}'
        for k, v in cfg.items()
    )


def get_target_output(args):
    """
    Determines whether we explicitly request the tarball.
    """
    if args.no_trees:
        return None
    return f'{args.output}-local.tar.gz'


def run_snakemake(args):
    """
    Executes Snakemake in one continuous run.
    """
    smk_cmd = [
        "snakemake",
        f"-s {SNAKEFILE_PATH}",
        f"--config {make_config(args)}",
        f"--cores {args.threads}",
        "--rerun-incomplete",
        "--keep-going",
        "--nolock",
        "--use-conda",
    ]

    target = get_target_output(args)
    if target:
        smk_cmd.append(target)

    cmd = " ".join(smk_cmd)
    print(f"\nExecuting:\n{cmd}\n")

    subprocess.run(cmd, shell=True, executable="/bin/bash", check=False)


if __name__ == "__main__":
    description = "Aligns, trims, and builds single-gene trees in a parallelized pipeline."
    usage = "sgt_constructor.py -i path/to/input/ [OPTIONS]"

    parser, optional, required = help_formatter.initialize_argparse(
        name="sgt_constructor.py",
        desc=description,
        usage=usage,
    )

    # Optional arguments
    optional.add_argument(
        "-t", "--threads", metavar="N", type=int, default=1,
        help="Total threads for the whole machine (default: 1)"
    )
    optional.add_argument(
        "--no_trees", action="store_true",
        help="Length filtration and trimming only"
    )
    optional.add_argument(
        "--trees_only", action="store_true",
        help="Only build single-gene trees (currently unused in SMK)"
    )

    args = help_formatter.get_args(
        parser, optional, required, pre_suf=False, inp_dir=True
    )

    # Load paths from config.ini
    config_ini = configparser.ConfigParser()
    config_ini.read("config.ini")

    dfo = str(Path(config_ini["PATHS"]["database_folder"]).resolve())

    args.metadata = os.path.join(dfo, "metadata.tsv")
    args.color_conf = os.path.abspath(config_ini["PATHS"]["color_conf"])
    args.input_metadata = os.path.abspath(config_ini["PATHS"]["input_file"])

    args.input = args.input.rstrip("/")
    args.output = args.output.rstrip("/")

    run_snakemake(args)
