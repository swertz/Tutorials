#!/usr/bin/python

## Example usage of condorTools
## Run `python condorExample.py`

from condorTools import condorSubmitter

submitters = []

#submitters.append( condorSubmitter("/home/fynu/swertz/tests_MEM/Tutorials/build/ttH_H_inv/TTbar_ttH.exe", "condor_tt_ttH", ["/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic/tt_20evt.root"], "t", 10) )
submitters.append( 
        condorSubmitter(
            "/home/fynu/swertz/tests_MEM/Tutorials/build/ttH_H_inv/TTbar_ttH.exe", 
            "condor_ttH", 
            [
                "/home/fynu/swertz/storage/Delphes/condorDelphes/ttH_H_inv/condor/output/output_selected_0.root",
                "/home/fynu/swertz/storage/Delphes/condorDelphes/ttH_H_inv/condor/output/output_selected_2.root",
                "/home/fynu/swertz/storage/Delphes/condorDelphes/ttH_H_inv/condor/output/output_selected_3.root",
            ], 
            "t", 
            25,
            maxEvents = 4000,
        )
    )

submitters.append( 
        condorSubmitter(
            "/home/fynu/swertz/tests_MEM/Tutorials/build/ttH_H_inv/TTbar_ttH.exe", 
            "condor_tt", 
            [
                "/home/fynu/swertz/ttbar_effth_delphes/15_November/selectedEvents/TTbar_qCut50.root",
            ], 
            "t", 
            25,
            maxEvents = 4000,
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
