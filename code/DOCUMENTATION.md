# M-IMPACT Post Processing

## Version 2

## Final MAF file output

- `tVarFreqP`: Variant Frequency of mutation with pseudo counts added:
    ```
        tVarFreqP = (t_alt_count+1)/(t_depth+2)
    ```
    To handle the case where the `t_depth=0` or `t_depth=t_alt_count` we add a pseudo counts to the various counts. This keeps the variant frequence and the logs odds finite (ie no n/0 problems)


- `AllNormal_tAD`: Total alternative allele depth (AD) for _all_ normal samples; normal pools plus normal controls.
    ```
        AllNormal_tAD = Normal_CTRLS_tAD + POOL_tAD
    ```

    Where `Normal_CTRLS_tAD` is the total AD for all the samples in the control set and `POOL_tAD` is the total AD for all the normal pool samples.

- `AllNormal_tFreqP`: pseudo count corrected variant frequency for sum of all normal samples (pools + control set).
    ```
        AllNormal_tFreqP=(AllNormal_tAD+1)/(AllNormal_tDP+2)
    ```
