# rb-generate-ovpn-profile
Script generate OVPN profile.

# Export všech certifikátů
:foreach item in=[/certificate find] do={/certificate export-certificate $item export-passphrase=xxxx }
