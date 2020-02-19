# Multi-Blacklist
Combining script for multiple blacklist sources. Can be expanded to add in any IP list. 
This script queries public blacklists, combines them, and publishes
them to an s3 bucket, but any destination URL will functionally work.

The output format should be a file called combined-blacklist.txt
It will be located in the current date/time directory.
Previous blacklists will be saved in their respective date/time directory
It is recommended that this script be run via a scheduled/cron/lambda functio
It is recommended that there be another script to cleanup old entries, as desired

see https://www.cisco.com/c/en/us/support/docs/security/asa-5500-x-firepower-services/200449-Configure-IP-Blacklisting-Using-Cisco-S.html for a Cisco example

See https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000ClRvCAK for Palo Alto example

See https://www.juniper.net/documentation/en_US/release-independent/sky-atp/topics/concept/sky-atp-integrated-feeds.html for example on how to do this on Juniper

See https://www.linuxincluded.com/using-pfblockerng-on-pfsense/ for blocking on pFsense
