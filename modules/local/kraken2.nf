process KRAKEN2 {
    tag "${meta.id}"
    publishDir "$params.outdir/kraken2_results", mode: 'copy'
    errorStrategy 'retry'
    maxRetries 3
    // This is the default value for maxForks in Nextflow, but it's good to be explicit
    maxForks 1
    cpus 3

    container 'quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0'

    input:
    tuple val(meta), path(reads)
    path db

    output:
    tuple val(meta), path("*.kraken2"), emit: results
    tuple val(meta), path("*.kraken2_report"), emit: report

    script:
    def paired = reads instanceof List && reads.size() == 2
    def paired_flag = paired ? '--paired' : ''
    def input_reads = paired ? "${reads[0]} ${reads[1]}" : "${reads[0]}"
    """
    kraken2 --db $db \
        --memory-mapping \
        --minimum-hit-groups 3 \
        --use-names \
        --report-minimizer-data \
        --threads $task.cpus \
        $paired_flag \
        --report ${meta.id}.kraken2_report \
        --output ${meta.id}.kraken2 \
        $input_reads
    """
}