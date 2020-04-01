az network vnet peering create -g RG-AZEUW-NETWORK-0001-DEV -n VNET-AZEUW-HUB-0001-DEV-VNET-AZEUW-SPOKE-0001-DEV --vnet-name VNET-AZEUW-HUB-0001-DEV --remote-vnet VNET-AZEUW-SPOKE-0001-DEV --allow-vnet-access --allow-gateway-transit
NETSPOKEEU1=$(az network vnet list --query "[?contains(name, 'VNET-AZEU1-SPOKE-0001-DEV')]")
az network vnet peering create -g RG-AZEUW-NETWORK-0001-DEV -n VNET-AZEUW-HUB-0001-DEV-VNET-AZEU1-SPOKE-0001-DEV --vnet-name VNET-AZEUW-HUB-0001-DEV --remote-vnet $(echo $(echo $NETSPOKEEU1 | jq first.id) | sed -e 's/^"//' -e 's/"$//') --allow-vnet-access --allow-gateway-transit
NETHUBEUW=$(az network vnet list --query "[?contains(name, 'VNET-AZEUW-HUB-0001-DEV')]")
NETHUB=$(echo $NETHUBEUW | jq first.id)
az network vnet peering create -g RG-AZEUW-NETWORK-0001-DEV -n VNET-AZEUW-SPOKE-0001-DEV-VNET-AZEUW-HUB-0001-DEV --vnet-name VNET-AZEUW-SPOKE-0001-DEV --remote-vnet $(echo $NETHUB | sed -e 's/^"//' -e 's/"$//') --allow-vnet-access --use-remote-gateways
az network vnet peering create -g RG-AZEU1-NETWORK-0001-DEV -n VNET-AZEU1-SPOKE-0001-DEV-VNET-AZEUW-HUB-0001-DEV --vnet-name VNET-AZEU1-SPOKE-0001-DEV --remote-vnet $(echo $NETHUB | sed -e 's/^"//' -e 's/"$//') --allow-vnet-access --use-remote-gateways