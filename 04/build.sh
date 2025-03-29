mkdir build_npb
cd build_npb
cmake ../npb_bt -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja

cd ..
mkdir build_ssca
cd build_ssca
cmake ../ssca2 -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja