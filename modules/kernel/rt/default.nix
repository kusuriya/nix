{config, pkgs, ...}:
{
  kernelPackages = pkgs.linuxPackages_latest;
  kernelPatches = [{
    name = "preempt-rt";
    patch = null;
    extraStructuredConfig = with lib.kernel; {
      PREEMPT_RT = yes;
      EXPERT = yes; # PREEMPT_RT depends on it (in kernel/Kconfig.preempt)
      PREEMPT_VOLUNTARY = lib.mkForce no; # PREEMPT_RT deselects it.
      # Fix error: unused option: RT_GROUP_SCHED.
      RT_GROUP_SCHED = lib.mkForce (option no); # Removed by sched-disable-rt-group-sched-on-rt.patch.
      DRM_I915_GVT = lib.mkForce (option yes);
      DRM_I915_GVT_KVMGT = lib.mkForce (option module);
    };
  }];
}
