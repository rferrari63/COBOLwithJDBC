#
# Environment for native mode
#
# set workdir - You can use the folder that you want
export TMP_DIR=~/cobol-pg
# set graalvm home directory
export GRAALVM_PATH=~/graalvm-ce-java11-20.3.1
# set javalvm home directory
export JAVA_HOME=${GRAALVM_PATH}
# set the PATH variable
export PATH=$GRAALVM_PATH/bin:$PATH
# set the path for graalvm libraries
export GRAALVM_LIBRARIES_PATH=$GRAALVM_PATH/languages/llvm/native/lib
# export the path for gnucobol 
export NATIVE_LIBRARIES_PATH=$TMP_DIR/native
# include cobc in search path
export PATH=$NATIVE_LIBRARIES_PATH/bin:$PATH
# export the variable where libraries should be searched for first at runtime
export LD_LIBRARY_PATH=${NATIVE_LIBRARIES_PATH}/lib:${GRAALVM_LIBRARIES_PATH}:${TMP_DIR}/target
