# Renaissance Benchmarks for Graal Native Image

This repository provides some scripts for running a compatible subset of the  Renaissance benchmarks as Graal native images and compares the performance of OpenJDK's HotSpot JVM with various GraalVM and GraalVM Native Image configurations.

The results for JDK 25 look as follows:

![Renaissance 0.16.1 with OpenJDK/GraalVM 25](./output/results/2026-02-16-09-47-38/stripe-jdk-25.svg)

In this graph, the labels for the JVM implementation have the following meaning:
- OpenJDK-25: plain OpenJDK 25 running with the default C2/G1 configuration
- GraalCE-25-JIT: GraalVM 25 Community edition with the Graal JIT (i.e. "libgraal") running as high tier JIT and the default G1 collector.
- GraalEE-25-JIT: Oracle GraalVM 25 (formerly known as "Enterprise Edition) with the Graal JIT (i.e. "libgraal") running as high tier JIT and the default G1 collector.
- GraalCE-25-NI: Native image produced by the GraalVM 25 Community edition (running with the default Serial GC).
- GraalCE-25-NI-SHEN: Native image produced by the GraalVM 25 Community edition (running with a [development version of Shenandoah GC in "passive" (i.e. "Stop-The-World" mode)](https://github.com/simonis/labs-openjdk/tree/simonis/GR-70066)).
- GraalEE-25-NI: Native image produced by Oracle GraalVM 25 (running with the default Serial GC and without automatic, ML-powered, profile guided optimizations (PGO), i.e. `-H:-MLProfileInference`).
- GraalEE-25-NI-ML: Native image produced by Oracle GraalVM 25 (running with the default Serial GC and automatic, ML-powered, profile guided optimizations (PGO)).
- GraalEE-25-NI-PGO: Native image produced by Oracle GraalVM 25 (running with the default Serial GC and explicit, profile guided optimizations (PGO), i.e. training run).
- GraalEE-25-NI-G1: Native image produced by Oracle GraalVM 25 (running with G1 GC and without automatic, ML-powered, profile guided optimizations (PGO), i.e. `-H:-MLProfileInference`).
- GraalEE-25-NI-G1-ML: Native image produced by Oracle GraalVM 25 (running with G1 GC and automatic, ML-powered, profile guided optimizations (PGO)).
- GraalEE-25-NI-G1-PGO: Native image produced by Oracle GraalVM 25 (running with the G1 GC and explicit, profile guided optimizations (PGO), i.e. training run).

The above numbers were collected on a [c5.metal](https://costcalc.cloudoptimo.com/aws-pricing-calculator/ec2/c5.metal) bare metal instance with 96 vCPUs and 25gb RAM using [Renaissance 0.16.1](https://renaissance.dev/download).

## Details on running the benchmarks

## Creating the output graphs
