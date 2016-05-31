-- Load the library containing the matrix element
load_modules('/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic/MatrixElement/build/libme_TTbar_ee.so')

-- Global parameters used by several modules
-- Changing these has NO impact on the value of the parameters used by the matrix element!
parameters = {
    energy = 13000.,
    top_mass = 173.,
    top_width = 1.491500,
    W_mass = 80.419002,
    W_width = 2.047600,
}

-- Configuration of Cuba
cuba = {
    relative_accuracy = 0.05,
    n_start = 100000,
    n_increase = 200000,
    max_eval = 10000000,
    verbosity = 3,
}

--BinnedTransferFunctionOnEnergy.tf_p1 = {
GaussianTransferFunction.tf_p1 = {
    ps_point = getpspoint(),
    reco_particle = 'input::particles/1',
    sigma = 0.05,
    --file = '/nfs/home/fynu/swertz/tests_MEM/binnedTF/TF_generator/Control_plots_hh_TF.root',
    --th2_name = 'Binned_Egen_DeltaE_Norm_ele',
}

--BinnedTransferFunctionOnEnergy.tf_p2 = {
GaussianTransferFunction.tf_p2 = {
    ps_point = getpspoint(),
    reco_particle = 'input::particles/2',
    sigma = 0.1,
    --file = '/nfs/home/fynu/swertz/tests_MEM/binnedTF/TF_generator/Control_plots_hh_TF.root',
    --th2_name = 'Binned_Egen_DeltaE_Norm_jet',
}

--BinnedTransferFunctionOnEnergy.tf_p3 = {
GaussianTransferFunction.tf_p3 = {
    ps_point = getpspoint(),
    reco_particle = 'input::particles/3',
    sigma = 0.05,
    --file = '/nfs/home/fynu/swertz/tests_MEM/binnedTF/TF_generator/Control_plots_hh_TF.root',
    --th2_name = 'Binned_Egen_DeltaE_Norm_ele',
}

--BinnedTransferFunctionOnEnergy.tf_p4 = {
GaussianTransferFunction.tf_p4 = {
    ps_point = getpspoint(),
    reco_particle = 'input::particles/4',
    sigma = 0.1,
    --file = '/nfs/home/fynu/swertz/tests_MEM/binnedTF/TF_generator/Control_plots_hh_TF.root',
    --th2_name = 'Binned_Egen_DeltaE_Norm_jet',
}

inputs_before_perm = {
    'tf_p1::output',
    'tf_p2::output',
    'tf_p3::output',
    'tf_p4::output',
}

-- Use permutator module to permutate input particles 2 and 4 (ie, the b-jets) using the MC,
-- which requires an additional dimension for integration
Permutator.permutator = {
    ps_point = getpspoint(),
    inputs = {
      inputs_before_perm[2],
      inputs_before_perm[4],
    }
}

inputs = {
  inputs_before_perm[1],
  'permutator::output/1',
  inputs_before_perm[3],
  'permutator::output/2',
}

-- Use the BreitWignerGenerators to generate values distributed as the corresponding peaks,
-- for each propagator in the topology
BreitWignerGenerator.flatter_s13 = {
    ps_point = getpspoint(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s134 = {
    ps_point = getpspoint(),
    mass = parameter('top_mass'),
    width = parameter('top_width')
}

BreitWignerGenerator.flatter_s25 = {
    ps_point = getpspoint(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

BreitWignerGenerator.flatter_s256 = {
    ps_point = getpspoint(),
    mass = parameter('top_mass'),
    width = parameter('top_width')
}

-- The main block defines the phase-space parametrisation,
-- converts our particles given by the transfer functions, and our propagator masses
-- into solutions for the missing particles in the event
BlockD.blockd = {
    inputs = inputs,

    -- Fix the neutrino transverse momentum to the experimental MET passed to MoMEMta
    pT_is_met = true,

    s13 = 'flatter_s13::s',
    s134 = 'flatter_s134::s',
    s25 = 'flatter_s25::s',
    s256 = 'flatter_s256::s',
}

-- Using the fully reconstructed event (invisibles and visibles), build the initial state
BuildInitialState.boost = {
    particles = inputs,
    invisibles = {
        'blockd::invisibles',
    },

    -- Since the neutrinos were reconstructed using the experimental MET,
    -- the event has non-zero total transverse momentum,
    -- so we have to do the boost to define an initial state satisfying conservation
    -- of momentum.
    do_transverse_boost = true
}

jacobians = {'flatter_s13::jacobian', 'flatter_s134::jacobian', 'flatter_s25::jacobian', 'flatter_s256::jacobian', 'tf_p1::TF_times_jacobian', 'tf_p2::TF_times_jacobian', 'tf_p3::TF_times_jacobian', 'tf_p4::TF_times_jacobian'}

-- This module defines the `integrands` output, which will be taken by MoMEMta as the value to integrate
MatrixElement.ttbar = {
  pdf = 'CT10nlo',
  pdf_scale = parameter('top_mass'),

  -- Name of the matrix element, defined in the .cc file of the ME 
  matrix_element = 'TTbar_ee_sm_P1_Sigma_sm_gg_epvebemvexbx',
  matrix_element_parameters = {
      card = '/home/fynu/swertz/tests_MEM/Tutorials/TTbar_FullyLeptonic/MatrixElement/Cards/param_card.dat'
  },

  initialState = 'boost::output',

  invisibles = {
    input = 'blockd::invisibles',
    -- Jacobians of the block: one value per invisibles' solution
    jacobians = 'blockd::jacobians',
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

  -- Configure how the inputs are linked to the matrix element (order and PID of the leg)
  -- Together with the invisibles' ids, it has to match the `mapFinalStates` index in the matrix element .cc file
  particles = {
    inputs = inputs,
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

  -- Other jacobians: only one value each
  jacobians = jacobians
}
