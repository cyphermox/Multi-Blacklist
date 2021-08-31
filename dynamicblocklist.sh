#/bin/bash
#
# This script queries public blocklists, combines them, and publishes
# them to an s3 bucket, but any destination URL will functionally work.
#
# The output format should be a file called combined-blocklist.txt
# It will be located in the current date/time directory.
# Previous blocklists will be saved in their respective date/time directory
# It is recommended that this script be run via a scheduled/cron/lambda functio
# It is recommended that there be another script to cleanup old entries, as desired
#
# Questions about this script can be sent to info@mooreinfosec.com
# This script is provided as-is, with no warranty, expressed or implied.
# It is the responsibility of the user to understand what this script does
# 
# I will add comments to this script explaining what each step does, along the way.
#
# First we create teh directory for the blocklisting. I have this done every time, because
# sometimes it's easier to just remove the entire blocklisting directory if the inode table

# or disk space gets filled up.

BUILD_PATH=./build/$(date '+%d-%b-%Y-%H-%M')
mkdir -p ${BUILD_PATH}
#
# This command sets up the aggregate data file.
# the aggregate data file is where we append things.
cp base-blocklist ${BUILD_PATH}/base-blocklist
#
# The next series of wget commands are (1) path relative, and (2) fetch public lists for dropping
# You can add in as many of these as you want, provided you add them into the cat/grep/etc at the
# end to ensure they get added to the final master-out list.
#
# SpamHaus DROP
/usr/bin/wget https://www.spamhaus.org/drop/drop.txt -O ${BUILD_PATH}/shdrop.txt
# SpamHaus EDROP
/usr/bin/wget https://www.spamhaus.org/drop/edrop.txt -O ${BUILD_PATH}/shedrop.txt
# Emerging Threats 
/usr/bin/wget https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt -O ${BUILD_PATH}/emerging.txt
# Known SSL abusers IP list
/usr/bin/wget https://sslbl.abuse.ch/blacklist/sslipblacklist.txt -O ${BUILD_PATH}/sslabuseiplist.txt
# Known TOR exit nodes
/usr/bin/wget https://check.torproject.org/exit-addresses -O ${BUILD_PATH}/exit-addresses
# FireHol.org Network List
/usr/bin/wget https://iplists.firehol.org/files/firehol_level1.netset -O ${BUILD_PATH}/firehol_level1.netset
#
# Now we begin combining the files. Cat and redirect the files to a common text file.
grep -v '^;' ${BUILD_PATH}/shdrop.txt >> ${BUILD_PATH}/base-blocklist
echo >> ${BUILD_PATH}/base-blocklist
grep -v '^;' ${BUILD_PATH}/shedrop.txt >> ${BUILD_PATH}/base-blocklist
echo >> ${BUILD_PATH}/base-blocklist
grep -v '^#' ${BUILD_PATH}/emerging.txt >> ${BUILD_PATH}/base-blocklist
echo >> ${BUILD_PATH}/base-blocklist
grep -v '^#' ${BUILD_PATH}/sslabuseiplist.txt >> ${BUILD_PATH}/base-blocklist
echo >> ${BUILD_PATH}/base-blocklist
grep ExitAddress ${BUILD_PATH}/exit-addresses | awk '{print $2;}' >> ${BUILD_PATH}/base-blocklist
echo >> ${BUILD_PATH}/base-blocklist
grep -v '^#' ${BUILD_PATH}/firehol_level1.netset >> ${BUILD_PATH}/base-blocklist
#
# Now to remove the duplicated values, as a lot of times a single host will be in multiple offending lists
sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 ${BUILD_PATH}/base-blocklist | tee ${BUILD_PATH}/block.duplicates | uniq -u >> ${BUILD_PATH}/block.addresses
#
# Now to remove lines with undesired characters (#)
sed -e '/^#/ d' -e '/^;/ d' -e 's/$//g' ${BUILD_PATH}/block.addresses > ${BUILD_PATH}/combined-blocklist.txt
#
# Now to just copy it up to the desired destination
# This can be via a scp to a public server
# copy to an s3 bucket
# or whatever
# In this case, I'm using s3 as a destination, but feel free to submit in whatever you choose. 
# Keep in mind that post writing, the file must be globally readable, as the firewall will not authenticate
# This can be an internal destination, but it must readable by the firewall
#
# I am leaving the line below commented out because I don't know what you're going to want for your upload. This is just a suggestion
# /usr/loca/bin/aws s3 cp ${BUILD_PATH}/combined-blacklist.txt s3://your-destination-host/path/
#
#
# Now you just configure your firewall to read the URL
# see https://www.cisco.com/c/en/us/support/docs/security/asa-5500-x-firepower-services/200449-Configure-IP-Blacklisting-Using-Cisco-S.html for a Cisco example
# See https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000ClRvCAK for Palo Alto
# See https://www.juniper.net/documentation/en_US/release-independent/sky-atp/topics/concept/sky-atp-integrated-feeds.html for example on how to do this on Juniper
# See https://www.linuxincluded.com/using-pfblockerng-on-pfsense/ for blocking on pFsense
