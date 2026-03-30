_: prev: {
  # replace intel-compute-runtime with intel-compute-runtime-legacy1 for legacy Gen8, Gen9 and Gen11 Intel GPUs
  intel-compute-runtime = prev.intel-compute-runtime-legacy1;

  # create symlink for intel-opencl/libigdrcl_legacy1.so
  prev.systemd.tmpfiles.rules =
    let
      createLink = src: dest: "L+ ${dest} - - - - ${src}";
    in
    [
      (createLink "${prev.pkgs.intel-compute-runtime-legacy1}/lib/intel-opencl/libigdrcl_legacy1.so" "/usr/lib/x86_64-linux-gnu/intel-opencl/libigdrcl_legacy1.so")
    ];
}
