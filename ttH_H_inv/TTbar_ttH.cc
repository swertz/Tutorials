/*
 *  MoMEMta: a modular implementation of the Matrix Element Method
 *  Copyright (C) 2016  Universite catholique de Louvain (UCL), Belgium
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#include <momemta/ConfigurationReader.h>
#include <momemta/Logging.h>
#include <momemta/MoMEMta.h>
#include <momemta/Utils.h>

#include <TTree.h>
#include <TChain.h>
#include <Math/PtEtaPhiM4D.h>
#include <Math/LorentzVector.h>

#include <string>
#include <chrono>

using namespace std::chrono;

using LorentzVectorM = ROOT::Math::LorentzVector<ROOT::Math::PtEtaPhiM4D<float>>;

/*
 * Example executable file loading an input sample of events,
 * computing weights using MoMEMta in the fully-leptonic ttbar hypothesis,
 * and saving these weights along with a copy of the event content in an output file.
 */

int main(int argc, char** argv) {

    UNUSED(argc);
    UNUSED(argv);

    /*
     * Load events from input file, retrieve reconstructed particles and MET
     */
    TChain chain("t");
    chain.Add(argv[1]);

    LorentzVectorM* lep_plus_p4M = nullptr;
    LorentzVectorM* lep_minus_p4M = nullptr;
    LorentzVectorM* bjet1_p4M = nullptr;
    LorentzVectorM* bjet2_p4M = nullptr;
    float MET_met, MET_phi;
    int leading_lep_PID;

    chain.SetBranchAddress("lep1_p4", &lep_plus_p4M);
    chain.SetBranchAddress("lep2_p4", &lep_minus_p4M);
    chain.SetBranchAddress("bjet1_p4", &bjet1_p4M);
    chain.SetBranchAddress("bjet2_p4", &bjet2_p4M);
    chain.SetBranchAddress("MET_met", &MET_met);
    chain.SetBranchAddress("MET_phi", &MET_phi);
    chain.SetBranchAddress("leadLepPID", &leading_lep_PID);
    
    /*
     * Define output TTree, which will be a clone of the input tree,
     * with the addition of the weights we're computing (including uncertainty and computation time)
     */
    TTree* out_tree = chain.CloneTree(0);
    
    double weight_tt, weight_tt_err, weight_tt_time;
    out_tree->Branch("weight_tt", &weight_tt);
    out_tree->Branch("weight_tt_err", &weight_tt_err);
    out_tree->Branch("weight_tt_time", &weight_tt_time);

    double weight_ttH, weight_ttH_err, weight_ttH_time;
    out_tree->Branch("weight_ttH", &weight_ttH);
    out_tree->Branch("weight_ttH_err", &weight_ttH_err);
    out_tree->Branch("weight_ttH_time", &weight_ttH_time);
    
    /*
     * Prepare MoMEMta to compute the weights
     */
    // Set MoMEMta's logging level to `debug`
    logging::set_level(boost::log::trivial::debug);

    // Construct the ConfigurationReader from the Lua file
    ConfigurationReader configuration_tt("/home/fynu/swertz/tests_MEM/Tutorials/ttH_H_inv/TTbar.lua");
    ConfigurationReader configuration_ttH("/home/fynu/swertz/tests_MEM/Tutorials/ttH_H_inv/ttH.lua");

    // Instantiate MoMEMta using a **frozen** configuration
    MoMEMta momemta_tt(configuration_tt.freeze());
    MoMEMta momemta_ttH(configuration_ttH.freeze());

    /*
     * Loop over all input events
     */
    for (int64_t entry = std::stoi(argv[2]); entry < std::min<int64_t>(chain.GetEntries(), std::stoi(argv[3])); entry++) {
        chain.GetEntry(entry);
        LOG(debug) << "==== Event " << entry << " =====";

        /*
         * Prepare the LorentzVectors passed to MoMEMta:
         * In the input file they are written in the PtEtaPhiM<float> basis,
         * while MoMEMta expects PxPyPzE<double>, so we have to perform this change of basis:
         */
        LorentzVector lep_plus_p4 { lep_plus_p4M->Px(), lep_plus_p4M->Py(), lep_plus_p4M->Pz(), lep_plus_p4M->E() };
        LorentzVector lep_minus_p4 { lep_minus_p4M->Px(), lep_minus_p4M->Py(), lep_minus_p4M->Pz(), lep_minus_p4M->E() };
        LorentzVector bjet1_p4 { bjet1_p4M->Px(), bjet1_p4M->Py(), bjet1_p4M->Pz(), bjet1_p4M->E() };
        LorentzVector bjet2_p4 { bjet2_p4M->Px(), bjet2_p4M->Py(), bjet2_p4M->Pz(), bjet2_p4M->E() };

        LorentzVectorM met_p4M { MET_met, 0, MET_phi, 0 };
        LorentzVector met_p4 { met_p4M.Px(), met_p4M.Py(), met_p4M.Pz(), met_p4M.E() };

        LorentzVector dummy_h { 50, 0, 0, 134.629 };

        LOG(debug) << "Particles:";
        LOG(debug) << lep_plus_p4;
        LOG(debug) << bjet1_p4;
        LOG(debug) << lep_minus_p4;
        LOG(debug) << bjet2_p4;
        LOG(debug) << met_p4;
        
        // Ensure the leptons are given in the correct order w.r.t their charge 
        if (leading_lep_PID < 0)
            std::swap(lep_plus_p4, lep_minus_p4);

        auto start_time = system_clock::now();
        std::vector<std::pair<double, double>> weights_tt = momemta_tt.computeWeights({lep_minus_p4, bjet1_p4, lep_plus_p4, bjet2_p4}, met_p4);
        auto end_time_tt = system_clock::now();
        std::vector<std::pair<double, double>> weights_ttH = momemta_ttH.computeWeights({lep_minus_p4, bjet1_p4, lep_plus_p4, bjet2_p4, dummy_h}, met_p4);
        auto end_time_ttH = system_clock::now();

        // Retrieve the weight and uncertainty
        weight_tt = weights_tt.back().first;
        weight_tt_err = weights_tt.back().second;
        weight_tt_time = std::chrono::duration_cast<milliseconds>(end_time_tt - start_time).count();

        LOG(debug) << "tt result: " << weight_tt << " +- " << weight_tt_err;
        LOG(info) << "Weight computed in " << weight_tt_time << "ms";

        weight_ttH = weights_ttH.back().first;
        weight_ttH_err = weights_ttH.back().second;
        weight_ttH_time = std::chrono::duration_cast<milliseconds>(end_time_ttH - end_time_tt).count();

        LOG(debug) << "ttH result: " << weight_ttH << " +- " << weight_ttH_err;
        LOG(info) << "Weight computed in " << weight_ttH_time << "ms";

        out_tree->Fill();
    }

    // Save our output TTree
    out_tree->SaveAs(argv[4]);

    return 0;
}
