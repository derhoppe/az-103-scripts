MYID=1
MYIDEU=$(expr $MYID + 200)
MYIDUS=$(expr $MYID + 100)
VNETHUB="10."$MYID".0.0/16"
VNETSPOKEEU="10."$MYIDEU".0.0/16"
VNETSPOKEUS="10."$MYIDUS".0.0/16"
VNETHUB_internal="10."$MYID".1.0/24"
VNETHUB_gateway="10."$MYID".9.0/27"
VNETHUB_firewall="10."$MYID".10.0/24"
VNETHUB_management="10."$MYID".2.0/24"
VNETHUB_dmzext="10."$MYID".13.0/24"
VNETSPOKEEU_internal="10."$MYIDEU".1.0/24"
VNETSPOKEUS_internal="10."$MYIDUS".1.0/24"
VNETSPOKEEU_workload="10."$MYIDEU".2.0/24"
VNETSPOKEEU_workload_LBIP="10."$MYIDEU".2.100"
VNETSPOKEUS_workload="10."$MYIDUS".2.0/24"
VNETSPOKEUS_workload_LBIP="10."$MYIDUS".2.100"
wget https://raw.githubusercontent.com/derhoppe/az-103-scripts/master/yaml/cloud-init.yaml
az group create -n RG-AZEUW-COMPUTE-0001-DEV --location westeurope --tags "delete=yes"
az group create -n RG-AZEU1-COMPUTE-0001-DEV --location eastus --tags "delete=yes"
az group create -n RG-AZEUW-NETWORK-0001-DEV --location westeurope --tags "delete=yes"
az group create -n RG-AZEU1-NETWORK-0001-DEV --location eastus --tags "delete=yes"
NETHUBEUW=$(az network vnet create -g RG-AZEUW-NETWORK-0001-DEV -n VNET-AZEUW-HUB-0001-DEV --address-prefix $VNETHUB --subnet-name internal --subnet-prefix $VNETHUB_internal)
NETSPOKEEUW=$(az network vnet create -g RG-AZEUW-NETWORK-0001-DEV -n VNET-AZEUW-SPOKE-0001-DEV --address-prefix $VNETSPOKEEU --subnet-name internal --subnet-prefix $VNETSPOKEEU_internal)
NETSPOKEEU1=$(az network vnet create -g RG-AZEU1-NETWORK-0001-DEV -n VNET-AZEU1-SPOKE-0001-DEV --address-prefix $VNETSPOKEUS --subnet-name internal --subnet-prefix $VNETSPOKEUS_internal)
az network vnet subnet create -n GatewaySubnet --vnet-name VNET-AZEUW-HUB-0001-DEV -g RG-AZEUW-NETWORK-0001-DEV --address-prefixes $VNETHUB_gateway
az network vnet subnet create -n AzureFirewallSubnet --vnet-name VNET-AZEUW-HUB-0001-DEV -g RG-AZEUW-NETWORK-0001-DEV --address-prefixes $VNETHUB_firewall
az network vnet subnet create -n management --vnet-name VNET-AZEUW-HUB-0001-DEV -g RG-AZEUW-NETWORK-0001-DEV --address-prefixes $VNETHUB_management
az network vnet subnet create -n dmzext --vnet-name VNET-AZEUW-HUB-0001-DEV -g RG-AZEUW-NETWORK-0001-DEV --address-prefixes $VNETHUB_dmzext
az network vnet subnet create -n workload --vnet-name VNET-AZEUW-SPOKE-0001-DEV -g RG-AZEUW-NETWORK-0001-DEV --address-prefixes $VNETSPOKEEU_workload
az network vnet subnet create -n workload --vnet-name VNET-AZEU1-SPOKE-0001-DEV -g RG-AZEU1-NETWORK-0001-DEV --address-prefixes $VNETSPOKEUS_workload
SUBEUW=$(az network vnet subnet show --resource-group 'RG-AZEUW-NETWORK-0001-DEV' --name workload --vnet-name 'VNET-AZEUW-SPOKE-0001-DEV' --query id -o tsv)
SUBEU1=$(az network vnet subnet show --resource-group 'RG-AZEU1-NETWORK-0001-DEV' --name workload --vnet-name 'VNET-AZEU1-SPOKE-0001-DEV' --query id -o tsv)
az network lb create -g RG-AZEUW-NETWORK-0001-DEV --name ILB-AZEUW-WEB-0001-DEV --sku Standard --subnet $SUBEUW --frontend-ip-name LBFE --backend-pool-name BP-AZEUW-WEB-0001-DEV --private-ip-address $VNETSPOKEEU_workload_LBIP
az network lb create -g RG-AZEU1-NETWORK-0001-DEV --name ILB-AZEU1-WEB-0001-DEV --sku Standard --subnet $SUBEU1 --frontend-ip-name LBFE --backend-pool-name BP-AZEU1-WEB-0001-DEV --private-ip-address $VNETSPOKEUS_workload_LBIP
LBAPEUW=$(az network lb address-pool list --lb-name ILB-AZEUW-WEB-0001-DEV -g RG-AZEUW-NETWORK-0001-DEV)
LBAPEU1=$(az network lb address-pool list --lb-name ILB-AZEU1-WEB-0001-DEV -g RG-AZEU1-NETWORK-0001-DEV)
az network lb probe create -g RG-AZEUW-NETWORK-0001-DEV --name HP-AZEUW-WEB-0001-DEV --lb-name ILB-AZEUW-WEB-0001-DEV --port 80 --protocol http --path /
az network lb probe create -g RG-AZEU1-NETWORK-0001-DEV --name HP-AZEU1-WEB-0001-DEV --lb-name ILB-AZEU1-WEB-0001-DEV --port 80 --protocol http --path /
LBRULEEUW=$(az network lb rule create -g RG-AZEUW-NETWORK-0001-DEV --lb-name ILB-AZEUW-WEB-0001-DEV -n LBR-AZEUW-WEB-0001-DEV --protocol Tcp --frontend-ip-name LBFE --frontend-port 80 --backend-pool-name BP-AZEUW-WEB-0001-DEV --backend-port 80)
LBRULEEU1=$(az network lb rule create -g RG-AZEU1-NETWORK-0001-DEV --lb-name ILB-AZEU1-WEB-0001-DEV -n LBR-AZEU1-WEB-0001-DEV --protocol Tcp --frontend-ip-name LBFE --frontend-port 80 --backend-pool-name BP-AZEU1-WEB-0001-DEV --backend-port 80)
NETZEUW=$(echo $NETSPOKEEUW | jq .newVNet.name)
NETZEU1=$(echo $NETSPOKEEU1 | jq .newVNet.name)
NETHUB=$(echo $NETHUBEUW | jq .newVNet.id)
LBEUW=$(echo $LBAPEUW | jq first.id)
LBEU1=$(echo $LBAPEU1| jq first.id)
NICAZEUW1=$(az network nic create -g RG-AZEUW-COMPUTE-0001-DEV --name NIC-AZEUW-SRVAZEUW0001-DEV --subnet $SUBEUW) 
NICAZEUWID1=$(echo $NICAZEUW1 | jq .NewNIC.id)
NICAZEUW2=$(az network nic create -g RG-AZEUW-COMPUTE-0001-DEV --name NIC-AZEUW-SRVAZEUW0002-DEV --subnet $SUBEUW) 
NICAZEUWID2=$(echo $NICAZEUW2 | jq .NewNIC.id)
NICAZEU11=$(az network nic create -g RG-AZEU1-COMPUTE-0001-DEV --name NIC-AZEU1-SRVAZEU10001-DEV --subnet $SUBEU1) 
NICAZEU1ID1=$(echo $NICAZEU11 | jq .NewNIC.id)
NICAZEU12=$(az network nic create -g RG-AZEU1-COMPUTE-0001-DEV --name NIC-AZEU1-SRVAZEU10002-DEV --subnet $SUBEU1)
NICAZEU1ID2=$(echo $NICAZEU12 | jq .NewNIC.id)
NICAZEUW1=$(az network nic list --query "[?contains(name, 'NIC-AZEUW-SRVAZEUW0001-DEV')]")
NICAZEUWID1=$(echo $NICAZEUW1 | jq first.id)
NICAZEUW2=$(az network nic list --query "[?contains(name, 'NIC-AZEUW-SRVAZEUW0002-DEV')]")
NICAZEUWID2=$(echo $NICAZEUW2 | jq first.id)
NICAZEU11=$(az network nic list --query "[?contains(name, 'NIC-AZEU1-SRVAZEU10001-DEV')]")
NICAZEU1ID1=$(echo $NICAZEU11 | jq first.id)
NICAZEU12=$(az network nic list --query "[?contains(name, 'NIC-AZEU1-SRVAZEU10002-DEV')]")
NICAZEU1ID2=$(echo $NICAZEU12 | jq first.id)
az vm create --resource-group RG-AZEUW-COMPUTE-0001-DEV --name SRVAZEUW0001 --image UbuntuLTS --admin-username student --admin-password 'Pa$$w.rd12345' --size Standard_DS1_v2 --custom-data cloud-init.yaml --nics $(echo $NICAZEUWID1 | sed -e 's/^"//' -e 's/"$//' )
az vm create --resource-group RG-AZEUW-COMPUTE-0001-DEV --name SRVAZEUW0002 --image UbuntuLTS --admin-username student --admin-password 'Pa$$w.rd12345' --size Standard_DS1_v2 --custom-data cloud-init.yaml --nics $(echo $NICAZEUWID2 | sed -e 's/^"//' -e 's/"$//' )
az vm create --resource-group RG-AZEU1-COMPUTE-0001-DEV --name SRVAZEU10001 --image UbuntuLTS --admin-username student --admin-password 'Pa$$w.rd12345' --size Standard_DS1_v2 --custom-data cloud-init.yaml --nics $(echo $NICAZEU1ID1 | sed -e 's/^"//' -e 's/"$//' )
az vm create --resource-group RG-AZEU1-COMPUTE-0001-DEV --name SRVAZEU10002 --image UbuntuLTS --admin-username student --admin-password 'Pa$$w.rd12345' --size Standard_DS1_v2 --custom-data cloud-init.yaml --nics $(echo $NICAZEU1ID2 | sed -e 's/^"//' -e 's/"$//' )
LBAPEUW=$(az network lb address-pool list --lb-name ILB-AZEUW-WEB-0001-DEV -g RG-AZEUW-NETWORK-0001-DEV)
LBAPEU1=$(az network lb address-pool list --lb-name ILB-AZEU1-WEB-0001-DEV -g RG-AZEU1-NETWORK-0001-DEV)
LBEUW=$(echo $LBAPEUW | jq first.id)
LBEU1=$(echo $LBAPEU1| jq first.id)
az network nic ip-config update -g RG-AZEUW-COMPUTE-0001-DEV --nic-name NIC-AZEUW-SRVAZEUW0001-DEV -n ipconfig1 --lb-address-pools $(echo $LBEUW | sed -e 's/^"//' -e 's/"$//')
az network nic ip-config update -g RG-AZEUW-COMPUTE-0001-DEV --nic-name NIC-AZEUW-SRVAZEUW0002-DEV -n ipconfig1 --lb-address-pools $(echo $LBEUW | sed -e 's/^"//' -e 's/"$//')
az network nic ip-config update -g RG-AZEU1-COMPUTE-0001-DEV --nic-name NIC-AZEU1-SRVAZEU10001-DEV -n ipconfig1 --lb-address-pools $(echo $LBEU1 | sed -e 's/^"//' -e 's/"$//')
az network nic ip-config update -g RG-AZEU1-COMPUTE-0001-DEV --nic-name NIC-AZEU1-SRVAZEU10002-DEV -n ipconfig1 --lb-address-pools $(echo $LBEU1 | sed -e 's/^"//' -e 's/"$//')
az extension add -n azure-firewall
az network firewall create --name AFW-AZEUW-0001-DEV --resource-group RG-AZEUW-NETWORK-0001-DEV --location westeurope
PIPFW=$(az network public-ip create -g RG-AZEUW-NETWORK-0001-DEV -n PIP-AFW-AZEUW-0001-DEV --allocation-method Static --sku Standard)
PIPFWID=$(echo $PIPFW | jq .publicIp.id)
az network firewall ip-config create --firewall-name AFW-AZEUW-0001-DEV --name FEIP --public-ip-address $(echo $PIPFWID | sed -e 's/^"//' -e 's/"$//') --resource-group RG-AZEUW-NETWORK-0001-DEV --vnet-name VNET-AZEUW-HUB-0001-DEV
FW=$(az network firewall list --query "[?contains(name, 'AFW-AZEUW-0001-DEV')]")
FWIP=$(echo $FW | jq first.ipConfigurations | jq first.privateIpAddress)
az network route-table create --name RT-AZEUW-TOFIREWALL --resource-group RG-AZEUW-NETWORK-0001-DEV --disable-bgp-route-propagation true
az network route-table route create --address-prefix 0.0.0.0/0 --name toFirewall --next-hop-type VirtualAppliance --resource-group RG-AZEUW-NETWORK-0001-DEV --route-table-name RT-AZEUW-TOFIREWALL --next-hop-ip-address $(echo $FWIP | sed -e 's/^"//' -e 's/"$//')
az network asg create --name ASG-AZEUW-WEB-0001-DEV --resource-group RG-AZEUW-NETWORK-0001-DEV
az network nsg create --name NSG-AZEUW-VNET-AZEUW-SPOKE-0001-DEV-workload --resource-group RG-AZEUW-NETWORK-0001-DEV
SUBHUB=$(az network vnet subnet show --resource-group 'RG-AZEUW-NETWORK-0001-DEV' --name management --vnet-name 'VNET-AZEUW-HUB-0001-DEV' --query addressPrefix -o tsv)
az network nsg rule create --name Deny-all --nsg-name NSG-AZEUW-VNET-AZEUW-SPOKE-0001-DEV-workload --priority 2050 --resource-group RG-AZEUW-NETWORK-0001-DEV --access Deny --protocol '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --direction Inbound --source-address-prefixes '*'
az network nsg rule create --name Allow-AZLB --nsg-name NSG-AZEUW-VNET-AZEUW-SPOKE-0001-DEV-workload --priority 2040 --resource-group RG-AZEUW-NETWORK-0001-DEV --access Allow --protocol '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --direction Inbound --source-address-prefixes AzureLoadBalancer
az network nsg rule create --name Allow-80 --nsg-name NSG-AZEUW-VNET-AZEUW-SPOKE-0001-DEV-workload --priority 2030 --resource-group RG-AZEUW-NETWORK-0001-DEV --access Allow --protocol '*' --source-port-ranges '*' --destination-asgs ASG-AZEUW-WEB-0001-DEV --destination-port-ranges 80 --direction Inbound --source-address-prefixes VirtualNetwork
az network nsg rule create --name Allow-management-22 --nsg-name NSG-AZEUW-VNET-AZEUW-SPOKE-0001-DEV-workload --priority 2020 --resource-group RG-AZEUW-NETWORK-0001-DEV --access Allow --protocol '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --direction Inbound --source-address-prefixes $SUBHUB
ASGID=$(az network asg show -g RG-AZEUW-NETWORK-0001-DEV --name ASG-AZEUW-WEB-0001-DEV --query id -o tsv)
az network nic ip-config update -g RG-AZEUW-COMPUTE-0001-DEV --nic-name NIC-AZEUW-SRVAZEUW0001-DEV -n ipconfig1 --application-security-groups $ASGID
az network nic ip-config update -g RG-AZEUW-COMPUTE-0001-DEV --nic-name NIC-AZEUW-SRVAZEUW0002-DEV -n ipconfig1 --application-security-groups $ASGID
az network vnet subnet update -g RG-AZEUW-NETWORK-0001-DEV -n workload --vnet-name VNET-AZEUW-SPOKE-0001-DEV --network-security-group NSG-AZEUW-VNET-AZEUW-SPOKE-0001-DEV-workload
az network asg create --name ASG-AZEU1-WEB-0001-DEV --resource-group RG-AZEU1-NETWORK-0001-DEV
az network nsg create --name NSG-AZEU1-VNET-AZEU1-SPOKE-0001-DEV-workload --resource-group RG-AZEU1-NETWORK-0001-DEV
SUBHUB=$(az network vnet subnet show --resource-group 'RG-AZEUW-NETWORK-0001-DEV' --name management --vnet-name 'VNET-AZEUW-HUB-0001-DEV' --query addressPrefix -o tsv)
az network nsg rule create --name Deny-all --nsg-name NSG-AZEU1-VNET-AZEU1-SPOKE-0001-DEV-workload --priority 2050 --resource-group RG-AZEU1-NETWORK-0001-DEV --access Deny --protocol '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --direction Inbound --source-address-prefixes '*'
az network nsg rule create --name Allow-AZLB --nsg-name NSG-AZEU1-VNET-AZEU1-SPOKE-0001-DEV-workload --priority 2040 --resource-group RG-AZEU1-NETWORK-0001-DEV --access Allow --protocol '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --direction Inbound --source-address-prefixes AzureLoadBalancer
az network nsg rule create --name Allow-80 --nsg-name NSG-AZEU1-VNET-AZEU1-SPOKE-0001-DEV-workload --priority 2030 --resource-group RG-AZEU1-NETWORK-0001-DEV --access Allow --protocol '*' --source-port-ranges '*' --destination-asgs ASG-AZEU1-WEB-0001-DEV --destination-port-ranges 80 --direction Inbound --source-address-prefixes VirtualNetwork
az network nsg rule create --name Allow-management-22 --nsg-name NSG-AZEU1-VNET-AZEU1-SPOKE-0001-DEV-workload --priority 2020 --resource-group RG-AZEU1-NETWORK-0001-DEV --access Allow --protocol '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --direction Inbound --source-address-prefixes $SUBHUB
ASGID=$(az network asg show -g RG-AZEU1-NETWORK-0001-DEV --name ASG-AZEU1-WEB-0001-DEV --query id -o tsv)
az network nic ip-config update -g RG-AZEU1-COMPUTE-0001-DEV --nic-name NIC-AZEU1-SRVAZEU10001-DEV -n ipconfig1 --application-security-groups $ASGID
az network nic ip-config update -g RG-AZEU1-COMPUTE-0001-DEV --nic-name NIC-AZEU1-SRVAZEU10002-DEV -n ipconfig1 --application-security-groups $ASGID
az network vnet subnet update -g RG-AZEU1-NETWORK-0001-DEV -n workload --vnet-name VNET-AZEU1-SPOKE-0001-DEV --network-security-group NSG-AZEU1-VNET-AZEU1-SPOKE-0001-DEV-workload
NETHUBEUW=$(az network vnet list --query "[?contains(name, 'VNET-AZEUW-HUB-0001-DEV')]")
NETHUB=$(echo $NETHUBEUW | jq first.id)
SUBHUB=$(az network vnet subnet show --resource-group 'RG-AZEUW-NETWORK-0001-DEV' --name dmzext --vnet-name 'VNET-AZEUW-HUB-0001-DEV' --query id -o tsv)
PIPAG=$(az network public-ip create -g RG-AZEUW-NETWORK-0001-DEV -n PIP-AG-AZEUW-0001-DEV --allocation-method Static --sku Standard)
PIPAGID=$(echo $PIPAG | jq .publicIp.id)
az network application-gateway create --name AG-AZEUW-0001-DEV --resource-group RG-AZEUW-NETWORK-0001-DEV --sku WAF_v2 --http-settings-protocol Http --http-settings-port 80 --max-capacity 3 --min-capacity 2 --vnet-name $(echo $NETHUB | sed -e 's/^"//' -e 's/"$//') --subnet $SUBHUB --public-ip-address $(echo $PIPAGID | sed -e 's/^"//' -e 's/"$//')
az network application-gateway probe create --gateway-name AG-AZEUW-0001-DEV --name PROBE-80 --path / --protocol Http --resource-group RG-AZEUW-NETWORK-0001-DEV --host-name-from-http-settings true
LBIP1=$(az network lb list --query "[?contains(name, 'LB-AZEUW-WEB-0001-DEV')]" | jq first.frontendIpConfigurations | jq first.privateIpAddress)
LBIP2=$(az network lb list --query "[?contains(name, 'LB-AZEU1-WEB-0001-DEV')]" | jq first.frontendIpConfigurations | jq first.privateIpAddress)
az network application-gateway address-pool update -g RG-AZEUW-NETWORK-0001-DEV --gateway-name AG-AZEUW-0001-DEV -n appGatewayBackendPool --servers $(echo $LBIP1 | sed -e 's/^"//' -e 's/"$//') $(echo $LBIP2 | sed -e 's/^"//' -e 's/"$//')
PIPVPN=$(az network public-ip create -g RG-AZEUW-NETWORK-0001-DEV -n PIP-VPNGW-AZEUW-0001-DEV --allocation-method Dynamic)
PIPVPNID=$(echo $PIPVPN | jq .publicIp.id)
az network vnet-gateway create -g RG-AZEUW-NETWORK-0001-DEV -n VPNGW-AZEUW-0001-DEV --public-ip-address $(echo $PIPVPNID | sed -e 's/^"//' -e 's/"$//') --vnet $(echo $NETHUB | sed -e 's/^"//' -e 's/"$//') --gateway-type Vpn --sku VpnGw1 --vpn-type RouteBased --address-prefixes 192.168.0.0/24 --client-protocol SSTP
