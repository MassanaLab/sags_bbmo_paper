import os
from Bio import SeqIO

# --- Configuration & Variables ---
out_dir = config['out_dir']
in_dir = config['in_dir']
genes = config['genes'].split(',')
trees_only = config['trees_only']
no_trees = config['no_trees']
tree_colors = config['tree_colors']
metadata = config['metadata']
input_metadata = config['input_metadata']

THREADS_MAX = config.get('max_threads', 8)

# --- Workflow Rules ---

rule all:
    input:
        f'{out_dir}-local.tar.gz' if not no_trees else expand(f'{out_dir}/trimal/{{gene}}.final', gene=genes)

rule rm_star_gaps:
    input: f'{in_dir}/{{gene}}.fas'
    output: f'{out_dir}/prequal/{{gene}}.aa'
    run:
        with open(output[0], 'w') as res:
            for record in SeqIO.parse(input[0], 'fasta'):
                res.write(f'>{record.name}\n{str(record.seq).replace("-", "").replace("*", "")}\n')

rule prequal:
    input: f'{out_dir}/prequal/{{gene}}.aa'
    output: f'{out_dir}/prequal/{{gene}}.aa.filtered'
    log: f'{out_dir}/logs/prequal/{{gene}}.log'
    shell: 'prequal {input} >{log} 2>{log}'

rule length_filter_mafft:
    input: f'{out_dir}/prequal/{{gene}}.aa.filtered'
    output: f'{out_dir}/length_filtration/mafft/{{gene}}.aln'
    log: f'{out_dir}/logs/length_filter_mafft/{{gene}}.log'
    threads: THREADS_MAX
    shell: 'mafft --thread {threads} --globalpair --maxiterate 1000 --unalignlevel 0.6 {input} >{output} 2>{log}'

rule length_filter_divvier:
    input: f'{out_dir}/length_filtration/mafft/{{gene}}.aln'
    output:
        f'{out_dir}/length_filtration/divvier/{{gene}}.aln.partial.fas',
        f'{out_dir}/length_filtration/divvier/{{gene}}.aln.PP'
    log: f'{out_dir}/logs/length_filter_divvier/{{gene}}.log'
    shell:
        '''
        divvier -mincol 4 -partial {input} >{log} 2>{log}
        mv {out_dir}/length_filtration/mafft/{wildcards.gene}.aln.partial.fas {out_dir}/length_filtration/divvier/
        mv {out_dir}/length_filtration/mafft/{wildcards.gene}.aln.PP {out_dir}/length_filtration/divvier/
        '''

rule x_to_dash:
    input: f'{out_dir}/length_filtration/divvier/{{gene}}.aln.partial.fas'
    output: f'{out_dir}/length_filtration/bmge/{{gene}}.pre_bmge'
    run:
        with open(output[0], 'w') as res:
            for record in SeqIO.parse(input[0], 'fasta'):
                res.write(f'>{record.name}\n{str(record.seq).replace("X", "-")}\n')

rule length_filter_bmge:
    input: f'{out_dir}/length_filtration/bmge/{{gene}}.pre_bmge'
    output: f'{out_dir}/length_filtration/bmge/{{gene}}.bmge'
    log: f'{out_dir}/logs/length_filter_bmge/{{gene}}.log'
    shell: 'bmge -t AA -g 0.3 -i {input} -of {output} >{log} 2>&1'

rule length_filtration:
    input: f'{out_dir}/length_filtration/bmge/{{gene}}.bmge'
    output: f'{out_dir}/length_filtration/bmge/{{gene}}.length_filtered'
    params: threshold=0.5
    log: f'{out_dir}/logs/length_filtration/{{gene}}.log'
    run:
        with open(output[0], 'w') as outfile:
            for record in SeqIO.parse(input[0], 'fasta'):
                coverage = len(str(record.seq).replace('-', '').replace('X', '')) / len(record.seq)
                if coverage > params.threshold:
                    outfile.write(f'>{record.description}\n{record.seq}\n')

rule mafft:
    input: f'{out_dir}/length_filtration/bmge/{{gene}}.length_filtered'
    output: f'{out_dir}/mafft/{{gene}}.aln'
    log: f'{out_dir}/logs/mafft/{{gene}}.log'
    threads: THREADS_MAX
    shell: 'mafft --thread {threads} --globalpair --maxiterate 1000 --unalignlevel 0.6 {input} >{output} 2>{log}'

rule divvier:
    input: f'{out_dir}/mafft/{{gene}}.aln'
    output:
        f'{out_dir}/divvier/{{gene}}.aln.partial.fas',
        f'{out_dir}/divvier/{{gene}}.aln.PP'
    log: f'{out_dir}/logs/divvier/{{gene}}.log'
    shell:
        '''
        divvier -mincol 4 -partial {input} >{log} 2>{log}
        mv {out_dir}/mafft/{wildcards.gene}.aln.partial.fas {out_dir}/divvier/
        mv {out_dir}/mafft/{wildcards.gene}.aln.PP {out_dir}/divvier/
        '''

rule trimal:
    input: f'{out_dir}/divvier/{{gene}}.aln.partial.fas'
    output: f'{out_dir}/trimal/{{gene}}.trimal'
    log: f'{out_dir}/logs/trimal/{{gene}}.log'
    shell: 'trimal -in {input} -gt 0.01 -out {output} >{log} 2>{log}'

rule remove_gaps:
    input: f'{out_dir}/trimal/{{gene}}.trimal'
    output: f'{out_dir}/trimal/{{gene}}.final'
    run:
        records = [r for r in SeqIO.parse(input[0], 'fasta') if len(str(r.seq).replace('-', '').replace('X','')) > 0]
        SeqIO.write(records, output[0], "fasta")

rule raxml:
    input: f'{out_dir}/trimal/{{gene}}.final'
    output:
        f'{out_dir}/raxml/{{gene}}.raxml.support',
        f'{out_dir}/raxml/{{gene}}.raxml.log'
    log: f'{out_dir}/logs/raxml/{{gene}}.log'
    params: raxml_out=f'{out_dir}/raxml'
    threads: THREADS_MAX
    shell:
        'raxml-ng --all --msa {input} --prefix {params.raxml_out}/{wildcards.gene} '
        '--model LG4X+G4 --tree pars{{10}} --bs-trees 100 --force --threads {threads} >{log} 2>{log}'

rule cp_trees:
    input:
        trimmed = f'{out_dir}/length_filtration/bmge/{{gene}}.length_filtered',
        final = f'{out_dir}/trimal/{{gene}}.final',
        support = f'{out_dir}/raxml/{{gene}}.raxml.support'
    output:
        t2 = f'{out_dir}-local/trees/{{gene}}.trimmed',
        f2 = f'{out_dir}-local/trees/{{gene}}.final',
        s2 = f'{out_dir}-local/trees/{{gene}}.raxml.support'
    shell:
        '''
        mkdir -p {out_dir}-local/trees
        cp {input.trimmed} {output.t2}
        cp {input.final} {output.f2}
        cp {input.support} {output.s2}
        '''

rule cp_metadata:
    input: tree_colors, metadata, input_metadata
    output:
        f'{out_dir}-local/tree_colors.tsv',
        f'{out_dir}-local/metadata.tsv',
        f'{out_dir}-local/input_metadata.tsv'
    shell: "cp {input[0]} {output[0]}; cp {input[1]} {output[1]}; cp {input[2]} {output[2]}"

rule tar_local_dir:
    input:
        expand(
            f'{out_dir}-local/trees/{{gene}}.{{ext}}',
            gene=genes,
            ext=['trimmed', 'final', 'raxml.support']
        ),
        f'{out_dir}-local/tree_colors.tsv',
        f'{out_dir}-local/metadata.tsv',
        f'{out_dir}-local/input_metadata.tsv'
    output:
        f'{out_dir}-local.tar.gz'
    log:
        f'{out_dir}/logs/tar_local_dir.log'
    params:
        out_dir_base=f'{out_dir}-local'
    shell:
        '''
        tar -czvf {output} {params.out_dir_base} >{log} 2>{log}
        rm -rf {params.out_dir_base}
        '''
