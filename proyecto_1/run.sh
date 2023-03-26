cd RSA
echo "Compiling Decryptor..."
./build.sh

echo "Decrypting image..."
cd build
./main

echo "Running visualization..."
cd ../../visualization
npm start