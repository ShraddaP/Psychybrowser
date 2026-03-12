#!/bin/bash
set -e
cd /Users/shradda/company_products/Psychybrowser/src

# 1. Rust Toolchain
echo "Restoring Rust..."
mkdir -p third_party/rust-toolchain
cd third_party/rust-toolchain
if [ ! -f VERSION ]; then
  curl -fL https://commondatastorage.googleapis.com/chromium-browser-clang/Mac/rust-toolchain-6f54d591c3116ee7f8ce9321ddeca286810cc142-2-llvmorg-23-init-5669-g8a0be0bc.tar.xz -o rust.tar.xz
  tar -xJf rust.tar.xz && rm rust.tar.xz
fi
cd ../..

# 2. V8
if [ ! -f v8/gni/v8.gni ]; then
  echo "Restoring V8..."
  rm -rf v8 && mkdir v8 && cd v8 && git init && git remote add origin https://chromium.googlesource.com/v8/v8.git
  git fetch --depth 1 origin b3c11715e59ed2d31a6013f25914cbb64a9bb641
  git checkout -f FETCH_HEAD && cd ..
fi

# 3. Third Party Repos (Using simple space-separated list for compatibility)
DEPS_LIST="
third_party/perfetto|https://android.googlesource.com/platform/external/perfetto
third_party/skia|https://skia.googlesource.com/skia
third_party/angle|https://chromium.googlesource.com/angle/angle
third_party/webrtc|https://webrtc.googlesource.com/src
third_party/swiftshader/src|https://swiftshader.googlesource.com/SwiftShader
third_party/pdfium|https://pdfium.googlesource.com/pdfium
third_party/breakpad/breakpad|https://chromium.googlesource.com/breakpad/breakpad
third_party/crashpad/crashpad|https://chromium.googlesource.com/crashpad/crashpad
third_party/boringssl/src|https://boringssl.googlesource.com/boringssl
third_party/icu|https://chromium.googlesource.com/chromium/deps/icu
third_party/libc++/src|https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxx
third_party/libc++abi/src|https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxxabi
third_party/libunwind/src|https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libunwind
"

for item in $DEPS_LIST; do
  path=$(echo $item | cut -d'|' -f1)
  url=$(echo $item | cut -d'|' -f2)
  if [ ! -f "$path/BUILD.gn" ] && [ ! -f "$path/webrtc.gni" ]; then
    echo "Restoring $path..."
    rm -rf "$path" && git clone --depth 1 "$url" "$path"
  fi
done

# 4. GN Gen
echo "Running GN gen..."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export PATH="/Users/shradda/company_products/depot_tools:$PATH"
/Users/shradda/company_products/depot_tools/gn gen out/Default --root=. --args='is_debug=false dcheck_always_on=false symbol_level=0'
ls -la out/Default/build.ninja
