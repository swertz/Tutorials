#!/usr/bin/python

## Example usage of condorTools
## Run `python condorExample.py`

from condorTools import condorSubmitter

submitters = []

submitters.append( 
        condorSubmitter(
            "/home/fynu/swertz/tests_MEM/Tutorials/build/TTbar_FullyLeptonic_JEC/TTbar_FullyLeptonic.exe", 
            "condor_ttJEC_parallel_wideTF_updated", 
            [
                "/home/fynu/swertz/storage/TopEffTh_2016_06/TTbar.root",
            ], 
            "t", 
            50,
            maxEvents = 20000,
        )
    )

for sub in submitters:

    ## Create test_condor directory and subdirs
    sub.setupCondorDirs()

    ## Write command and data files in the condor directory
    sub.createCondorFiles()

    ## Actually submit the jobs
    ## It is recommended to do a dry-run first without submitting to condor
    sub.submitOnCondor()
