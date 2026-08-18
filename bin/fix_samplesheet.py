#!/usr/bin/env python3
"""
fix_samplesheet.py
------------------
Converts a nf-core/fetchngs samplesheet (which contains relative FASTQ paths
and possibly padded/quoted field names) into a clean 3-column samplesheet with
paths relative to the project root directory suitable for the gutmeta pipeline.

Usage:
    python3 fix_samplesheet.py <input_samplesheet> <fastq_dir> <output_samplesheet>

Arguments:
    input_samplesheet   Path to the fetchngs-produced samplesheet.csv
    fastq_dir           Relative path to the directory containing downloaded FASTQ files
    output_samplesheet  Path to write the cleaned samplesheet
"""

import csv
import os
import sys

def clean_key(k: str) -> str:
    """Strip surrounding whitespace and stray quote characters from a field name."""
    return k.strip().strip('"').strip()

def fix_path(raw_path: str, fastq_dir: str) -> str:
    """
    Extract the filename from the raw path and join it with the actual fastq directory.
    """
    cleaned = raw_path.strip().strip('"').strip()
    if not cleaned:
        return ""

    # Just take the filename and place it in our known fastq directory
    filename = os.path.basename(cleaned)
    return os.path.normpath(os.path.join(fastq_dir, filename))

def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)

    input_samplesheet  = sys.argv[1]
    fastq_dir          = sys.argv[2]
    output_samplesheet = sys.argv[3]

    if not os.path.isfile(input_samplesheet):
        sys.exit(f"ERROR: Input samplesheet not found: {input_samplesheet}")

    if not os.path.isdir(fastq_dir):
        print(f"WARNING: FASTQ directory not found: {fastq_dir}", file=sys.stderr)

    rows_written = 0

    with open(input_samplesheet, encoding="utf-8-sig", newline="") as infile, \
         open(output_samplesheet, "w", newline="\n") as outfile:

        reader = csv.DictReader(infile)
        reader.fieldnames = [clean_key(f) for f in reader.fieldnames]

        writer = csv.DictWriter(outfile, fieldnames=["sample", "fastq_1", "fastq_2"])
        writer.writeheader()

        for row in reader:
            clean_row = {clean_key(k): v.replace("\r", "") if v else v for k, v in row.items()}

            fastq_1 = fix_path(clean_row.get("fastq_1", ""), fastq_dir)
            fastq_2 = fix_path(clean_row.get("fastq_2", ""), fastq_dir)

            for label, path in [("fastq_1", fastq_1), ("fastq_2", fastq_2)]:
                if path and not os.path.isfile(path):
                    print(f"WARNING: {label} file not found: {path}", file=sys.stderr)

            writer.writerow({
                "sample":  clean_row["sample"].strip().strip('"'),
                "fastq_1": fastq_1,
                "fastq_2": fastq_2,
            })
            rows_written += 1

    print(f"Wrote {rows_written} sample(s) to: {output_samplesheet}")

if __name__ == "__main__":
    main()
