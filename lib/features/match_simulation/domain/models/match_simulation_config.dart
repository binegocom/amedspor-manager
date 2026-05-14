class MatchSimulationConfig {
  final int? seed;
  final bool useFixedTimestep;
  final double fixedStepSeconds;
  final double maxFrameDeltaSeconds;
  final int maxStepsPerUpdate;
  final double totalRealDuration;
  final bool enableExtraTime;

  const MatchSimulationConfig({
    this.seed,
    this.useFixedTimestep = true,
    this.fixedStepSeconds = 1 / 20,
    this.maxFrameDeltaSeconds = 0.25,
    this.maxStepsPerUpdate = 8,
    this.totalRealDuration = 60.0,
    this.enableExtraTime = false,
  });
}
