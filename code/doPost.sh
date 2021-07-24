#!/bin/bash

#POSTPROCESS_SCRIPT=/home/socci/Code/Pipelines/CBE/Variant/PostProcessV3/doPostProcessV3.sh
POSTPROCESS_SCRIPT=/home/socci/Work/LUNA/Work/PostProcess/Mouse/Version5/PostProcess_V5-Mouse/doPostProcessV5.sh

function usage {
    echo "usage: doPost.sh [-f] [-p] [-d PROJECTDIR] pipelineOutputDir"
	echo "    -f turn on facets"
	echo "    -p turn off post"
	echo "    -d explicitly set projectDirectory"
}

# Default FACETS to NO
FACETS="NO"
POST="YES"

PROJECTDIR=""
while getopts "fpd:" opt; do
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

PIPELINEDIR=$1
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
	NUMDIRS=$(find /juno/projects/BIC/variant -type d | egrep -v "(drafts|archive)" | egrep "Proj_$projectNo$" | wc -l)
	PROJECTDIR=$(find /juno/projects/BIC/variant -type d | egrep -v "(drafts|archive)" | egrep "Proj_$projectNo$")
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

if [ "$POST" == "YES" ]; then
	mkdir -p $POSTDIR/post
	CWD=$PWD
	cd $POSTDIR/post
	bsub -o LSF.00.POST5/ -J POST_$$ -R "rusage[mem=32]" $LSF_TIME_LIMIT \
		$POSTPROCESS_SCRIPT
	cd $CWD
fi

#if [ "$FACETS" == "YES" ]; then
#	mkdir -p $POSTDIR/facets
#	CWD=$PWD
#	cd $POSTDIR/facets
#	~/Code/Pipelines/FACETS/FACETS.app/bProcess.sh $PIPELINEDIR $PROJECTDIR
#	cd $CWD
#fi
