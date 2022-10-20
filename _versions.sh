#!/bin/sh

# Copyright 2015-present Viktor Szakats. See LICENSE.md
# SPDX-License-Identifier: MIT

# NOTE: Bump nghttp3 and ngtcp2 together with curl.

export CACERT_VER=''  # '2022-10-11'

export CURL_VER_='7.85.0'
export CURL_HASH=88b54a6d4b9a48cb4d873c7056dcba997ddd5b7be5a2d537a4acb55c20b04be6
export BROTLI_VER_='1.0.9'
export BROTLI_HASH=f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
export CARES_VER_='1.17.2'
export CARES_HASH=4803c844ce20ce510ef0eb83f8ea41fa24ecaae9d280c468c582d2bb25b3913d
export GSASL_VER_='2.2.0'
export GSASL_HASH=79b868e3b9976dc484d59b29ca0ae8897be96ce4d36d32aed5d935a7a3307759
export LIBUNISTRING_VER_='1.1'
export LIBUNISTRING_HASH=827c1eb9cb6e7c738b171745dac0888aa58c5924df2e59239318383de0729b98
export LIBICONV_VER_='1.17'
export LIBICONV_HASH=8f74213b56238c85a50a5329f77e06198771e70dd9a739779f4c02f65d971313
export LIBIDN2_VER_='2.3.3'
export LIBIDN2_HASH=f3ac987522c00d33d44b323cae424e2cffcb4c63c6aa6cd1376edacbf1c36eb0
export LIBPSL_VER_='0.21.1'
export LIBPSL_HASH=ac6ce1e1fbd4d0254c4ddb9d37f1fa99dec83619c1253328155206b896210d4c
export WOLFSSH_VER_='1.4.11'
export WOLFSSH_HASH=46f01ae2c757d551d9b251cd99be234dbb7332ce6a3586b83735ef41e26707a1
export LIBSSH_VER_='0.10.4'
export LIBSSH_HASH=07392c54ab61476288d1c1f0a7c557b50211797ad00c34c3af2bbc4dbc4bd97d
export LIBSSH2_VER_='1.10.0'
export LIBSSH2_HASH=2d64e90f3ded394b91d3a2e774ca203a4179f69aebee03003e5a6fa621e41d51
export NGHTTP2_VER_='1.50.0'
export NGHTTP2_HASH=af24007e34c18c782393a1dc3685f8fd5b50283e90a9191d25488eb50aa2c825
export NGHTTP3_VER_='0.7.1'
export NGHTTP3_HASH=331d70c2fc8e63d931a7b33b592fa3992bcffd36ed8900691ce541f4d694efa7
export NGTCP2_VER_='0.9.0'
export NGTCP2_HASH=1c6ecfe3d132ccc23262258db9da8964622ad9be552a798d9f9589386e347299
#export NGTCP2_VER_='0.10.0'
#export NGTCP2_HASH=a323f29d8d9968c41f445e48f3a3e5047f2678195a3f2d8f86d60d7a29418940
export WOLFSSL_VER_='5.5.1'
export WOLFSSL_HASH=97339e6956c90e7c881ba5c748dd04f7c30e5dbe0c06da765418c51375a6dee3
export MBEDTLS_VER_='3.2.1'
export MBEDTLS_HASH=d0e77a020f69ad558efc660d3106481b75bd3056d6301c31564e04a0faae88cc
export OPENSSL_QUIC_VER_='3.0.5'
export OPENSSL_QUIC_HASH=766878d2c97d13ea36254ae3b1bf553939ac111f3f1b3449b8d777aca7671366
export OPENSSL_VER_='3.0.5'
export OPENSSL_HASH=aa7d8d9bef71ad6525c55ba11e5f4397889ce49c2c9349dcea6d3e4f0b024a7a
export BORINGSSL_VER_='1ee71185a2322dc354bee5e5a0abfb1810a27dc6'
export BORINGSSL_HASH=00a86eaf79aca7dc1f730e1f91c0511d0fdeea9e1abcdabc53948b6ec80bfe6c
export LIBRESSL_VER_='3.6.0'
export LIBRESSL_HASH=1b12defcbbdbdbeda86929e421000af0f42333add4817fd26c0d9a1aec478404
export ZLIBNG_VER_='2.0.6'
export ZLIBNG_HASH=8258b75a72303b661a238047cb348203d88d9dddf85d480ed885f375916fcab6
export ZLIB_VER_='1.2.13'
export ZLIB_HASH=d14c38e313afc35a9a8760dadf26042f51ea0f5d154b0630a31da0540107fb98
export ZSTD_VER_='1.5.2'
export ZSTD_HASH=7c42d56fac126929a6a85dbc73ff1db2411d04f104fae9bdea51305663a83fd0
export LLVM_MINGW_LINUX_VER_='20220906'
export LLVM_MINGW_LINUX_HASH=ee00708bdd65eeaa88d5fa89ad7e3fa1d6bae8093ee4559748e431e55f7568ec
export LLVM_MINGW_MAC_VER_='20220906'
export LLVM_MINGW_MAC_HASH=9c259f125b9a0d5a8b393c3d2a35e9fccd539f46c25d1424fcc62513fa40f786
export LLVM_MINGW_WIN_VER_='20220906'
export LLVM_MINGW_WIN_HASH=06c8523447a369303f7a67dda1d2b66a6b2e460640126458f69f1d98afd3fdf1
export PEFILE_VER_='2022.5.30'

# Create revision string
# NOTE: Set _REV to empty after bumping CURL_VER_, and
#       set it to 1 then increment by 1 each time bumping a dependency
#       version or pushing a CI rebuild for the main branch.
export _REV='9'
