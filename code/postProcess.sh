#!/bin/bash

export SDIR="$( cd "$( dirname "$0" )" && pwd )"
SVERSION=$(git --git-dir=$SDIR/../.git describe --tags --always --long)
echo $SVERSION

export R_LIBS=/home/socci/lib/R/CentOS7/3.6.1
RSCRIPT=/opt/common/CentOS_7/R/R-3.6.1/bin/Rscript

. ../config

MANIFESTFILE=""
while getopts "fpd:m:" opt; do
    case $opt in
    m)
        MANIFESTFILE="MANIFEST=$OPTARG"
        ;;
    \?)
        usage;
        exit
    esac
done
shift $((OPTIND-1))

LSFTAG=$(uuidgen)

PROJECTNO=$(echo $PROJECTDIR | perl -ne 'm|(Proj_[^/]*)|; print $1')
echo PROJECTNO=$PROJECTNO

MERGEDMAF=$PIPELINEDIR/variants/snpsIndels/haplotect/${PROJECTNO}_haplotect_VEP_MAF.txt

BAMDIR=$PIPELINEDIR/alignments
BAM1=$(ls $BAMDIR/*.bam | head -1)

MAF_GENOME=$(head $MERGEDMAF  | tail -1 | cut -f4)
BAM_GENOME=$(~/Code/FillOut/FillOut/GenomeData/getGenomeBuildBAM.sh $BAM1)

if [ "$MAF_GENOME" != "$BAM_GENOME" ]; then
    echo
    echo "Mismatch in MAF($MAF_GENOME)/BAM($BAM_GENOME) genomes"
    if [ "$MAF_GENOME" == "GRCm38" ]; then
        echo "Fixing chromosome names"
        $SDIR/fixChromosomesToUCSC.R IN=$MERGEDMAF OUT=maf0.txt
    else
        echo
        echo
        exit -1
    fi
else
    ln -s $MERGEDMAF maf0.txt
fi
echo

#######
# PostProcess BIC MAF
#
echo
echo "#####"
echo "Filter targetted events"
$SDIR/filterToTargets $SDIR/../resources/M-IMPACT_v1_mm10_targets.bed.gz maf0.txt maf1.txt
echo

echo
echo "#####"
echo "Get fillout"
Rscript --no-save /juno/home/socci/Code/FillOut/FillOut21/makeMinimalMaf.R maf1.txt
ls $BAMDIR/*bam >bamList
cat bamList | sed 's/.*_s_/s_/' | sed 's/.bam//' >sids
paste sids bamList >bam_fof
cat \
    $SDIR/../resources/mouseControlSamples_210724.txt \
    $SDIR/../resources/mousePooledNormalBams_210724.txt \
    >>bam_fof

/juno/home/socci/Code/FillOut/FillOut21/bin/GetBaseCountsMultiSample \
    --thread 24 \
    --filter_improper_pair 0 \
    --fasta /juno/depot/assemblies/M.musculus/mm10/mm10.fasta \
    --maf maf1_minMaf.maf \
    --output minimaFillOut.out \
    --bam_fof bam_fof

echo
echo "#####"
echo "AddNormalFillData"
$SDIR/addNormalFillData maf1.txt minimaFillOut.out maf2.txt
echo

echo
echo "#####"
echo "makeFinalMAF"
$SDIR/makeFinalMAF $MANIFESTFILE maf2.txt
echo

# echo
# echo "Collapse ..."
# $SDIR/collapseNormalizedMAF.R IN=post_01.maf OUT=${PROJECTNO}_haplotect_VEP_MAF__PostV5.txt RevisionTAG=$SVERSION

#$SDIR/bSync ${LSFTAG}_FILL2
#cat ___FILLOUT.maf | awk -F"\t" '$5 !~ /GL/{print $0}' >${PROJECTNO}___FILLOUT.V5.txt

