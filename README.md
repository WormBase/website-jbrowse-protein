# website-jbrowse-protein

Dockerfile for building protein schematic

This README encompasses not only what is contained in this repo but also documents
how it fits in with the Alliance of Genome Resources data and server pipelines, as
well as the the data processing and JBrowse server tools in the `website-genome-browsers`
repo in the `protein-schematic-*` branches.

# Overview

The Dockerfile in this repo codes for a data processing tool that fetches the
protein GFF from the WormBase FTP site, processes it into JBrowse NCList json
format, and deposits the results in the Alliance JBrowse S3 bucket. This processing
is currently configured to run through the Alliance GoCD system and making use of
the ridiculously parallelizable nature of processing data from many assemblies. If
running on a single CPU is desired, the `single_species` branch can be used (it is
somewhat misleadingly named, as it will run all species, but one at a time).

# Workflow

When starting a new release, a release specific branch is created from the
`protein_schematic_staging` branch, typically called `protein-$RELEASE`. Usually, the only
change that needs to be made for a release is to bump the `RELEASE=` number in
`/website-genome-browsers/protein_schematic/Dockerfile`. Once the release number has
be pushed into the release specific repo in website-genome-browser, two changes need
to be made in this repo:

1. The Dockerfile in this repo can be updated to add the release to the line

   RUN git clone --single-branch --branch protein-282 https://github.com/WormBase/website-genome-browsers.git

2. The line `RELEASE=282` in `parallel.sh` should be updated the the current release.

Note that both of these items could potentially be parameterized and passed in
when running though Ansible using the `$MOD_RELEASE_VERSION` environment variable in
the agr_ansible_devops WormBase specific environment (https://github.com/alliance-genome/agr_ansible_devops/blob/master/environments/jbrowse/wb.yml), but this hasn't been
hooked up yet.

When these changes are commited to the main branch, the GoCD system will run the
`JBrowseSoftwareProcessWBProt` pipeline to build the Dockerfile in this repo, and
then run the `JBrowseProcessWBProtein` pipeline, which will run a compute machine
through Ansible to process the WormBase protein GFF files. The script that it runs,
`parallel.sh` uses GNU parallel to process all of the assemblies in WormBase
(currently 31) even though many of them don't have a protein GFF file (meaning
only the protein fasta file gets processed). After processing the the files, the
script will upload the JBrowse data to the Alliance JBrowse S3 bucket (agrjbrowse).

# Building JBrowse servers

There are two servers for protein schematic JBrowse instances:

1. http://jbrowse_wb_protein_dev.alliancegenome.org/tools/protein_schematic/ for development/staging
2. http://jbrowse_wb_protein_prod.alliancegenome.org/tools/protein_schematic/ for production

Both the development and production servers follow the same build procedure. The GoCD
pipeline for building the server container builds automatically when
there are commits to the branches in website-genome-browsers are commited to. For
development/staging, the `protein_schematic_staging` branch is watched, and for
production, it watches `protein_schematic_production`.

To create a staging version:

1. Create a `protein-$RELEASE` branch of the website-genome-browsers repo off
   of the `protein_schematic_staging` branch.

2. Edit the Dockerfile at `/website-genome-browsers/protein_schematic/Dockerfile`
   in that branch to update the `ARG RELEASE=` line to update the release version,

3. Update all of the trackList.json files in '/website-genome-browsers/protein_schematic/jbrowse/data/$ASSEMBLY' to change the version number. While this should be parameterized
   and scripted in some way, it can easily be done with this Perl oneliner:

```
perl -pi -e 's/WormBase\/WS281\/protein/WormBase\/WS282\/protein/' */trackList.json
```

Execute this one liner in `/website-genome-browsers/protein_schematic/jbrowse/data`
and of course, replace `281` and `282` with the old and new releases of WormBase
respectively.

4. After these changes are made, push these changes to the `protein-$RELEASE` github
   branch. At this point, local test versions of the server can be created from the Dockerfile.

5. To update the staging server, merge these changes into the `protein_schematic_staging`
   branch which will cause GoCD to rerun the `JBrowseWBProteinDev` pipeline, which rebuilds
   the server container, then the `JBrowseWBProteinDevServer` pipeline which moves the
   container onto the server machine and starts it, and then finally runs the
   `NginxJBrowse` pipeline to restart the proxy nginx server to point at the new
   server container. This rebuild process can take up to 15 minutes. Note that the final
   step of restarting the nginx proxy must be manually triggered in the GoCD website.

### Building the production server

To create a production version merge that changes in the `protein_schematic_staging` branch
into the `protein_schematic_production` which will cause GoCD to rebuild the server
container similarly to step five above, execpt that it runs the `JBrowseWBProteinProd`
and `JBrowseWBProteinProdServer` pipelines
