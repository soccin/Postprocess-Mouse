#!/bin/bash

POSTDIR=$1

if [ ! -e $POSTDIR/config ]; then
    echo "FATAL ERROR missing config file"
    echo "not a valid post directory"
    echo
    exit
fi

PROJECTNO=$(echo $POSTDIR | perl -ne 'm|(Proj_.*?)/|; print $1')
echo $PROJECTNO

. $POSTDIR/config

echo
echo "  Remeber you need to sudo here because of permissions"
echo

sudo mkdir -p $PIPELINEDIR/post
sudo chmod -R g+w $PIPELINEDIR/post

cp -v $POSTDIR/post/*_VEP_MAF__PostV6b.txt $PIPELINEDIR/post
cp -v $POSTDIR/post/*_VEP_MAF__PostV6b_HQ.xlsx $PIPELINEDIR/post

cat << EOM
=====
Subject: Mouse IMPACT (${PROJECTNO}) results ready

The output for Mouse IMPACT ${PROJECTNO} are ready.

You can access them on the BIC Delivery server at:

  https://bicdelivery.mskcc.org/project/${PROJECTNO/Proj_/}/variants/r_001

There is a brief writeup of the various output files is attached below. In addition to the full pipeline output in the above folders attached is an excel file which has filtered mutation list echo to contain just those events that:

    (1) Will change the protein sequence (mis/non-sense, splice-site)

    (2) Are not in the latest version of dbSNP (ie annotated as novel)

    (3) Mutations that were seen in any strain/litter-mate control samples.

    (4) Mutations that have significant counts in a library of control samples

Note in particular filter (2) can miss potential pathogenic events. We are working to clean up dbSNP filtering but if you require more precise control of event filter you can get the full event MAF on the server.

If you require any further assistance let me know. If you are collaborating with a data-analyst in the CMO/Componc we can make the files directly available to them on the MSK cluster.

Nicholas Socci
Bioinformatics Core
MSKCC
socci@cbio.mskcc.org
EOM

