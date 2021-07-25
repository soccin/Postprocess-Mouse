#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
SVERSION=$(git --git-dir=$SDIR/../.git --work-tree=$SDIR describe --tags --dirty="-UNCOMMITED")
echo $SVERSION

export R_LIBS=/home/socci/lib/R/CentOS7/3.6.1
RSCRIPT=/opt/common/CentOS_7/R/R-3.6.1/bin/Rscript

. ../config

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

echo "HALT-41"

exit

# if [ ! -e ___FILLOUT.vcf ]; then
# echo "fillOutCBE::CFILL"
#     bsub -m commonHG ${JC_TIMELIMIT_CFILL} -o LSF.01.FILLOUT/ \
#       -J ${LSFTAG}_CFILL -n 24 -R "rusage[mem=22]" \
#         ~/Code/FillOut/FillOut/fillOutCBE.sh \
#           $BAMDIR maf0.txt ___FILLOUT.vcf
# fi

# echo "vcf2MultiMAF::FILL2"
# bsub -m commonHG ${JC_TIMELIMIT_LONG} -o LSF.02.FILL2VCF/ \
#     -J ${LSFTAG}_FILL2 -w "post_done(${LSFTAG}_CFILL)" \
#     -n 12 -R "rusage[mem=22]" \
#     $SDIR/vcf2MultiMAF.sh ___FILLOUT.vcf $BAM_GENOME


#######
# PostProcess BIC MAF
#
echo
echo "AddHeader..."
$SDIR/addHeaderTags.R IN=$MERGEDMAF OUT=post_01.maf RevisionTAG=$SVERSION
echo
echo "Collapse ..."
$SDIR/collapseNormalizedMAF.R IN=post_01.maf OUT=${PROJECTNO}_haplotect_VEP_MAF__PostV5.txt RevisionTAG=$SVERSION

#$SDIR/bSync ${LSFTAG}_FILL2
#cat ___FILLOUT.maf | awk -F"\t" '$5 !~ /GL/{print $0}' >${PROJECTNO}___FILLOUT.V5.txt
