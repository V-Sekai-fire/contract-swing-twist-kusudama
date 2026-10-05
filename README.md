# contract-swing-twist-kusudama

A Lean 4 simulation of swing-twist inverse kinematics with multi-cone joint limits, checked point for point against the engine's own solver.

## What it is for

A change to the joint-limit solver is tried here in seconds, against cones and solved directions recorded from a live engine scene, before an engine rebuild that takes minutes. The datasets are Parquet release assets of this repository rather than files in the tree.

## Build and run

```sh
data/fetch.sh
lake exe sim
```

## Licence

The licence is not stated.
