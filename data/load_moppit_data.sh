while IFS='' read -r LINE || [ -n "${LINE}" ]; do
    wget -4 -nc ${LINE}
done < 'mopitt_links.txt'
