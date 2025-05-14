# Script was made to get LLVM build for iOS from the Nyxian server
wget https://nyxian.app/bootstrap/LLVM.zip

# Now create a tmp folder and prepare it
mkdir tmp
mv LLVM.zip tmp/LLVM.zip

# Now enter and extract and move it back
cd tmp
unzip LLVM.zip
mv LLVM.xcframework ../LLVM.xcframework

# Now exit the dir and remove it
cd ..
rm -rf tmp

# Now move LLVM.xcframework
mv LLVM.xcframework Nyxian/LindChain/LLVM.xcframework
