#!/bin/bash
set -euo pipefail

: "${HADOOP_HOME:?HADOOP_HOME no está definido en el contenedor}"

JAR="$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar"
RESULTS_DIR=/tmp/terasort/resultados

if [[ ! -f "$JAR" ]]; then
    printf 'No se encontró el JAR de ejemplos: %s\n' "$JAR" >&2
    exit 1
fi

mkdir -p "$RESULTS_DIR"
for path in /tmp/terasort/entrada /tmp/terasort/salida /tmp/terasort/reporte; do
    if hadoop fs -test -e "$path"; then
        hadoop fs -rm -r "$path"
    fi
done

printf '# Tiempos de ejecución de TeraSort\n\nDatos generados: 100 000 filas\n\n| Prueba | Duración | Resultado |\n|---|---:|---|\n' > "$RESULTS_DIR/time.md"

run_timed() {
    local name="$1"
    shift
    local start end elapsed duration

    start=$(date +%s%N)
    if "$@"; then
        end=$(date +%s%N)
        elapsed=$((end - start))
        duration=$(awk -v ns="$elapsed" 'BEGIN { printf "%.3f s", ns / 1000000000 }')
        printf '| %s | %s | Correcto |\n' "$name" "$duration" | tee -a "$RESULTS_DIR/time.md"
    else
        end=$(date +%s%N)
        elapsed=$((end - start))
        duration=$(awk -v ns="$elapsed" 'BEGIN { printf "%.3f s", ns / 1000000000 }')
        printf '| %s | %s | Error |\n' "$name" "$duration" | tee -a "$RESULTS_DIR/time.md"
        return 1
    fi
}

printf 'Versión de Hadoop:\n'
hadoop version

run_timed TeraGen hadoop jar "$JAR" teragen 100000 /tmp/terasort/entrada
run_timed TeraSort hadoop jar "$JAR" terasort /tmp/terasort/entrada /tmp/terasort/salida
run_timed TeraValidate hadoop jar "$JAR" teravalidate /tmp/terasort/salida /tmp/terasort/reporte

awk -F'|' '
$2 ~ /TeraGen|TeraSort|TeraValidate/ {
    duration = $3
    gsub(/[^0-9.]/, "", duration)
    total += duration
}
END {
    if (total <= 4) {
        rating = "Tienes una PC master race (tiempo muy corto)"
    } else if (total <= 10) {
        rating = "Tienes una PC buena (tiempo normal)"
    } else {
        rating = "Tienes una PC de rendimiento básico (tiempo extenso)"
    }
    printf "\nTiempo total: %.3f s\nClasificación: %s\n", total, rating
}' "$RESULTS_DIR/time.md" | tee -a "$RESULTS_DIR/time.md"

printf '\nReporte de validación:\n'
hadoop fs -cat /tmp/terasort/reporte/part-r-00000
hadoop fs -get -f /tmp/terasort/reporte/part-r-00000 "$RESULTS_DIR/part-r-00000"
hadoop fs -get -f /tmp/terasort/reporte/_SUCCESS "$RESULTS_DIR/_SUCCESS"

printf '\nArchivos generados en %s:\n' "$RESULTS_DIR"
ls -l "$RESULTS_DIR"
printf '\nTiempos y clasificación:\n'
cat "$RESULTS_DIR/time.md"
