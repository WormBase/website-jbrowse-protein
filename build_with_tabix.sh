#!/bin/bash
# this is a simple test script for tabix indexing gff

set -e

RELEASE=280
while getopts r:s:a:k: option
do
case "${option}"
in
r) 
  RELEASE=${OPTARG}
  ;;
s) 
  SPECIES=${OPTARG}
  ;;
a)
  AWSACCESS=${OPTARG}
  ;;
k)
  AWSSECRET=${OPTARG}
  ;;
esac
done

if [ -z "$RELEASE" ]
then
    RELEASE=${WB_RELEASE}
fi

if [ -z "$SPECIES" ]
then
    SPECIES=${WB_SPECIES}
fi

if [ -z "$AWSACCESS" ]
then
    AWSACCESS=${AWS_ACCESS_KEY}
fi

if [ -z "$AWSSECRET" ]
then
    AWSSECRET=${AWS_SECRET_KEY}
fi

if [ -z "$AWSBUCKET" ]
then
    if [ -z "${AWS_S3_BUCKET}" ]
    then
        AWSBUCKET=agrjbrowse
    else
        AWSBUCKET=${AWS_S3_BUCKET}
    fi
fi

echo $PATH

wget  ftp://ftp.wormbase.org/pub/wormbase/releases/WS280/species/c_elegans/PRJNA13758/c_elegans.PRJNA13758.WS280.protein.fa.gz

gzip -d c_elegans.PRJNA13758.WS280.protein.fa.gz
bgzip c_elegans.PRJNA13758.WS280.protein.fa
samtools faidx c_elegans.PRJNA13758.WS280.protein.fa.gz

wget  ftp://ftp.wormbase.org/pub/wormbase/releases/WS280/species/c_elegans/PRJNA13758/c_elegans.PRJNA13758.WS280.protein_annotation.gff3.gz
gzip -d c_elegans.PRJNA13758.WS280.protein_annotation.gff3.gz

gt gff3 -tidy -sortlines -retainids c_elegans.PRJNA13758.WS280.protein_annotation.gff3 > c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 

#create individual GFF files per track
grep -P "\tintrinsically_unstructured_polypeptide_region\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > mobidb.gff
grep -P "\t(CDS|exon)\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > exon_boundaries.gff
grep -P "\tcompositionally_biased_region_of_peptide\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > seg.gff
grep -P "\tcoiled_coil\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > ncoils.gff
grep -P "\ttransmembrane_helix\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > tmhmm.gff
grep -P "\tsignal_peptide\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > signalp.gff
grep -P "\tmotif\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > motif.gff
grep -P "\tMass_spec_peptide\tmatch\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > massspec.gff
grep -P "\tcatalytic_residue\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > catalytic_residue.gff
grep -P "\tmetal_binding_site\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > metal_binding_site.gff
grep -P "\tpost_translationally_modified_region\t" c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3 > post_translationally_modified_region.gff

 bgzip  mobidb.gff; tabix  mobidb.gff.gz
 bgzip  exon_boundaries.gff; tabix  exon_boundaries.gff.gz
 bgzip  seg.gff; tabix  seg.gff.gz
 bgzip  ncoils.gff; tabix  ncoils.gff.gz
 bgzip  tmhmm.gff; tabix  tmhmm.gff.gz
 bgzip  signalp.gff; tabix  signalp.gff.gz
 bgzip  motif.gff; tabix  motif.gff.gz
 bgzip  massspec.gff; tabix  massspec.gff.gz
 bgzip  catalytic_residue.gff; tabix  catalytic_residue.gff.gz
 bgzip  metal_binding_site.gff; tabix  metal_binding_site.gff.gz
 bgzip  post_translationally_modified_region.gff; tabix  post_translationally_modified_region.gff.gz


#bgzip c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3
#tabix c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}

aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein.fa.gz s3://agrjbrowse/test/worm/c_elegans.PRJNA13758.WS280.protein.fa.gz
aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein.fa.gz.fai s3://agrjbrowse/test/worm/c_elegans.PRJNA13758.WS280.protein.fa.gz.fai
aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein.fa.gz.gzi s3://agrjbrowse/test/worm/c_elegans.PRJNA13758.WS280.protein.fa.gz.gzi
#aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz s3://agrjbrowse/test/c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz
#aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz.tbi s3://agrjbrowse/test/c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz.tbi

 

aws s3 cp --acl public-read  mobidb.gff.gz s3://agrjbrowse/test/worm/mobidb.gff.gz ; aws s3 cp --acl public-read  mobidb.gff.gz.tbi s3://agrjbrowse/test/worm/mobidb.gff.gz.tbi
aws s3 cp --acl public-read  exon_boundaries.gff.gz s3://agrjbrowse/test/worm/exon_boundaries.gff.gz ; aws s3 cp --acl public-read  exon_boundaries.gff.gz.tbi s3://agrjbrowse/test/worm/exon_boundaries.gff.gz.tbi
aws s3 cp --acl public-read  seg.gff.gz s3://agrjbrowse/test/worm/seg.gff.gz ; aws s3 cp --acl public-read  seg.gff.gz.tbi s3://agrjbrowse/test/worm/seg.gff.gz.tbi
aws s3 cp --acl public-read  ncoils.gff.gz s3://agrjbrowse/test/worm/ncoils.gff.gz ; aws s3 cp --acl public-read  ncoils.gff.gz.tbi s3://agrjbrowse/test/worm/ncoils.gff.gz.tbi
aws s3 cp --acl public-read  tmhmm.gff.gz s3://agrjbrowse/test/worm/tmhmm.gff.gz ; aws s3 cp --acl public-read  tmhmm.gff.gz.tbi s3://agrjbrowse/test/worm/tmhmm.gff.gz.tbi
aws s3 cp --acl public-read  signalp.gff.gz s3://agrjbrowse/test/worm/signalp.gff.gz ; aws s3 cp --acl public-read  signalp.gff.gz.tbi s3://agrjbrowse/test/worm/signalp.gff.gz.tbi
aws s3 cp --acl public-read  motif.gff.gz s3://agrjbrowse/test/worm/motif.gff.gz ; aws s3 cp --acl public-read  motif.gff.gz.tbi s3://agrjbrowse/test/worm/motif.gff.gz.tbi
aws s3 cp --acl public-read  massspec.gff.gz s3://agrjbrowse/test/worm/massspec.gff.gz ; aws s3 cp --acl public-read  massspec.gff.gz.tbi s3://agrjbrowse/test/worm/massspec.gff.gz.tbi
aws s3 cp --acl public-read  catalytic_residue.gff.gz s3://agrjbrowse/test/worm/catalytic_residue.gff.gz ; aws s3 cp --acl public-read  catalytic_residue.gff.gz.tbi s3://agrjbrowse/test/worm/catalytic_residue.gff.gz.tbi
aws s3 cp --acl public-read  metal_binding_site.gff.gz s3://agrjbrowse/test/worm/metal_binding_site.gff.gz ; aws s3 cp --acl public-read  metal_binding_site.gff.gz.tbi s3://agrjbrowse/test/worm/metal_binding_site.gff.gz.tbi
aws s3 cp --acl public-read  post_translationally_modified_region.gff.gz s3://agrjbrowse/test/worm/post_translationally_modified_region.gff.gz ; aws s3 cp --acl public-read  post_translationally_modified_region.gff.gz.tbi s3://agrjbrowse/test/worm/post_translationally_modified_region.gff.gz.tbi
