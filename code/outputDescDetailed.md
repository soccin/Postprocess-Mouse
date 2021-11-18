# Description of filtered MAF excel file

As part of the output of the pipeline is an excel file called:

`Proj_PROJNO_VEP_MAF__PostV6b_HQ.xlsx`

which contains several sheets:
- `maf_Filter8`
- `UnFilt_NonSilent`
- `cohortNormalFilter`
- `PARAMS`

The last sheet `PARAMS` is a listing of arguments and parameters used by the program that generated this file. It is mostly to track the version number and inputs used for reproducibility. The most useful fields are `TUMORS` which list the samples that were identified as tumor samples and `COHORT_NORMALS` which are the normals in this project.

The first of the three event sheets is: `maf_Filter8` which is a list of High Quality (HQ) mutations that were filtered from the full set of mutations. The filters used are:

- **TARGETED**: The mutation falls inside the M-IMPACT (version 2) target area. That is, it is in a gene that was targetted by the assay.

- **NOVEL**: The mutation is not in the latest version of Mouse `dbSNP`

- Note seen in any of a set of normals which includes:

    - Not **present in cohort normals**: The mutation is not seen in any of the normal samples in this project.

    - Not **present in control samples**: The variant allele frequency of the mutation in a set of control normals is below a set threshold compared to the tumor's variant frequency.

    - Not **present in pooled samples**: Similar to the previous case but using a different set of normals; the pooled normals used as part of the assay.

- Allele depth >= 8 reads and a Tumor variant allelel frequence greater than two percent (VAF>=0.02)

- **Non-Silent**: The mutation either changes the Amino Acid sequence or targets a splice region. Ie, the mution is not _silent_

Only mutations that pass **ALL** of these filters is in the first sheet.

The second sheet: `UnFilt_NonSilent` contains any mutation that is simply _not_ silent. So mutations that are non-targetted, non-novel (seen in dbSNP) and/or potentially seen in one of the normals are on this list. It obviously is likely to contain lots of false positive but will have a way lower false negative rate than the first.

Finaly the sheet: `cohortNormalFilter` list mutations that were filtered out by the cohort normal filter. If the _normals_ in this project are not really normals this filter may also remove potentially important or interesting events so they are listed here.

