#!/bin/sh

# Copyright 2014-present Viktor Szakats. See LICENSE.md
# SPDX-License-Identifier: MIT

# shellcheck disable=SC3040
set -o xtrace -o errexit -o nounset; [ -n "${BASH:-}${ZSH_NAME:-}" ] && set -o pipefail

export _NAM _VER _OUT _BAS _DST

_NAM="$(basename "$0" | cut -f 1 -d '.' | sed 's/-autotools//')"
_VER="$1"

(
  cd "${_NAM}"  # mandatory component

  cache='configure-cache.txt'
  rm -f "${cache}"

  rm -r -f "${_PKGDIR}" "${_BLDDIR}-shared" "${_BLDDIR}-static"

  [ -f 'configure' ] || autoreconf --force --install

  [ "${CW_DEV_CROSSMAKE_REPRO:-}" = '1' ] && export AR="${AR_NORMALIZE}"

  # tell libtool to allow building a shared library against static libs
  export lt_cv_deplibs_check_method='pass_all'

  for pass in shared static; do

    options="${_CONFIGURE_GLOBAL}"
    export CC="${_CC_GLOBAL}"
    export CFLAGS="${_CFLAGS_GLOBAL} -O3"
    export CPPFLAGS="${_CPPFLAGS_GLOBAL} -DNDEBUG"
    export RCFLAGS="${_RCFLAGS_GLOBAL}"
    export LDFLAGS="${_LDFLAGS_GLOBAL} -Wl,--nxcompat -Wl,--dynamicbase"
    export LIBS="${_LIBS_GLOBAL}"

    CPPFLAGS="${CPPFLAGS} -DHAVE_PROCESS_H"  # TODO: delete after https://github.com/curl/curl/pull/9703

    options="${options} --enable-unix-sockets"

    if [ "${CW_DEV_LLD_REPRODUCE:-}" = '1' ] && [ "${_LD}" = 'lld' ]; then
      if [ "${pass}" = 'shared' ]; then
        LDFLAGS="${LDFLAGS} -Wl,--reproduce=$(pwd)/$(basename "$0" .sh)-dll.tar"
      else
        LDFLAGS="${LDFLAGS} -Wl,--reproduce=$(pwd)/$(basename "$0" .sh)-exe.tar"
      fi
    fi

    if [ "${_CPU}" = 'x86' ]; then
      if [ "${pass}" = 'static' ]; then
        LDFLAGS="${LDFLAGS} -Wl,--pic-executable,-e,_mainCRTStartup"
      fi
    else
      if [ "${pass}" = 'static' ]; then
        LDFLAGS="${LDFLAGS} -Wl,--pic-executable,-e,mainCRTStartup"
      else
        LDFLAGS="${LDFLAGS} -Wl,--image-base,0x150000000"
      fi
      LDFLAGS="${LDFLAGS} -Wl,--high-entropy-va"
    fi

    if [ ! "${_BRANCH#*unicode*}" = "${_BRANCH}" ]; then
      CPPFLAGS="${CPPFLAGS} -DUNICODE -D_UNICODE"
      LDFLAGS="${LDFLAGS} -municode"
    fi

    if [ "${CW_MAP}" = '1' ]; then
      if [ "${pass}" = 'shared' ]; then
        _MAP_NAME="libcurl${_CURL_DLL_SUFFIX}.map"
      else
        _MAP_NAME='curl.map'
      fi
      LDFLAGS="${LDFLAGS} -Wl,-Map,${_MAP_NAME}"
    fi

    if [ ! "${_BRANCH#*pico*}" = "${_BRANCH}" ] || \
       [ ! "${_BRANCH#*nano*}" = "${_BRANCH}" ]; then
      options="${options} --disable-alt-svc"
    else
      options="${options} --enable-alt-svc"
    fi

    if [ ! "${_BRANCH#*pico*}" = "${_BRANCH}" ]; then
      options="${options} --disable-crypto-auth"
      options="${options} --disable-dict --disable-file --disable-gopher --disable-mqtt --disable-rtsp --disable-smb --disable-telnet --disable-tftp"
      options="${options} --disable-ftp"
      options="${options} --disable-imap --disable-pop3 --disable-smtp"
      options="${options} --disable-ldap --disable-ldaps --with-ldap-lib=wldap32"
    else
      options="${options} --enable-crypto-auth"
      options="${options} --enable-dict --enable-file --enable-gopher --enable-mqtt --enable-rtsp --enable-smb --enable-telnet --enable-tftp"
      if [ "${_BRANCH#*noftp*}" = "${_BRANCH}" ]; then
        options="${options} --enable-ftp"
      else
        options="${options} --disable-ftp"
      fi
      options="${options} --enable-imap --enable-pop3 --enable-smtp"
      options="${options} --enable-ldap --enable-ldaps --with-ldap-lib=wldap32"
    fi

    # NOTE: root path with spaces breaks all values with '${_TOP}'. But,
    #       autotools breaks on spaces anyway, so let us leave it like that.

    if [ -n "${_ZLIB}" ]; then
      options="${options} --with-zlib=${_TOP}/${_ZLIB}/${_PP}"
    else
      options="${options} --without-zlib"
    fi

    if [ -d ../brotli ] && [ "${_BRANCH#*nobrotli*}" = "${_BRANCH}" ]; then
      options="${options} --with-brotli=${_TOP}/brotli/${_PP}"
      LDFLAGS="${LDFLAGS} -L${_TOP}/brotli/${_PP}/lib"
      LIBS="${LIBS} -lbrotlicommon"
    else
      options="${options} --without-brotli"
    fi
    if [ -d ../zstd ] && [ "${_BRANCH#*nozstd*}" = "${_BRANCH}" ]; then
      options="${options} --with-zstd=${_TOP}/zstd/${_PP}"
      LDFLAGS="${LDFLAGS} -L${_TOP}/zstd/${_PP}/lib"
      LIBS="${LIBS} -lzstd"
    else
      options="${options} --without-zstd"
    fi

    options="${options} --with-schannel"
    CPPFLAGS="${CPPFLAGS} -DHAS_ALPN"

    h3=0

    if [ -n "${_OPENSSL}" ]; then
      options="${options} --with-openssl=${_TOP}/${_OPENSSL}/${_PP}"
      options="${options} --disable-openssl-auto-load-config"
      if [ "${_OPENSSL}" = 'boringssl' ]; then
        CPPFLAGS="${CPPFLAGS} -DCURL_BORINGSSL_VERSION=\\\"$(printf '%.8s' "${BORINGSSL_VER_}")\\\""
        options="${options} --disable-tls-srp"
        if [ "${_TOOLCHAIN}" = 'mingw-w64' ] && [ "${_CPU}" = 'x64' ] && [ "${_CRT}" = 'ucrt' ]; then  # FIXME
          LDFLAGS="${LDFLAGS} -Wl,-Bdynamic,-lpthread,-Bstatic"
        else
          LDFLAGS="${LDFLAGS} -Wl,-Bstatic,-lpthread,-Bdynamic"
        fi
        h3=1
      elif [ "${_OPENSSL}" = 'libressl' ]; then
        options="${options} --disable-tls-srp"
        LIBS="${LIBS} -lbcrypt"  # for auto-detection
        h3=1
      elif [ "${_OPENSSL}" = 'openssl-quic' ] || [ "${_OPENSSL}" = 'openssl' ]; then
        options="${options} --enable-tls-srp"
        LIBS="${LIBS} -lbcrypt"  # for auto-detection
        [ "${_OPENSSL}" = 'openssl-quic' ] && h3=1
      fi
    else
      options="${options} --disable-tls-srp"
    fi

    if [ -d ../wolfssl ]; then
      options="${options} --with-wolfssl=${_TOP}/wolfssl/${_PP}"
      h3=1
    else
      options="${options} --without-wolfssl"
    fi

    if [ -d ../mbedtls ]; then
      options="${options} --with-mbedtls=${_TOP}/mbedtls/${_PP}"
    else
      options="${options} --without-mbedtls"
    fi

    options="${options} --without-gnutls --without-bearssl --without-rustls --without-nss --without-hyper"

    if [ -d ../wolfssh ] && [ -d ../wolfssl ]; then
      options="${options} --with-wolfssh=${_TOP}/wolfssh/${_PP}"
      CPPFLAGS="${CPPFLAGS} -I${_TOP}/wolfssh/${_PP}/include"
      LDFLAGS="${LDFLAGS} -L${_TOP}/wolfssh/${_PP}/lib"
      options="${options} --without-libssh"
      options="${options} --without-libssh2"
    elif [ -d ../libssh ]; then
      options="${options} --with-libssh=${_TOP}/libssh/${_PP}"
      options="${options} --without-wolfssh"
      options="${options} --without-libssh2"
      CPPFLAGS="${CPPFLAGS} -DLIBSSH_STATIC"
    elif [ -d ../libssh2 ]; then
      options="${options} --with-libssh2=${_TOP}/libssh2/${_PP}"
      options="${options} --without-wolfssh"
      options="${options} --without-libssh"
      LIBS="${LIBS} -lbcrypt"  # for auto-detection
    else
      options="${options} --without-wolfssh"
      options="${options} --without-libssh"
      options="${options} --without-libssh2"
    fi

    options="${options} --without-librtmp"

    if [ -d ../libidn2 ]; then
      options="${options} --with-libidn2=${_TOP}/libidn2/${_PP}"
      LDFLAGS="${LDFLAGS} -L${_TOP}/libidn2/${_PP}/lib"
      LIBS="${LIBS} -lidn2"

      if [ -d ../libpsl ]; then
        options="${options} --with-libpsl=${_TOP}/libpsl/${_PP}"
        CPPFLAGS="${CPPFLAGS} -I${_TOP}/libpsl/${_PP}/include"
        LDFLAGS="${LDFLAGS} -L${_TOP}/libpsl/${_PP}/lib"
        LIBS="${LIBS} -lpsl"
      else
        options="${options} --without-libpsl"
      fi

      if [ -d ../libiconv ]; then
        LDFLAGS="${LDFLAGS} -L${_TOP}/libiconv/${_PP}/lib"
        LIBS="${LIBS} -liconv"
      fi
      if [ -d ../libunistring ]; then
        LDFLAGS="${LDFLAGS} -L${_TOP}/libunistring/${_PP}/lib"
        LIBS="${LIBS} -lunistring"
      fi
    elif [ "${_BRANCH#*pico*}" = "${_BRANCH}" ]; then
      options="${options} --without-libidn2"
      options="${options} --with-winidn"
    fi

    if [ -d ../cares ]; then
      options="${options} --enable-ares=${_TOP}/cares/${_PP}"
      CPPFLAGS="${CPPFLAGS} -DCARES_STATICLIB"
    else
      options="${options} --disable-ares"
    fi

    if [ -d ../gsasl ]; then
      options="${options} --with-libgsasl=${_TOP}/gsasl/${_PP}"
      CPPFLAGS="${CPPFLAGS} -I${_TOP}/gsasl/${_PP}/include"
      LDFLAGS="${LDFLAGS} -L${_TOP}/gsasl/${_PP}/lib"
    else
      options="${options} --without-libgsasl"
    fi

    if [ -d ../nghttp2 ]; then
      options="${options} --with-nghttp2=${_TOP}/nghttp2/${_PP}"
      CPPFLAGS="${CPPFLAGS} -DNGHTTP2_STATICLIB"
    else
      options="${options} --without-nghttp2"
    fi

    [ "${_BRANCH#*noh3*}" = "${_BRANCH}" ] || h3=0

    # HTTP3 does not appear enabled in the configure summary.
    if [ "${h3}" = '1' ] && [ -d ../nghttp3 ] && [ -d ../ngtcp2 ]; then
      # Detection insists on having a pkg-config, so force feed everything manually.
      # This lib does not appear enabled in the configure summary.
      options="${options} --with-nghttp3=yes"
      CPPFLAGS="${CPPFLAGS} -DNGHTTP3_STATICLIB -DUSE_NGHTTP3"
      CPPFLAGS="${CPPFLAGS} -I${_TOP}/nghttp3/${_PP}/include"
      LDFLAGS="${LDFLAGS} -L${_TOP}/nghttp3/${_PP}/lib"
      LIBS="${LIBS} -lnghttp3"

      # Detection insists on having a pkg-config, so force feed everything manually.
      # This lib does not appear enabled in the configure summary.
      options="${options} --with-ngtcp2=yes"
      CPPFLAGS="${CPPFLAGS} -DNGTCP2_STATICLIB -DUSE_NGTCP2"
      CPPFLAGS="${CPPFLAGS} -I${_TOP}/ngtcp2/${_PP}/include"
      LDFLAGS="${LDFLAGS} -L${_TOP}/ngtcp2/${_PP}/lib"
      LIBS="${LIBS} -lngtcp2"
      if [ "${_OPENSSL}" = 'boringssl' ]; then
        LIBS="${LIBS} -lngtcp2_crypto_boringssl"
      elif [ "${_OPENSSL}" = 'openssl-quic' ] || [ "${_OPENSSL}" = 'libressl' ]; then
        LIBS="${LIBS} -lngtcp2_crypto_openssl"
      elif [ -d ../wolfssl ]; then
        LIBS="${LIBS} -lngtcp2_crypto_wolfssl"
      fi
    else
      options="${options} --without-nghttp3"
      options="${options} --without-ngtcp2"
    fi

    options="${options} --without-quiche --without-msh3"

    options="${options} --enable-websockets"

    if [ "${pass}" = 'shared' ]; then
      _DEF_NAME="libcurl${_CURL_DLL_SUFFIX}.def"
      LDFLAGS="${LDFLAGS} -Wl,--output-def,${_DEF_NAME}"
      CPPFLAGS="${CPPFLAGS} -DCURL_STATICLIB"

      options="${options} --disable-static"
      options="${options} --enable-shared"
    else
      options="${options} --enable-static"
      options="${options} --disable-shared"
    fi

    if [ -f "${cache}" ]; then
      grep -a -v -E '_env_(CPPFLAGS|LDFLAGS)_' "${cache}" > "${cache}.new"
      mv "${cache}.new" "${cache}"
    fi

    options="${options} --cache-file=../${cache}"

    (
      mkdir "${_BLDDIR}-${pass}"; cd "${_BLDDIR}-${pass}"
      # shellcheck disable=SC2086
      ../configure ${options} \
        --disable-debug \
        --disable-pthreads \
        --enable-warnings \
        --enable-threaded-resolver \
        --enable-symbol-hiding \
        --enable-http \
        --enable-proxy \
        --enable-manual \
        --enable-libcurl-option \
        --enable-ipv6 \
        --enable-verbose \
        --enable-sspi \
        --enable-ntlm \
        --enable-cookies \
        --enable-http-auth \
        --enable-doh \
        --enable-mime \
        --enable-dateparse \
        --enable-netrc \
        --enable-progress-meter \
        --enable-dnsshuffle \
        --enable-get-easy-options \
        --enable-hsts \
        --without-ca-path \
        --without-ca-bundle \
        --without-ca-fallback
    )

    # NOTE: 'make clean' deletes src/tool_hugehelp.c and docs/curl.1. Next,
    #       'make' regenerates them, including the current date in curl.1,
    #       and breaking reproducibility. tool_hugehelp.c might also be
    #       reflowed/hyphened differently than the source distro, breaking
    #       reproducibility again. Skip the clean phase to resolve it.

    if [ "${pass}" = 'shared' ]; then
      # Skip building shared version curl.exe. The build itself works, but
      # then autotools tries to create its "ltwrapper", and fails. This only
      # seems to happen when building curl against more than one dependency.
      # I have found no way to skip building that component, even though
      # we do not need it. Skip this pass altogether.
      VERSIONINFO='-avoid-version'
      [ -n "${_CURL_DLL_SUFFIX_NODASH}" ] && VERSIONINFO="-release '${_CURL_DLL_SUFFIX_NODASH}' ${VERSIONINFO}"
      make "VERSIONINFO=${VERSIONINFO}" \
        --directory="${_BLDDIR}-${pass}/lib" --jobs="${_JOBS}" install "DESTDIR=$(pwd)/${_PKGDIR}" # >/dev/null # V=1
    else
      make --directory="${_BLDDIR}-${pass}" --jobs="${_JOBS}" install "DESTDIR=$(pwd)/${_PKGDIR}" # >/dev/null # V=1
    fi

    # Manual copy to DESTDIR

    if [ "${pass}" = 'shared' ]; then
      cp -p "${_BLDDIR}-${pass}/lib/${_DEF_NAME}" "${_PP}"/bin/
    fi

    if [ "${CW_MAP}" = '1' ]; then
      if [ "${pass}" = 'shared' ]; then
        cp -p "${_BLDDIR}-${pass}/lib/${_MAP_NAME}" "${_PP}"/bin/
      else
        cp -p "${_BLDDIR}-${pass}/src/${_MAP_NAME}" "${_PP}"/bin/
      fi
    fi
  done

  # Build fixups

  chmod -x "${_PP}"/lib/*.a

  . ../curl-pkg.sh
)
