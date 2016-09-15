-- Load the library containing the matrix element
load_modules('/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic/MatrixElement/build/libme_TTbar_ee.so')

parameters = {
    energy = 13000.,
    top_mass = 173.,
    top_width = 1.491500,
    W_mass = 80.419002,
    W_width = 2.047600,
}

cuba = {
    relative_accuracy = 0.05,
    max_eval = 1000000,
    n_start = 50000,
    verbosity = 3,
}

lep1 = 'input::particles/1'
lep2 = 'input::particles/2'

bjet1_nom = 'input::particles/3'
bjet2_nom = 'input::particles/4'
met_nom = 'input::particles/5'

bjet1_up = 'input::particles/6'
bjet2_up = 'input::particles/7'
met_up = 'input::particles/8'

bjet1_down = 'input::particles/9'
bjet2_down = 'input::particles/10'
met_down = 'input::particles/11'

GaussianTransferFunction.tf_lep1 = {
    ps_point = add_dimension(),
    reco_particle = lep1,
    sigma = 0.05,
}

GaussianTransferFunction.tf_lep2 = {
    ps_point = add_dimension(),
    reco_particle = lep2,
    sigma = 0.05,
}

ps_tf_p2 = add_dimension()

BinnedTransferFunctionOnEnergy.tf_bjet1_nom = {
    ps_point = ps_tf_p2,
    reco_particle = bjet1_nom,
    file = '/home/fynu/swertz/scratch/CMSSW_7_6_3_patch2/src/cp3_llbb/TTTools/histFactory/transferFunctions/tf_beforeFSR_loose.root',
    th2_name = 'bJet_bParton_DeltaEvsE_Norm',
}
BinnedTransferFunctionOnEnergy.tf_bjet1_up = {
    ps_point = ps_tf_p2,
    reco_particle = bjet1_up,
    file = '/home/fynu/swertz/scratch/CMSSW_7_6_3_patch2/src/cp3_llbb/TTTools/histFactory/transferFunctions/tf_beforeFSR_loose.root',
    th2_name = 'bJet_bParton_DeltaEvsE_Norm',
}
BinnedTransferFunctionOnEnergy.tf_bjet1_down = {
    ps_point = ps_tf_p2,
    reco_particle = bjet1_down,
    file = '/home/fynu/swertz/scratch/CMSSW_7_6_3_patch2/src/cp3_llbb/TTTools/histFactory/transferFunctions/tf_beforeFSR_loose.root',
    th2_name = 'bJet_bParton_DeltaEvsE_Norm',
}

ps_tf_p4 = add_dimension()

BinnedTransferFunctionOnEnergy.tf_bjet2_nom = {
    ps_point = ps_tf_p4,
    reco_particle = bjet2_nom,
    file = '/home/fynu/swertz/scratch/CMSSW_7_6_3_patch2/src/cp3_llbb/TTTools/histFactory/transferFunctions/tf_beforeFSR_loose.root',
    th2_name = 'bJet_bParton_DeltaEvsE_Norm',
}
BinnedTransferFunctionOnEnergy.tf_bjet2_up = {
    ps_point = ps_tf_p4,
    reco_particle = bjet2_up,
    file = '/home/fynu/swertz/scratch/CMSSW_7_6_3_patch2/src/cp3_llbb/TTTools/histFactory/transferFunctions/tf_beforeFSR_loose.root',
    th2_name = 'bJet_bParton_DeltaEvsE_Norm',
}
BinnedTransferFunctionOnEnergy.tf_bjet2_down = {
    ps_point = ps_tf_p4,
    reco_particle = bjet2_down,
    file = '/home/fynu/swertz/scratch/CMSSW_7_6_3_patch2/src/cp3_llbb/TTTools/histFactory/transferFunctions/tf_beforeFSR_loose.root',
    th2_name = 'bJet_bParton_DeltaEvsE_Norm',
}

ps_perm = add_dimension()
Permutator.permutator_nom = {
    ps_point = ps_perm,
    inputs = {
        'tf_bjet1_nom::output',
        'tf_bjet2_nom::output',
    }
}
Permutator.permutator_up = {
    ps_point = ps_perm,
    inputs = {
        'tf_bjet1_up::output',
        'tf_bjet2_up::output',
    }
}
Permutator.permutator_down = {
    ps_point = ps_perm,
    inputs = {
        'tf_bjet1_down::output',
        'tf_bjet2_down::output',
    }
}

inputs_nom = {
  'tf_lep1::output',
  'permutator_nom::output/1',
  'tf_lep2::output',
  'permutator_nom::output/2',
}
inputs_up = {
  'tf_lep1::output',
  'permutator_up::output/1',
  'tf_lep2::output',
  'permutator_up::output/2',
}
inputs_down = {
  'tf_lep1::output',
  'permutator_down::output/1',
  'tf_lep2::output',
  'permutator_down::output/2',
}

BreitWignerGenerator.flatter_s13 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s134 = {
    ps_point = add_dimension(),
    mass = parameter('top_mass'),
    width = parameter('top_width')
}

BreitWignerGenerator.flatter_s25 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s256 = {
    ps_point = add_dimension(),
    mass = parameter('top_mass'),
    width = parameter('top_width')
}

BlockD.blockd_nom = {
    inputs = inputs_nom,
    met = met_nom,

    pT_is_met = true,

    s13 = 'flatter_s13::s',
    s134 = 'flatter_s134::s',
    s25 = 'flatter_s25::s',
    s256 = 'flatter_s256::s',
}

Looper.looper_nom = {
    solutions = "blockd_nom::solutions",
    path = Path("boost_nom", "ttbar_nom", "integrand_nom")
}

    BuildInitialState.boost_nom = {
        particles = inputs_nom,
        solution = 'looper_nom::solution',
        do_transverse_boost = true
    }
    
    jacobians_nom = {'flatter_s13::jacobian', 'flatter_s134::jacobian', 'flatter_s25::jacobian', 'flatter_s256::jacobian', 'tf_lep1::TF_times_jacobian', 'tf_lep2::TF_times_jacobian', 'tf_bjet1_nom::TF_times_jacobian', 'tf_bjet2_nom::TF_times_jacobian'}
    
    MatrixElement.ttbar_nom = {
      pdf = 'CT10nlo',
      pdf_scale = parameter('top_mass'),
    
      matrix_element = 'TTbar_ee_sm_P1_Sigma_sm_gg_epvebemvexbx',
      matrix_element_parameters = {
          card = '/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic/MatrixElement/Cards/param_card.dat'
      },
    
      initialState = 'boost_nom::partons',
    
      invisibles = {
        input = 'looper_nom::solution',
        ids = {
          {
            pdg_id = 12,
            me_index = 2,
          },
    
          {
            pdg_id = -12,
            me_index = 5,
          }
        }
      },
    
      particles = {
        inputs = inputs_nom,
        ids = {
          {
            pdg_id = -11,
            me_index = 1,
          },
    
          {
            pdg_id = 5,
            me_index = 3,
          },
    
          {
            pdg_id = 11,
            me_index = 4,
          },
    
          {
            pdg_id = -5,
            me_index = 6,
          },
        }
      },
    
      jacobians = jacobians_nom
    }

    DoubleSummer.integrand_nom = {
        input = 'ttbar_nom::output'
    }

BlockD.blockd_up = {
    inputs = inputs_up,
    met = met_up,

    pT_is_met = true,

    s13 = 'flatter_s13::s',
    s134 = 'flatter_s134::s',
    s25 = 'flatter_s25::s',
    s256 = 'flatter_s256::s',
}

Looper.looper_up = {
    solutions = "blockd_up::solutions",
    path = Path("boost_up", "ttbar_up", "integrand_up")
}

    BuildInitialState.boost_up = {
        particles = inputs_up,
        solution = 'looper_up::solution',
        do_transverse_boost = true
    }
    
    jacobians_up = {'flatter_s13::jacobian', 'flatter_s134::jacobian', 'flatter_s25::jacobian', 'flatter_s256::jacobian', 'tf_lep1::TF_times_jacobian', 'tf_lep2::TF_times_jacobian', 'tf_bjet1_up::TF_times_jacobian', 'tf_bjet2_up::TF_times_jacobian'}
    
    MatrixElement.ttbar_up = {
      pdf = 'CT10nlo',
      pdf_scale = parameter('top_mass'),
    
      matrix_element = 'TTbar_ee_sm_P1_Sigma_sm_gg_epvebemvexbx',
      matrix_element_parameters = {
          card = '/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic/MatrixElement/Cards/param_card.dat'
      },
    
      initialState = 'boost_up::partons',
    
      invisibles = {
        input = 'looper_up::solution',
        ids = {
          {
            pdg_id = 12,
            me_index = 2,
          },
    
          {
            pdg_id = -12,
            me_index = 5,
          }
        }
      },
    
      particles = {
        inputs = inputs_up,
        ids = {
          {
            pdg_id = -11,
            me_index = 1,
          },
    
          {
            pdg_id = 5,
            me_index = 3,
          },
    
          {
            pdg_id = 11,
            me_index = 4,
          },
    
          {
            pdg_id = -5,
            me_index = 6,
          },
        }
      },
    
      jacobians = jacobians_up
    }

    DoubleSummer.integrand_up = {
        input = 'ttbar_up::output'
    }


BlockD.blockd_down = {
    inputs = inputs_down,
    met = met_down,

    pT_is_met = true,

    s13 = 'flatter_s13::s',
    s134 = 'flatter_s134::s',
    s25 = 'flatter_s25::s',
    s256 = 'flatter_s256::s',
}

Looper.looper_down = {
    solutions = "blockd_down::solutions",
    path = Path("boost_down", "ttbar_down", "integrand_down")
}

    BuildInitialState.boost_down = {
        particles = inputs_down,
        solution = 'looper_down::solution',
        do_transverse_boost = true
    }
    
    jacobians_down = {'flatter_s13::jacobian', 'flatter_s134::jacobian', 'flatter_s25::jacobian', 'flatter_s256::jacobian', 'tf_lep1::TF_times_jacobian', 'tf_lep2::TF_times_jacobian', 'tf_bjet1_down::TF_times_jacobian', 'tf_bjet2_down::TF_times_jacobian'}
    
    MatrixElement.ttbar_down = {
      pdf = 'CT10nlo',
      pdf_scale = parameter('top_mass'),
    
      matrix_element = 'TTbar_ee_sm_P1_Sigma_sm_gg_epvebemvexbx',
      matrix_element_parameters = {
          card = '/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic/MatrixElement/Cards/param_card.dat'
      },
    
      initialState = 'boost_down::partons',
    
      invisibles = {
        input = 'looper_down::solution',
        ids = {
          {
            pdg_id = 12,
            me_index = 2,
          },
    
          {
            pdg_id = -12,
            me_index = 5,
          }
        }
      },
    
      particles = {
        inputs = inputs_down,
        ids = {
          {
            pdg_id = -11,
            me_index = 1,
          },
    
          {
            pdg_id = 5,
            me_index = 3,
          },
    
          {
            pdg_id = 11,
            me_index = 4,
          },
    
          {
            pdg_id = -5,
            me_index = 6,
          },
        }
      },
    
      jacobians = jacobians_down
    }

    DoubleSummer.integrand_down = {
        input = 'ttbar_down::output'
    }


integrand('integrand_nom::sum', 'integrand_up::sum', 'integrand_down::sum')
