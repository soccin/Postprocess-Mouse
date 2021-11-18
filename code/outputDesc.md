There is a brief writeup of the various output files is attached below. In addition to the full pipeline output in the above folders attached is an excel file which has filtered mutation list to contain just those events that:

1. Are in the M-IMPACT (ver 2) target area; ie they in genes in the M-IMPACT assay

2. Are not in the latest version of dbSNP (ie annotated as novel)

3. Mutations that were _NOT_ seen in Normal control samples in this project.

4. Mutations which had variant allele frequences too large in either:

    - A set of control normal samples used to validate the assay

    - A set of pooled normal samples from previous runs

5. Mutations with tumor variant allele frequeces too low (<2%)

6. Mutations which did not have at least 8 reads that showed the mutation (AD>=8)

Note in particular filter (2) can miss potential pathogenic events. We are working to clean up dbSNP filtering but if you require more precise control of event filter you can get the full event MAF on the server.
