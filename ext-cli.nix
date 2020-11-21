{ stdenv, lib, fetchurl }:
let

  # Please keep the version x.y.0.z and do not update to x.y.76.z because the
  # source of the latter disappears much faster.
  version = "1.3.3";

  src = fetchurl {
    url = "https://github.com/hasura/graphql-engine/releases/download/v1.3.3/cli-ext-hasura-linux.tar.gz";
    sha1 = "3f92fraay4f88ak29dpiahlyxxfb62kp";
  };
in stdenv.mkDerivation {
  name = "hasura-cli-${version}";

  system = "x86_64-linux";

  inherit src; 
  
  # buildPhase = ":";
  
  unpackPhase = "true";

  # Extract and copy executable in $out/bin
  installPhase = ''
    mkdir -p $out/bin
    
    tar -xvzf $src -C $out/bin 
    mv $out/bin/cli-ext-hasura-linux $out/bin/hasura-cli_ext    
  '';

  
  preFixup = let
    libPath = lib.makeLibraryPath [stdenv.cc.cc];
  in ''
    orig_size=$(stat --printf=%s $out/bin/hasura-cli_ext)
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/hasura-cli_ext
    patchelf --set-rpath ${libPath} $out/bin/hasura-cli_ext
    chmod +x $out/bin/hasura-cli_ext
    new_size=$(stat --printf=%s $out/bin/hasura-cli_ext)
    ###### zeit-pkg fixing starts here.
    # we're replacing plaintext js code that looks like
    # PAYLOAD_POSITION = '1234                  ' | 0
    # [...]
    # PRELUDE_POSITION = '1234                  ' | 0
    # ^-----20-chars-----^^------22-chars------^
    # ^-- grep points here
    #
    # var_* are as described above
    # shift_by seems to be safe so long as all patchelf adjustments occur 
    # before any locations pointed to by hardcoded offsets
    var_skip=20
    var_select=22
    shift_by=$(expr $new_size - $orig_size)
    function fix_offset {
      # $1 = name of variable to adjust
      location=$(grep -obUam1 "$1" $out/bin/hasura-cli_ext | cut -d: -f1)
      location=$(expr $location + $var_skip)
      value=$(dd if=$out/bin/hasura-cli_ext iflag=count_bytes,skip_bytes skip=$location \
                 bs=1 count=$var_select status=none)
      value=$(expr $shift_by + $value)
      echo -n $value | dd of=$out/bin/hasura-cli_ext bs=1 seek=$location conv=notrunc
    }
    fix_offset PAYLOAD_POSITION
    fix_offset PRELUDE_POSITION
  '';
  dontStrip = true;

  meta = with stdenv.lib; {
    description = "Hasura CLI Extension";
    homepage = https://hasura.io/;
    license = licenses.mit;
    maintainers = with stdenv.lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
