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
#include <momemta/Types.h>
#include <momemta/Unused.h>

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

    double weight_tt_JECup, weight_tt_JECup_err, weight_tt_JECup_time;
    out_tree->Branch("weight_tt_JECup", &weight_tt_JECup);
    out_tree->Branch("weight_tt_JECup_err", &weight_tt_JECup_err);
    out_tree->Branch("weight_tt_JECup_time", &weight_tt_JECup_time);
    
    double weight_tt_JECdown, weight_tt_JECdown_err, weight_tt_JECdown_time;
    out_tree->Branch("weight_tt_JECdown", &weight_tt_JECdown);
    out_tree->Branch("weight_tt_JECdown_err", &weight_tt_JECdown_err);
    out_tree->Branch("weight_tt_JECdown_time", &weight_tt_JECdown_time);

    /*
     * Prepare MoMEMta to compute the weights
     */
    // Set MoMEMta's logging level to `debug`
    logging::set_level(boost::log::trivial::debug);

    // Construct the ConfigurationReader from the Lua file
    ConfigurationReader configuration_tt("/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic_JEC/TTbar_FullyLeptonic.lua");

    // Instantiate MoMEMta using a **frozen** configuration
    MoMEMta momemta_tt(configuration_tt.freeze());

    //configuration_tt.getCubaConfiguration().set("retainStateFile", false);
    //MoMEMta momemta_tt_end(configuration_tt.freeze());
    /* configuration_tt.getCubaConfiguration().set("grid_number", -1);
    configuration_tt.getCubaConfiguration().set("n_start", 10000);
    configuration_tt.getCubaConfiguration().set("max_eval", 10000);
    MoMEMta momemta_tt_start(configuration_tt.freeze());*/

    double JECfactor = 1.05;

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

        LorentzVector bjet1_JECup_p4 = bjet1_p4*JECfactor;
        LorentzVector bjet2_JECup_p4 = bjet2_p4*JECfactor;
        LorentzVector diff_JECup = bjet1_JECup_p4 + bjet2_JECup_p4 - bjet1_p4 - bjet2_p4;
        LorentzVector met_JECup_p4 = met_p4 - diff_JECup;

        LorentzVector bjet1_JECdown_p4 = bjet1_p4/JECfactor;
        LorentzVector bjet2_JECdown_p4 = bjet2_p4/JECfactor;
        LorentzVector diff_JECdown = bjet1_JECdown_p4 + bjet2_JECdown_p4 - bjet1_p4 - bjet2_p4;
        LorentzVector met_JECdown_p4 = met_p4 - diff_JECdown;

        // Ensure the leptons are given in the correct order w.r.t their charge 
        if (leading_lep_PID < 0)
            std::swap(lep_plus_p4, lep_minus_p4);

        auto start_time = system_clock::now();
        
        //std::vector<std::pair<double, double>> weights_tt = momemta_tt.computeWeights({lep_minus_p4, bjet1_p4, lep_plus_p4, bjet2_p4}, met_p4);
        std::vector<std::pair<double, double>> weights_tt = momemta_tt.computeWeights({lep_minus_p4, lep_plus_p4, bjet1_p4, bjet2_p4, met_p4, bjet1_JECup_p4, bjet2_JECup_p4, met_JECup_p4, bjet1_JECdown_p4, bjet2_JECdown_p4, met_JECdown_p4});
        auto end_time_tt = system_clock::now();
        
        /*std::vector<std::pair<double, double>> weights_tt_JECup = momemta_tt.computeWeights({lep_minus_p4, bjet1_JECup_p4, lep_plus_p4, bjet2_JECup_p4}, met_JECup_p4);
        auto end_time_tt_JECup = system_clock::now();*/
        
        /*std::vector<std::pair<double, double>> weights_tt_JECdown = momemta_tt.computeWeights({lep_minus_p4, bjet1_JECdown_p4, lep_plus_p4, bjet2_JECdown_p4}, met_JECdown_p4);
        auto end_time_tt_JECdown = system_clock::now();*/

        // Retrieve the weight and uncertainty
        weight_tt = weights_tt[0].first;
        weight_tt_err = weights_tt[0].second;
        weight_tt_time = std::chrono::duration_cast<milliseconds>(end_time_tt - start_time).count();
        
        weight_tt_JECup = weights_tt[1].first;
        weight_tt_JECup_err = weights_tt[1].second;

        weight_tt_JECdown = weights_tt[2].first;
        weight_tt_JECdown_err = weights_tt[2].second;
        
        /*/weight_tt_JECup = weights_tt_JECup.back().first;
        weight_tt_JECup_err = weights_tt_JECup.back().second;
        weight_tt_JECup_time = std::chrono::duration_cast<milliseconds>(end_time_tt_JECup - end_time_tt).count();

        weight_tt_JECdown = weights_tt_JECdown.back().first;
        weight_tt_JECdown_err = weights_tt_JECdown.back().second;
        weight_tt_JECdown_time = std::chrono::duration_cast<milliseconds>(end_time_tt_JECdown - end_time_tt_JECup).count();*/

        //LOG(debug) << "tt result: " << weight_tt << " +- " << weight_tt_err;
        //LOG(info) << "Weight computed in " << weight_tt_time << "ms";

        out_tree->Fill();
    }

    // Save our output TTree
    out_tree->SaveAs(argv[4]);

    return 0;
}
