# BIC@MSKCC M-IMPACT Pipeline: Output

## Introduction

### Directory Structure

```
ROOT/
├── metrics
├── post
├── project_files
└── variants
    └── snpsIndels
        ├── haplotect
        ├── haplotypecaller
        ├── mutect
        ├── mutect2
        ├── strelka
        └── vardict
```

### Post

These are the primary mutation call lists. They have the filtered annotated output.

### Matrics

The raw output of a number of metrics computed with the PICARD toolkit. The are summarized in the file: `Proj_15402_QC_Report.pdf` and for the individual metrics there are `.txt` files which are the raw output from PICARD.

### Project_files

The files used for running the pipeline. They contain the mapping data, pairing and grouping data.

### Variants

The folders here have the raw output of the various callers run in the pipeline. For the filtered results only the following callers are used: mutect, haplotype. But depending on the run there may be additional raw output included.


