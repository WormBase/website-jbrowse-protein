# website-jbrowse-protein

Dockerfile for building protein schematic

This README encompasses not only what is contained in this repo but also documents
how it fits in with the Alliance of Genome Resources data and server pipelines, as 
well as the the data processing and JBrowse server tools in the `website-genome-browsers` 
repo in the `protein-schematic-*` branches.

Overview
========

The Dockerfile in this repo codes for a data processing tool that fetches the 
protein GFF from the WormBase FTP site, processes it into JBrowse NCList json
format, and deposits the results in the Alliance JBrowse s3 bucket. This processing 
is currently configured to run through the Alliance GoCD system and making use of
the ridiculously parallelizable nature of processing data from many assemblies. If
running on a single CPU is desired, the `single_species` branch can be used (it is
somewhat misleadingly named, as it will run all species, but one at a time).

Also running in the GoCD system at the Alliance are development/staging and production
versions of JBrowse configured to make use of these data.

Workflow
========

When starting a new release, a release specific branch is created from the
`protein-schematic-staging` branch, typically called `protein-$RELEASE`. Usually, the only
change that needs to be made for a release is to bump the `RELEASE=` number in 
`/website-genome-browsers/protein_schematic/Dockerfile`. Once the release number has
be pushed into the release specific repo in website-genome-browser, two changes need
to be made in this repo:

1. The Dockerfile in this repo can be updated to add the release to the line 

    RUN git clone --single-branch --branch protein-282 https://github.com/WormBase/website-genome-browsers.git

2. The line `RELEASE=282` in `parallel.sh` should be updated the the current release.

When these changes are commited to the main branch, the GoCD system will run the
`JBrowseSoftwareProcessWBProt` pipeline to build the Dockerfile in this repo, and
then run the `JBrowseProcessWBProtein` pipeline, which will run a compute machine
through Ansible to process the WormBase protein GFF files. The script that it runs,
`parallel.sh` uses GNU parallel to process all of the assemblies in WormBase 
(currently 31) even though many of them don't have a protein GFF file (meaning
only the protein fasta file gets processed). After processing the the files, the
script will upload the JBrowse data to the Alliance JBrowse S3 bucket (agrjbrowse).

Building JBrowse servers
========================




