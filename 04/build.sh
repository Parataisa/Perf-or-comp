PROJECT_ROOT="$(pwd)"
NPB_SRC="${PROJECT_ROOT}/npb_bt"
SSCA_SRC="${PROJECT_ROOT}/ssca2"
NPB_BUILD="${PROJECT_ROOT}/build_npb"
SSCA_BUILD="${PROJECT_ROOT}/build_ssca"

echo "Building NPB benchmarks..."
mkdir -p "${NPB_BUILD}"
cd "${NPB_BUILD}"
cmake "${NPB_SRC}" -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja


echo "Building SSCA benchmarks..."
cd "${PROJECT_ROOT}"
mkdir -p "${SSCA_BUILD}"
cd "${SSCA_BUILD}"
cmake "${SSCA_SRC}" -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja

cd "${PROJECT_ROOT}"
echo "Build completed successfully"