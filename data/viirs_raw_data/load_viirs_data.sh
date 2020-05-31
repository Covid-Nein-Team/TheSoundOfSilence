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
    echo "https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.05.08/VNP13C1.A2020129.001.2020145113802.h5"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 2 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.05.08/VNP13C1.A2020129.001.2020145113802.h5 -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.05.08/VNP13C1.A2020129.001.2020145113802.h5 | tail -1)
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
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.05.08/VNP13C1.A2020129.001.2020145113802.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.04.30/VNP13C1.A2020121.001.2020137110943.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.04.22/VNP13C1.A2020113.001.2020129111952.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.04.14/VNP13C1.A2020105.001.2020122171748.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.04.06/VNP13C1.A2020097.001.2020122174245.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.03.29/VNP13C1.A2020089.001.2020122180350.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.03.21/VNP13C1.A2020081.001.2020120212139.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.03.13/VNP13C1.A2020073.001.2020114225446.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.03.05/VNP13C1.A2020065.001.2020081184151.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.02.26/VNP13C1.A2020057.001.2020085095331.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.02.18/VNP13C1.A2020049.001.2020085095332.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.02.10/VNP13C1.A2020041.001.2020057102447.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.02.02/VNP13C1.A2020033.001.2020050091528.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.01.25/VNP13C1.A2020025.001.2020041085023.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.01.17/VNP13C1.A2020017.001.2020050161112.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.01.09/VNP13C1.A2020009.001.2020050171206.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2020.01.01/VNP13C1.A2020001.001.2020050172801.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2019.12.27/VNP13C1.A2019361.001.2020014031652.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2019.12.19/VNP13C1.A2019353.001.2020007190249.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2019.12.11/VNP13C1.A2019345.001.2020003100819.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2019.12.03/VNP13C1.A2019337.001.2019353114633.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2019.11.25/VNP13C1.A2019329.001.2019346010418.h5
https://e4ftl01.cr.usgs.gov//DP101/VIIRS/VNP13C1.001/2019.11.17/VNP13C1.A2019321.001.2020016215957.h5
EDSCEOF