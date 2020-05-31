#!/bin/sh

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (bpaassen): " username
    username=${username:-bpaassen}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1201_v003-2020m0428t120154.he5"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 2 --netrc-file "$netrc" https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1201_v003-2020m0428t120154.he5 -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1201_v003-2020m0428t120154.he5 | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1201_v003-2020m0428t120154.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1202_v003-2020m0428t120312.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1203_v003-2020m0428t120205.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1204_v003-2020m0428t120249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1205_v003-2020m0428t120234.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1206_v003-2020m0428t120133.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1207_v003-2020m0428t120200.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1208_v003-2020m0428t120228.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1209_v003-2020m0428t120228.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1210_v003-2020m0428t120142.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1211_v003-2020m0428t120132.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1212_v003-2020m0428t120952.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1213_v003-2020m0428t120201.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1214_v003-2020m0428t121051.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1215_v003-2020m0428t120118.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1216_v003-2020m0428t120132.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1217_v003-2020m0428t120952.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1218_v003-2020m0428t120233.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1219_v003-2020m0428t120204.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1220_v003-2020m0428t120241.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1221_v003-2020m0428t120118.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1222_v003-2020m0428t120201.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1223_v003-2020m0428t121009.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1224_v003-2020m0428t120248.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1225_v003-2020m0428t121008.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1226_v003-2020m0428t120154.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1227_v003-2020m0428t121036.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1228_v003-2020m0428t121000.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1229_v003-2020m0428t121006.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1230_v003-2020m0428t120948.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2019/OMI-Aura_L3-OMNO2d_2019m1231_v003-2020m0428t121051.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0101_v003-2020m0330t173100.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0102_v003-2020m0330t173624.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0103_v003-2020m0330t173624.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0104_v003-2020m0330t173631.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0105_v003-2020m0330t174158.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0106_v003-2020m0330t174145.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0107_v003-2020m0330t174719.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0108_v003-2020m0330t173618.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0109_v003-2020m0330t174149.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0110_v003-2020m0330t174148.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0111_v003-2020m0330t174145.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0112_v003-2020m0330t174734.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0113_v003-2020m0330t174730.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0114_v003-2020m0330t174842.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0115_v003-2020m0330t174710.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0116_v003-2020m0330t174157.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0117_v003-2020m0330t174148.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0118_v003-2020m0330t174723.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0119_v003-2020m0330t174733.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0120_v003-2020m0330t174711.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0121_v003-2020m0330t174718.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0122_v003-2020m0330t174716.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0123_v003-2020m0330t175242.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0124_v003-2020m0330t175241.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0125_v003-2020m0330t175242.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0126_v003-2020m0330t175248.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0127_v003-2020m0330t175248.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0128_v003-2020m0330t175244.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0129_v003-2020m0330t175804.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0130_v003-2020m0330t175758.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0131_v003-2020m0330t175802.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0201_v003-2020m0330t175752.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0202_v003-2020m0330t175757.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0203_v003-2020m0330t180305.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0204_v003-2020m0330t175753.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0205_v003-2020m0330t175803.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0206_v003-2020m0330t180307.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0207_v003-2020m0330t180823.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0208_v003-2020m0330t180814.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0209_v003-2020m0330t180402.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0210_v003-2020m0330t180348.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0211_v003-2020m0330t180349.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0212_v003-2020m0330t180311.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0213_v003-2020m0330t180826.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0214_v003-2020m0330t180836.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0215_v003-2020m0330t180824.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0216_v003-2020m0330t180835.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0217_v003-2020m0330t180816.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0218_v003-2020m0330t180807.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0219_v003-2020m0330t180814.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0220_v003-2020m0330t180812.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0221_v003-2020m0330t180816.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0222_v003-2020m0330t181342.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0223_v003-2020m0330t181342.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0224_v003-2020m0330t181346.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0225_v003-2020m0330t181346.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0226_v003-2020m0330t181915.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0227_v003-2020m0330t182507.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0228_v003-2020m0330t181342.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0229_v003-2020m0330t181342.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0301_v003-2020m0330t181913.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0302_v003-2020m0330t181915.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0303_v003-2020m0330t182443.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0304_v003-2020m0330t182429.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0305_v003-2020m0330t182619.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0306_v003-2020m0330t181915.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0307_v003-2020m0330t182433.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0308_v003-2020m0330t182450.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0309_v003-2020m0330t182443.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0310_v003-2020m0330t182440.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0311_v003-2020m0330t182945.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0312_v003-2020m0330t182944.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0313_v003-2020m0330t182949.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0314_v003-2020m0330t182940.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0315_v003-2020m0330t183459.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0316_v003-2020m0330t182941.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0317_v003-2020m0330t182941.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0318_v003-2020m0330t183456.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0319_v003-2020m0330t183453.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0320_v003-2020m0330t183549.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0321_v003-2020m0330t183451.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0322_v003-2020m0330t183646.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0323_v003-2020m0331t075305.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0324_v003-2020m0325t234332.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0325_v003-2020m0326t172749.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0326_v003-2020m0330t123810.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0327_v003-2020m0330t123806.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0328_v003-2020m0329t171504.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0329_v003-2020m0330t234234.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0330_v003-2020m0331t184142.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0331_v003-2020m0402t003844.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0401_v003-2020m0402t171734.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0402_v003-2020m0403t172311.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0403_v003-2020m0404t172303.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0404_v003-2020m0405t180653.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0405_v003-2020m0407t000732.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0406_v003-2020m0407t175754.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0407_v003-2020m0408t235524.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0408_v003-2020m0409t172735.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0409_v003-2020m0411t090823.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0410_v003-2020m0411t172329.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0411_v003-2020m0412t174024.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0412_v003-2020m0414t010729.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0413_v003-2020m0414t180618.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0414_v003-2020m0415t234012.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0415_v003-2020m0416t173702.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0416_v003-2020m0418t094004.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0417_v003-2020m0420t084642.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0418_v003-2020m0419t215644.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0419_v003-2020m0420t172819.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0420_v003-2020m0421t173235.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0421_v003-2020m0423t022109.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0422_v003-2020m0423t200715.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0423_v003-2020m0425t090429.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0424_v003-2020m0425t172736.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0425_v003-2020m0427t034023.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0426_v003-2020m0427t173029.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0427_v003-2020m0428t172457.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0428_v003-2020m0430t004146.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0429_v003-2020m0430t172120.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0430_v003-2020m0502t085106.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0501_v003-2020m0502t171633.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0502_v003-2020m0504t092201.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0503_v003-2020m0504t173547.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0504_v003-2020m0506t000019.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0505_v003-2020m0506t190441.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0506_v003-2020m0507t174404.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0507_v003-2020m0509t084913.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0508_v003-2020m0509t171717.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0509_v003-2020m0511t122736.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0510_v003-2020m0511t173912.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0511_v003-2020m0512t234852.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0512_v003-2020m0513t172500.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0513_v003-2020m0514t174805.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0514_v003-2020m0516t115701.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0515_v003-2020m0516t171828.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0516_v003-2020m0518t081843.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0517_v003-2020m0518t180713.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0518_v003-2020m0520t003149.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0519_v003-2020m0520t180146.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0520_v003-2020m0521t235806.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0521_v003-2020m0522t172505.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0522_v003-2020m0523t172714.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0523_v003-2020m0524t231415.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0524_v003-2020m0525t175013.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0525_v003-2020m0526t233426.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0526_v003-2020m0527t170946.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0527_v003-2020m0529t013329.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0528_v003-2020m0529t171427.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2020/OMI-Aura_L3-OMNO2d_2020m0529_v003-2020m0530t173600.he5
EDSCEOF
