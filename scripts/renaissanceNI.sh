#!/bin/bash

MYPATH=$(dirname $(realpath -s $0))

if [[ ! -v OPENJDK_HOME ]]; then
  echo "You need to define OPENJDK_HOME"
  exit 1
fi
if [[ ! -v GRAALCE_HOME ]]; then
  echo "You need to define GRAALCE_HOME"
  exit 1
fi
if [[ ! -v GRAALEE_HOME ]]; then
  echo "You need to define GRAALEE_HOME"
  exit 1
fi
if [[ ! -v GRAALCE_SHEN_HOME ]]; then
  echo "You need to define GRAALCE_SHEN_HOME"
  exit 1
fi
if [[ ! -v SHENANDOAH_HOME ]]; then
  echo "You need to define SHENANDOAH_HOME"
  exit 1
fi
if [[ ! -v RENAISSANCE_SINGLE ]]; then
  echo "You need to define RENAISSANCE_SINGLE"
  exit 1
fi

echo_and_exec() {
  if [[ -v DEBUG ]]; then
    echo "  ${@/eval/}"
  fi
  "$@"
}

if [[ ! -v OUTPUT ]]; then
  OUTPUT="${MYPATH}/../output"
  echo "No OUTPUT specified, setting OUTPUT to '${OUTPUT}'"
fi

if [[ ! -v JAVA_ARGS ]]; then
  JAVA_ARGS="-Xms12g -Xmx12g"
  echo "No JAVA_ARGS specified, setting JAVA_ARGS to '${JAVA_ARGS}'"
fi

if [[ ! -v BENCH_TIME ]]; then
  BENCH_TIME="600"
  echo "No BENCH_TIME specified, setting BENCH_TIME to '${BENCH_TIME}' (seconds)"
fi

echo_and_exec mkdir -p ${OUTPUT}

# Renaissance benchmarks which are known to work with Native Image
# See: https://graalvm.slack.com/archives/CN9KSFB40/p1770879311886539?thread_ts=1770839392.854859&cid=CN9KSFB40
benchmarks=(
  "akka-uct"
# "db-shootout" # compiles but fails with java.lang.NoSuchFieldException: directMemory
  "dotty"
  "finagle-chirper"
  "finagle-http"
  "fj-kmeans"
  "future-genetic"
  "mnemonics"
  "par-mnemonics"
  "philosophers"
  "reactors"
  "rx-scrabble"
  "scala-doku"
  "scala-kmeans"
  "scala-stm-bench7"
  "scrabble"
)
# Contains special command line options for compiling the benchmarks to native images and must have the
# sime size like the 'benchmarks' array above.
# See: https://github.com/oracle/graal/blob/c65b0fac/substratevm/mx.substratevm/mx_substratevm_benchmark.py#L69-L148
ni_opts=(
  "" # "akka-uct"
# "--add-opens java.base/java.lang.reflect=ALL-UNNAMED" # "db-shootout" # compiles but fails with java.lang.NoSuchFieldException: directMemory
  "-H:+AllowJRTFileSystem" # "dotty"
  "--initialize-at-build-time=org.slf4j,org.apache.log4j --initialize-at-run-time=io.netty.channel.unix,io.netty.channel.epoll,io.netty.handler.codec.http2,io.netty.handler.ssl,io.netty.internal.tcnative,io.netty.util.internal.logging.Log4JLogger" # "finagle-chirper"
  "--initialize-at-build-time=org.slf4j,org.apache.log4j --initialize-at-run-time=io.netty.channel.unix,io.netty.channel.epoll,io.netty.handler.codec.http2,io.netty.handler.ssl,io.netty.internal.tcnative,io.netty.util.internal.logging.Log4JLogger" # "finagle-http"
  "" # "fj-kmeans"
  "" # "future-genetic"
  "" # "mnemonics"
  "" # "par-mnemonics"
  "" # "philosophers"
  "" # "reactors"
  "" # "rx-scrabble"
  "" # "scala-doku"
  "" # "scala-kmeans"
  "" # "scala-stm-bench7"
  "" # "scrabble"
)

# The different Native Image flavours we want to build
modes=(
  "OpenJDK"
  "GraalCE-JIT"
  "GraalCE-NI"
  "GraalCE-NI-SHEN"
  "GraalEE-JIT"
  "GraalEE-NI"
  "GraalEE-NI-ML"
  "GraalEE-NI-PGO"
  "GraalEE-NI-G1"
  "GraalEE-NI-G1-ML"
  "GraalEE-NI-G1-PGO"
)

# The GraalVM which corresponds to each 'mode' above (this array must have the sime size as 'modes' above)
jdks=(
  ${OPENJDK_HOME}
  ${GRAALCE_HOME}
  ${GRAALCE_HOME}
  ${GRAALCE_SHEN_HOME}
  ${GRAALEE_HOME}
  ${GRAALEE_HOME}
  ${GRAALEE_HOME}
  ${GRAALEE_HOME}
  ${GRAALEE_HOME}
  ${GRAALEE_HOME}
  ${GRAALEE_HOME}
)

# Special native-image build options for each 'mode' above (this array must have the sime size as 'modes' above)
jdk_ni_opts=(
  "" # OpenJDK
  "" # GraalCE-JIT
  "" # GraalCE-NI
  "--native-compiler-options=-L${SHENANDOAH_HOME} --native-compiler-options=-Wl,--unresolved-symbols=ignore-all --gc=shenandoah -H:ShenandoahDebugLevel=product" # GraalCE-NI-SHEN
  "" # GraalEE-JIT
  "-H:-MLProfileInference" # GraalEE-NI
  "" # GraalEE-NI-ML
  "" # GraalEE-NI-PGO
  "--gc=G1 -H:-MLProfileInference" # GraalEE-NI-G1
  "--gc=G1" # GraalEE-NI-ML
  "--gc=G1" # GraalEE-NI-G1-PGO
)

# Special native-image runtime options for each 'mode' above (this array must have the sime size as 'modes' above)
jdk_runtime_opts=(
  "" # OpenJDK
  "-XX:+EnableJVMCI -XX:+UseJVMCICompiler -XX:+UseJVMCINativeLibrary" # GraalCE-JIT
  "" # GraalCE-NI
  "-XX:+UnlockDiagnosticVMOptions -XX:ShenandoahGCMode=passive" # GraalCE-NI-SHEN
  "-XX:+EnableJVMCI -XX:+UseJVMCICompiler -XX:+UseJVMCINativeLibrary" # GraalEE-JIT
  "" # GraalEE-NI
  "" # GraalEE-NI-ML
  "" # GraalEE-NI-PGO
  "" # GraalEE-NI-G1
  "" # GraalEE-NI-G1-ML
  "" # GraalEE-NI-G1-PGO
)

if [[ ${#modes[@]} != ${#jdks[@]} || ${#jdks[@]} != ${#jdk_ni_opts[@]} || ${#jdk_ni_opts[@]} != ${#jdk_runtime_opts[@]} ]]; then
  echo "'modes', 'jdks', 'jdk_ni_opts' and 'jdk_runtime_opts' should all have the same number of elements"
  exit 1
fi

DATE=$(date "+%Y-%m-%d-%H-%M-%S")

for b in ${!benchmarks[@]}; do
  benchmark=${benchmarks[$b]}
  benchmark_jar="${RENAISSANCE_SINGLE}/${benchmark}.jar"

  echo "=== ${benchmark} ==="

  if [[ ! -e ${OUTPUT}/results/${DATE}/${benchmark} ]]; then
    echo_and_exec mkdir -p ${OUTPUT}/results/${DATE}/${benchmark}
  fi
  # Create the NI metadata configuration first if it doesn't exist already
  if [[ -v REBUILD_CONF || ! -e ${OUTPUT}/${benchmark}/conf ]]; then
    echo_and_exec ${GRAALEE_HOME}/bin/java -agentlib:native-image-agent=config-output-dir=${OUTPUT}/${benchmark}/conf -jar ${benchmark_jar} --json /dev/null -t 60 ${benchmark}
  fi
  for m in ${!modes[@]}; do
    jdk=${jdks[$m]}

    if [[ ${benchmark} =~ "dotty" ]]; then
      # 'dotty' needs special runtime arguments if run as native image
      DOTTY_ARGS="-Djava.home=${jdk} -Djava.class.path=${benchmark_jar}"
    else
      DOTTY_ARGS=
    fi

    if [[ ${modes[$m]} =~ "NI" ]]; then

      # For Native Image modes we have to do some preparations...

      if [[ ${modes[$m]} =~ "PGO" ]]; then

        # For PGO modes, create an instrumented binary first.
        if [[ -v REBUILD_NI || ! -e ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]}.pgo ]]; then
          echo_and_exec ${jdk}/bin/native-image -H:ConfigurationFileDirectories=${OUTPUT}/${benchmark}/conf -O3 ${ni_opts[$b]} ${jdk_ni_opts[$m]} --pgo-instrument  -o ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]}.pgo -cp ${benchmark_jar} org.renaissance.harness.RenaissanceSuite
        fi

        # Now run the instrumented binary to create the profile
        if [[ -v REBUILD_NI || ! -e ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]}.iprof ]]; then
          echo_and_exec ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]}.pgo -XX:ProfilesDumpFile=${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]}.iprof ${JAVA_ARGS} -Dmode=${modes[$m]} ${jdk_runtime_opts[$m]} ${DOTTY_ARGS} --json /dev/null -t 60 ${benchmark}
        fi

        # Create the native image based on the PGO profile if it doesn't exist already
        if [[ -v REBUILD_NI || ! -e ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]} ]]; then
          echo_and_exec ${jdk}/bin/native-image --pgo=${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]}.iprof -H:ConfigurationFileDirectories=${OUTPUT}/${benchmark}/conf -O3 ${ni_opts[$b]} ${jdk_ni_opts[$m]} -o ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]} -cp ${benchmark_jar} org.renaissance.harness.RenaissanceSuite
        fi

      else # [[ ${modes[$m]} =~ "PGO"]]

        # Create the native image if it doesn't exist already
        if [[ -v REBUILD_NI || ! -e ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]} ]]; then
          echo_and_exec ${jdk}/bin/native-image -H:ConfigurationFileDirectories=${OUTPUT}/${benchmark}/conf -O3 ${ni_opts[$b]} ${jdk_ni_opts[$m]} -o ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]} -cp ${benchmark_jar} org.renaissance.harness.RenaissanceSuite
        fi
      fi

      # And finally run the benchmark as Native Image
      echo_and_exec ${OUTPUT}/${benchmark}/${benchmark}-${modes[$m]} ${JAVA_ARGS} -Dmode=${modes[$m]} ${jdk_runtime_opts[$m]} ${DOTTY_ARGS} --json ${OUTPUT}/results/${DATE}/${benchmark}/result-${benchmark}-${modes[$m]}.json -t ${BENCH_TIME} ${benchmark}

    else # [[ ${modes[$m]} =~ "NI" ]]

      # For plain Java modes, just run the benchmarks
      echo_and_exec ${jdk}/bin/java ${JAVA_ARGS} -Dmode=${modes[$m]} ${jdk_runtime_opts[$m]} -jar ${benchmark_jar} --json ${OUTPUT}/results/${DATE}/${benchmark}/result-${benchmark}-${modes[$m]}.json -t ${BENCH_TIME} ${benchmark}
    fi
  done
done
