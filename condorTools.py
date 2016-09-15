##
## Utilities to submit condor jobs to create the histograms.
## See condorExample.py for how-to usage.
##

import os
import sys
import stat
import copy

import ROOT as R

class condorSubmitter:

    def __init__(self, executable, baseDir, fileList, treeName, evtPerJob, maxEvents=-1):

        self.maxEvents = maxEvents
        self.executable = executable
        self.filesSplitting = self.getFilesSplitting(fileList, treeName, evtPerJob)
        self.baseDir = os.path.join(os.path.abspath(baseDir), "condor")
        self.isCreated = False
        self.user = os.environ["USER"]

        self.jobCmd = """
should_transfer_files   = YES
when_to_transfer_output = ON_EXIT
universe       = vanilla
requirements   = (CMSFARM =?= TRUE)&&(Memory > 200)

arguments      = $(Process)
output         = {logdir_relpath}/condor_$(Process).out
error          = {logdir_relpath}/condor_$(Process).err
log            = {logdir_relpath}/condor_$(Process).log
executable     = {indir_path}/condor.sh
queue {n_jobs}

"""
        
        self.commonShell = """
#!/usr/bin.bash

{indir_path}/condor_$1.sh
"""

        self.baseShell = """
#!/usr/bin.bash

module load gcc/gcc-4.9.1-sl6_amd64
module load root/6.06.02-sl6_gcc49
module load boost/1.57_sl6_gcc49
module load lhapdf/6.1

LD_LIBRARY_PATH=${{LD_LIBRARY_PATH}}:/home/fynu/swertz/tests_MEM/MoMEMta/local_install/lib/

{executable} {input_file} {start_evt} {end_evt} output_{job_id}.root

mv output_{job_id}.root {outdir_path}
"""

    def getFilesSplitting(self, fileList, treeName, evtPerJob):

        files_entries = []
        files_splitting = []
        totEvents = 0
        maxEvents = 0

        for file in fileList:
            if not os.path.isfile(file):
                print "Warning: file {} does not exist".format(file)
                continue

            m_tree = R.TChain(treeName)
            m_tree.Add(file)
            m_evt = m_tree.GetEntries()
            maxEvents += m_evt

            if m_evt == 0:
                print "Warning: tree {} in file {} has zero entries".format(treeName, file)
                continue

            files_entries.append( (file, m_evt) )

        if self.maxEvents > 0:
            maxEvents = min(maxEvents, self.maxEvents)

        for file in files_entries:
            evt_start = 0
            evt_stop = min(evtPerJob, file[1], maxEvents)
            
            while evt_stop <= file[1] and totEvents < maxEvents:
                files_splitting.append( (file[0], evt_start, evt_stop) )
                totEvents += evt_stop - evt_start
                
                evt_start += evtPerJob
                evt_stop += evtPerJob

        return files_splitting


    def setupCondorDirs(self):
        """ Setup the condor directories (input/output) in baseDir. """
    
        if not os.path.isdir(self.baseDir):
            os.makedirs(self.baseDir)
    
        inDir = os.path.join(self.baseDir, "input")
        if not os.path.isdir(inDir):
            os.makedirs(inDir)
        self.inDir = inDir
        
        outDir = os.path.join(self.baseDir, "output")
        if not os.path.isdir(outDir):
            os.makedirs(outDir)
        self.outDir = outDir

        logDir = os.path.join(self.baseDir, "logs")
        if not os.path.isdir(logDir):
            os.makedirs(logDir)
        self.logDir = os.path.relpath(logDir)

    def createCondorFiles(self):
        """ Create the .sh and .cmd files for Condor."""

        jobCount = 0
        dico = {}
        dico["indir_path"] = self.inDir
        dico["logdir_relpath"] = os.path.relpath(self.logDir)
        dico["outdir_path"] = self.outDir
        dico["executable"] = self.executable

        for file in self.filesSplitting:

            dico["job_id"] = str(jobCount)
            dico["input_file"] = file[0]
            dico["start_evt"] = file[1]
            dico["end_evt"] = file[2]

            thisCmd = str(self.jobCmd)
            thisSh = str(self.baseShell)
            
            thisSh = self.baseShell.format(**dico)

            shFileName = os.path.join(self.inDir, "condor_{}.sh".format(jobCount))
            with open(shFileName, "w") as sh:
                sh.write(thisSh)
            perm = os.stat(shFileName)
            os.chmod(shFileName, perm.st_mode | stat.S_IEXEC)

            jobCount += 1

        dico["n_jobs"] = jobCount
           
        cmdFileName = os.path.join(self.inDir, "condor.cmd")
        with open(cmdFileName, "w") as cmd:
            cmd.write(self.jobCmd.format(**dico))

        commonShellFileName = os.path.join(self.inDir, "condor.sh")
        with open(commonShellFileName, "w") as sh:
            sh.write(self.commonShell.format(**dico))
        perm = os.stat(commonShellFileName)
        os.chmod(commonShellFileName, perm.st_mode | stat.S_IEXEC)

        print "Created condor command for {} jobs. Caution: the jobs are not submitted yet!.".format(jobCount)

        self.jobCount = jobCount
        self.isCreated = True

    
    def submitOnCondor(self):

        if not self.isCreated:
            raise Exception("Job files must be created first using createCondorFiles().")

        print "Submitting {} condor jobs.".format(self.jobCount)
        os.system("condor_submit {}".format( os.path.join(self.inDir, "condor.cmd") ) )

        print "Submitting {} jobs done.".format(self.jobCount)
        print "Monitor your jobs with `condor_status -submitter` or `condor_q {}`".format(self.user)



if __name__ == "__main__":
    raise Exception("Not destined to be run stand-alone.")
