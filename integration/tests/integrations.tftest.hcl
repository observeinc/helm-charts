
run "setup_vcluster" {
  module {
    source = "./modules/setup_vcluster"
  }
}


run "connect_vcluster" {
  module {
    source  = "observeinc/collection/aws//modules/testing/exec"
    version = "2.9.0"
  }

  variables {
    command = "python3 ./scripts/connect_vcluster.py"
    env_vars = {
      VCLUSTER_NAME          = run.setup_vcluster.vcluster_name 
    }
  }
  assert {
    condition     = output.error == ""
    error_message = "Error in Connection"
  }
}

