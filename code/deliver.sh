#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ "" ]; then

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

else
    PROJECTNO=12345_AB
fi

cat << EOM
=====
Subject: Mouse IMPACT (${PROJECTNO}) results ready

The output for Mouse IMPACT ${PROJECTNO} are ready.

You can access them on the BIC Delivery server at:

  https://bicdelivery.mskcc.org/project/${PROJECTNO/Proj_/}/variants/r_001

EOM

#cat $SDIR/outputDesc.md

cat << EOM
If you require any further assistance let me know. If you are collaborating with a data-analyst in the CMO/Componc we can make the files directly available to them on the MSK cluster.

Nicholas Socci
Bioinformatics Core
MSKCC
socci@cbio.mskcc.org
EOM

