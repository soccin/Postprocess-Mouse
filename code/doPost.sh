#!/bin/bash

set -e

#ROOT=""
ROOT=/rtsess01/compute/juno/bic

SDIR="$( cd "$( dirname "$0" )" && pwd )"

POSTPROCESS_SCRIPT=/home/socci/Work/LUNA/Work/PostProcess/Mouse/Version5/PostProcess_V5-Mouse/doPostProcessV5.sh

function usage {
    echo "usage: doPost.sh [-f] [-p] [-m MANIFEST] [-d PROJECTDIR] pipelineOutputDir"
	echo "    -m specify manifest file (tumor/normal assignments)"
	echo "    -d explicitly set projectDirectory"
}

PROJECTDIR=""
MANIFESTFILE=""
while getopts "fpd:m:" opt; do
	case $opt in
	f)
		echo "Turning FACETS _ON_"
		FACETS="YES"
		;;
	p)
		echo "Not running POST"
		POST="NO"
		;;
	d)
		PROJECTDIR=$OPTARG
		;;
	m)
		MANIFESTFILE="-m  $(realpath $OPTARG)"
		;;
	\?)
		usage;
		exit
	esac
done
shift $((OPTIND-1))

if [ "$#" != "1" ]; then
	usage
    exit
fi

SDIR="$( cd "$( dirname "$0" )" && pwd )"

PIPELINEDIR=$(realpath $ROOT/$1)
projectNo=$(echo $PIPELINEDIR | perl -ne 'm|/Proj_([^/\s]*)|; print $1')
runNo=$(echo $PIPELINEDIR | perl -ne 'm|/Proj_[^/\s]*/(r_\d+)|; print $1')


echo PIPELINEDIR=$PIPELINEDIR
echo projectNo=$projectNo
echo runNo=$runNo

if [ "$runNo" == "" ]; then
	echo "Invalid pipline directory "$PIPELINEDIR
	echo
	exit 1
fi

if [ "$PROJECTDIR" == "" ]; then
	NUMDIRS=$(find $ROOT/juno/projects/BIC/variant -type d | egrep -v "(drafts|archive)" | egrep "Proj_$projectNo$" | wc -l)
	PROJECTDIR=$(find $ROOT/juno/projects/BIC/variant -type d | egrep -v "(drafts|archive)" | egrep "Proj_$projectNo$")
	SCRIPT=$(basename $0)
	if [ "$NUMDIRS" != "1" ]; then
		echo $SCRIPT Problem finding project files for Proj_$projectNo
		echo NUMDIRS=$NUMDIRS
		echo
		echo $PROJECTDIR | tr ' ' '\n'
		echo
		echo
		usage
		exit 1
	fi
fi

echo PROJECTDIR=\"$PROJECTDIR\"
POSTDIR=Proj_$projectNo/$runNo

mkdir -p $POSTDIR
echo "PROJECTDIR="$PROJECTDIR >$POSTDIR/config
echo "PIPELINEDIR="$PIPELINEDIR >>$POSTDIR/config
echo "projectNo="$projectNo >>$POSTDIR/config

LSF_TIME_LIMIT="-W 59"

mkdir -p $POSTDIR/post
CWD=$PWD
cd $POSTDIR/post
#echo bsub -o LSF.00.POST5/ -J POST_$$ -R "rusage[mem=32]" $LSF_TIME_LIMIT

module load singularity/3.7.1
IMAGE=$SDIR/images/triassic_v1.0.1.sif

if [ ! -e $IMAGE ]; then
    echo -e "\n\n\tNeed to get image\n\n$IMAGE\n\n"
    echo "Check images folder for Dockerfile" 
    echo -e "\n\n"
fi

singularity exec \
	--bind /rtsess01:/rtsess01 \
	--bind /rtsess01/compute/juno/bic/juno:/juno \
	$IMAGE \
	$SDIR/postProcess.sh $MANIFESTFILE

cd $CWD
