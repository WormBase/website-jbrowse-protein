#!/bin/bash

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

echo "awsbucket:"
echo $AWSBUCKET
echo "species"
echo $SPECIES
echo "release"
echo $RELEASE


MAKEPATH=/website-genome-browsers/protein_schematic/bin/make_schematic.pl

CONFPATH=/website-genome-browsers/protein_schematic/bin/protein_build.conf

LOGFILE=$SPECIES
LOGFILE+=".log"

#this is by far the longest running portion of the script (typically a few hours)
echo "running build script"
$MAKEPATH --conf $CONFPATH --quiet --release $RELEASE --species $SPECIES 2>1 | grep -v "Deep recursion"; mv 1 $LOGFILE
echo "finished running build script"

DATADIR=/jbrowse/data

cd $DATADIR

UPLOADTOS3PATH=/agr_jbrowse_config/scripts/upload_to_S3.pl

# this path will need to be fixed for "real" releases. Something like:
#  REMOTEPATH="MOD-jbrowses/WormBase/WS$RELEASE/$SPECIES"
REMOTEPATH="test/WS$RELEASE/protein/$SPECIES"

echo "$UPLOADTOS3PATH --bucket $AWSBUCKET --local $SPECIES --remote $REMOTEPATH --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET"
$UPLOADTOS3PATH --bucket $AWSBUCKET --local $SPECIES --remote $REMOTEPATH --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET
 


