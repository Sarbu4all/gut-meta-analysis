process KNEADDATA_READ_COUNTS {
    tag "all_samples"
    container 'quay.io/biocontainers/kneaddata:0.12.1--pyhdfd78af_0'
    publishDir "${params.outdir}/kneaddata", mode: "copy"

    input:
    path logs

    output:
    path "kneaddata_read_counts.txt", emit: txt

    script:
    """
    mkdir -p kneaddata_logs
    cp $logs kneaddata_logs/
    
    kneaddata_read_count_table --input kneaddata_logs \
        --output kneaddata_read_counts.txt
    """
}
