process BRACKEN {
    tag "${meta.id}"
    publishDir "$params.outdir/bracken_results", mode: 'copy'

    container 'quay.io/biocontainers/bracken:3.1--h9948957_0'

    input:
    tuple val(meta), path(kraken2_report)
    path db

    output:
    tuple val(meta), path("*.bracken"), emit: abundance
    tuple val(meta), path("*.bracken_report"), emit: report

    script:
    """
    bracken -d $db \
        -i ${kraken2_report} \
        -o ${meta.id}.bracken \
        -w ${meta.id}.bracken_report \
        -r 100 -l S
    """
}