process KNEADDATA {
    tag "${meta.id}"
    container 'quay.io/biocontainers/kneaddata:0.12.1--pyhdfd78af_0'
    // Nextflow's local executor sizes concurrency against the host's RAM, which it
    // can see, not the container runtime's memory ceiling (e.g. Docker Desktop's VM),
    // which it can't. Bowtie2 decontamination against the human genome index peaks
    // around 3-3.5GB RSS per sample, so running several samples in parallel can
    // exceed a constrained VM and get OOM-killed. Serialize until memory is declared.
    maxForks 1

    input:
    tuple val(meta), path(reads)
    path db

    output:
    tuple val(meta), path("kneaddata/*.fastq.gz"), emit: reads
    path "kneaddata/*.log", emit: log

    script:
    """
    # /usr/local/share/trimmomatic-0.39-2 contains both the real trimmomatic.jar
    # and a same-named Java wrapper script ('trimmomatic'). KneadData's
    # 'trimmomatic*' glob can match the wrapper instead of the jar, which then
    # fails as "Invalid or corrupt jarfile". Point it at an isolated copy of
    # just the jar to remove the ambiguity.
    mkdir -p trimmomatic_jar
    cp /usr/local/share/trimmomatic-0.39-2/trimmomatic.jar trimmomatic_jar/

    kneaddata --input1 ${reads[0]} --input2 ${reads[1]} \
        --reference-db $db \
        --trimmomatic trimmomatic_jar \
        --remove-intermediate-output \
        --threads $task.cpus \
        --log kneaddata/${meta.id}.log \
        --output kneaddata

    gzip kneaddata/*.fastq
    """
}
