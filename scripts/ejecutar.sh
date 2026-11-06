#!/bin/bash
# Ejecutar dentro del contenedor hadoop
export JAR=$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar

time hadoop jar $JAR teragen 100000 /tmp/terasort/entrada
time hadoop jar $JAR terasort /tmp/terasort/entrada /tmp/terasort/salida
time hadoop jar $JAR teravalidate /tmp/terasort/salida /tmp/terasort/reporte
hadoop fs -cat /tmp/terasort/reporte/part-r-00000
