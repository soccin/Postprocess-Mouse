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

FACETSFILE=$POSTDIR/post/__Facets_PostV5.txt
if [ -e $FACETSFILE ]; then
    cp -v $FACETSFILE $PIPELINEDIR/post
else
    echo
    echo "FACETS File does not exists copying SOMATIC file"
    echo
    cp -v $POSTDIR/post/*_haplotect_VEP_MAF__PostV5.txt $PIPELINEDIR/post
fi

if [ -e "${PROJECTNO}_haplotect_VEP_MAF__PostV5.xlsx" ]; then
    echo "Copying XLSX MAF"
    cp -v ${PROJECTNO}_haplotect_VEP_MAF__PostV5.xlsx $PIPELINEDIR/post
fi

#cp -v $POSTDIR/post/Proj*___FILLOUT.V5.txt $PIPELINEDIR/post
#./postDeliver.sh $POSTDIR
