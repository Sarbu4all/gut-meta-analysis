# nf-core/gutmeta: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v25.10.4.11173 - 2026-08-17

Initial release of nf-core/gutmeta, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- KneadData quality trimming and host decontamination step
- Kraken2 taxonomic classification and Bracken abundance re-estimation steps
- `--kneaddata_db` / `--kraken2_db` parameters for reference database paths
- Bracken `--out-report` output (an updated Kraken-style report alongside the abundance table)
- `run_fetchngs.sh` helper script for downloading and formatting SRA/ENA read data

### `Fixed`

- KneadData: isolated the Trimmomatic jar to avoid a container packaging ambiguity that caused "Invalid or corrupt jarfile" failures
- KneadData: serialized execution (`maxForks 1`) to avoid Docker Desktop memory exhaustion under concurrent host-decontamination runs
- Kraken2: added the missing `--paired` flag so paired-end reads are classified as pairs instead of as independent single-end reads
- Kraken2: removed a `--confidence` threshold miscalibrated for this dataset's read length, which was causing near-total misclassification
- Kraken2: fixed a stray trailing space after a line-continuation backslash that broke the generated shell command
- `conf/test.config`: pointed the `test` profile at real, minimal FastQC/MultiQC test data instead of a different pipeline's samplesheet
- `run_fetchngs.sh`: pinned `NXF_SYNTAX_PARSER=v1` to work around a legacy-syntax incompatibility in `nf-core/fetchngs`
- Samplesheet generation: switched to relative FASTQ paths for portability across machines
- CI: replaced `nf-test.yml`'s self-hosted-runner-dependent sharded matrix with a working smoke test on standard GitHub-hosted runners
- Moved `publishDir` for local modules (KneadData, Kraken2, Bracken) into `conf/modules.config`, matching nf-core convention

### `Dependencies`

### `Deprecated`
