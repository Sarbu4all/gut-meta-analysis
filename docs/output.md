# nf-core/gutmeta: Output

## Introduction

This document describes the files and reports produced by the **nf-core/gutmeta** pipeline.
The pipeline writes results to the directory specified by `--outdir` (default: `results/`). Output files are organized by analysis stage so that quality-control, host-contamination, taxonomic-profiling, and pipeline-execution results can be inspected independently.

## Pipeline overview

The pipeline produces the following major outputs:

1. **Raw-read quality control** - FastQC
2. **Raw-read QC aggregation** - MultiQC
3. **Quality filtering and host-read removal** — KneadData
4. **Post-processing quality control** — FastQC
5. **Taxonomic classification** — Kraken2
6. **Taxonomic abundance estimation** — Bracken
7. **Pipeline execution reports and software provenance** — Nextflow

All paths below are relative to the pipeline output directory.

---

## FastQC

FastQC is run on the raw sequencing reads and on the filtered paired reads retained after KneadData processing.

### Output files

```text
fastqc/
├── raw/
│   ├── *_fastqc.html
│   └── *_fastqc.zip
└── clean/
    ├── *_fastqc.html
    └── *_fastqc.zip
```
## MultiQC

MultiQC aggregates quality-control results across samples and produces an interactive HTML report.

### Output files

```text
multiqc/
├── raw/
│   ├── multiqc_report.html
│   ├── multiqc_data/
│   └── multiqc_plots/
└── clean/
    ├── multiqc_report.html
    ├── multiqc_data/
    └── multiqc_plots/
```

## KneadData

KneadData performs quality filtering and host-read removal before downstream taxonomic profiling.

### Output files

```text
kneaddata/
└── kneaddata/
    ├── *.fastq.gz
    └── *.log

```

## Kraken2

Kraken2 performs k-mer-based taxonomic classification of the cleaned sequencing reads.

### Output files

```text
kraken2_results/
├── <sample>.kraken2
└── <sample>.kraken2_report
```

## Bracken

Bracken estimates taxonomic abundance from Kraken2 classification reports.

### Output files
```text
bracken_results/
└── <sample>.bracken
```

## Pipeline information

Nextflow generates execution and provenance information under:

### Output files

```text
pipeline_info/
├── execution_report_*.html
├── execution_timeline_*.html
├── execution_trace_*.txt
├── pipeline_dag_*.html
└── nf_core_gutmeta_software_mqc_versions.yml
```
