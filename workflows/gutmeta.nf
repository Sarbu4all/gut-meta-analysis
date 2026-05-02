/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { KNEADDATA                } from '../modules/local/kneaddata'
include { KNEADDATA_READ_COUNTS    } from '../modules/local/kneaddata_read_counts'
include { FASTQC as FASTQC_RAW     } from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_CLEAN   } from '../modules/nf-core/fastqc/main'
include { MULTIQC as MULTIQC_RAW   } from '../modules/nf-core/multiqc/main'
include { MULTIQC as MULTIQC_CLEAN } from '../modules/nf-core/multiqc/main'
include { KRAKEN2                  } from '../modules/local/kraken2'
include { BRACKEN                  } from '../modules/local/bracken'
include { paramsSummaryMap         } from 'plugin/nf-schema'
include { paramsSummaryMultiqc     } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_gutmeta_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GUTMETA {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()
    // ----------------------------------------------------------------------------------------------------------------
    // STEP 1: Run FastQC on raw reads
    // ----------------------------------------------------------------------------------------------------------------
    FASTQC_RAW(ch_samplesheet)

    // ----------------------------------------------------------------------------------------------------------------
    // STEP 2: MultiQC report on raw reads
    // ----------------------------------------------------------------------------------------------------------------
    MULTIQC_RAW(
        FASTQC_RAW.out.zip
            .map { _meta, file -> file }
            .flatten()
            .collect()
            .map { files ->
                [
                    [id: 'gutmeta_raw'],
                    files,
                    multiqc_config
                        ? file(multiqc_config, checkIfExists: true)
                        : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                    multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                    [],
                    [],
                ]
            }
    )

    // -------------------------------------------------------------------------
    // STEP 3: KneadData — quality trimming & host decontamination
    // -------------------------------------------------------------------------
    ch_kneaddata_db = params.kneaddata_db ? channel.fromPath(params.kneaddata_db).first() : channel.empty()
    KNEADDATA(ch_samplesheet, ch_kneaddata_db)
    KNEADDATA_READ_COUNTS(KNEADDATA.out.log.collect())

    // -------------------------------------------------------------------------
    // STEP 4: FastQC on KneadData-cleaned reads (paired reads only)
    // -------------------------------------------------------------------------
    def ch_clean_reads = KNEADDATA.out.reads
        .map { meta, fastqs ->
            def paired = fastqs instanceof List ? fastqs : [fastqs]
            def paired_clean = paired.findAll { f -> f.name =~ /.*_kneaddata_paired_[12]\.fastq\.gz$/ }
            tuple(meta, paired_clean)
        }
    FASTQC_CLEAN(ch_clean_reads)

    // -------------------------------------------------------------------------
    // STEP 5: Kraken2 Taxonomic Profiling
    // -------------------------------------------------------------------------
    ch_kraken2_db = params.kraken2_db ? channel.fromPath(params.kraken2_db).first() : channel.empty()
    KRAKEN2(ch_clean_reads, ch_kraken2_db)

    // -------------------------------------------------------------------------
    // STEP 6: Bracken Taxonomic Profiling
    // -------------------------------------------------------------------------
    BRACKEN(KRAKEN2.out.report, ch_kraken2_db)

    // -------------------------------------------------------------------------
    // STEP 7: Collate software versions for the final MultiQC report
    // -------------------------------------------------------------------------
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by: 0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:     'nf_core_gutmeta_software_mqc_versions.yml',
            sort:     true,
            newLine:  true
        )

    // -------------------------------------------------------------------------
    // STEP 7: MultiQC report on cleaned reads (+ pipeline metadata)
    // -------------------------------------------------------------------------
    def ch_summary_params     = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary   = channel.value(paramsSummaryMultiqc(ch_summary_params))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))

    def ch_multiqc_clean_files = FASTQC_CLEAN.out.zip
        .map { _meta, file -> file }
        .mix(KNEADDATA.out.log)
        //.mix(ch_collated_versions)
        //.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml', storeDir: "${outdir}/pipeline_info"))
        //.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', storeDir: "${outdir}/pipeline_info", sort: true))

    MULTIQC_CLEAN(
        ch_multiqc_clean_files.flatten().collect().map { files ->
            [
                [id: 'gutmeta_clean'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )

    emit:
    multiqc_report = MULTIQC_CLEAN.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions 
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
