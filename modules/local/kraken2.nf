process KRAKEN2 {
    tag "${meta.id}"
    publishDir "$params.outdir/kraken2_results", mode: 'copy'

    container 'quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0'

    input:
    tuple val(meta), path(reads)
    path db

    output:
    tuple val(meta), path("*.kraken2"), emit: results
    path "*.kraken2_report", emit: report

    script:
    """
    kraken2 --db $db \
        --threads $task.cpus \
        --report ${meta.id}.kraken2_report \
        --output ${meta.id}.kraken2 \
        ${reads[0]} ${reads[1]}
    """
}