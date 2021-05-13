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

bgzip c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3
tabix c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz


aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein.fa.gz s3://agrjbrowse/test/worm/c_elegans.PRJNA13758.WS280.protein.fa.gz
aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein.fa.gz.fai s3://agrjbrowse/test/worm/c_elegans.PRJNA13758.WS280.protein.fa.gz.fai
aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein.fa.gz.gzi s3://agrjbrowse/test/worm/c_elegans.PRJNA13758.WS280.protein.fa.gz.gzi
aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz s3://agrjbrowse/test/c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz
aws s3 cp --acl public-read c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz.tbi s3://agrjbrowse/test/c_elegans.PRJNA13758.WS280.protein_annotation.sorted.gff3.gz.tbi

 


