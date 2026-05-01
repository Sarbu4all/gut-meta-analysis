process KNEADDATA {
    tag "${meta.id}"
    container 'quay.io/biocontainers/kneaddata:0.12.1--pyhdfd78af_0'
    publishDir "${params.outdir}/kneaddata", mode: "copy"

    input:
    tuple val(meta), path(reads)
    path db

    output:
    tuple val(meta), path("kneaddata/*.fastq.gz"), emit: reads
    path "kneaddata/*.log", emit: log

    script:
    """
    kneaddata --input1 ${reads[0]} --input2 ${reads[1]} \
        --reference-db $db \
        --trimmomatic /usr/local/share/trimmomatic-0.39-2 \
        --remove-intermediate-output \
        --threads $task.cpus \
        --log kneaddata/${meta.id}.log \
        --output kneaddata

    gzip kneaddata/*.fastq
    """
}
