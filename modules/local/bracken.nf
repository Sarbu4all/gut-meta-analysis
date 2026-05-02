process BRACKEN {
    tag "${meta.id}"
    publishDir "$params.outdir/bracken_results", mode: 'copy'

    container 'quay.io/biocontainers/bracken:3.1--h9948957_0'

    input:
    tuple val(meta), path(kraken2_report)
    path db

    output:
    tuple val(meta), path("*.bracken")

    script:
    """
    bracken -d $db \
        -i ${kraken2_report} \
        -o ${meta.id}.bracken \
        -r 150 -l S
    """
}