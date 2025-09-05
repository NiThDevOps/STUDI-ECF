# --- PARAMS ---
$REGION = "us-east-1"
$VPC    = "vpc-058a85dbf54bd3d82"

Write-Host "Suppression du VPC $VPC dans $REGION"

# 0) Sanity check
aws ec2 describe-vpcs --region $REGION --vpc-ids $VPC --query "Vpcs[].VpcId"

# 1) Instances
$inst = aws ec2 describe-instances --region $REGION --filters Name=vpc-id,Values=$VPC --query "Reservations[].Instances[].InstanceId" --output text
if ($inst) { aws ec2 terminate-instances --region $REGION --instance-ids $inst | Out-Null; aws ec2 wait instance-terminated --region $REGION --instance-ids $inst }

# 2) Load Balancers (ALB/NLB + Classic)
$alb = aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC'].LoadBalancerArn" --output text
if ($alb) { $alb.Split() | % { aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn $_ } }
$clb = aws elb describe-load-balancers --region $REGION --query "LoadBalancerDescriptions[?VPCId=='$VPC'].LoadBalancerName" --output text 2>$null
if ($clb) { $clb.Split() | % { aws elb delete-load-balancer --region $REGION --load-balancer-name $_ } }

# 3) VPC Endpoints (Interface + Gateway)
$vpce = aws ec2 describe-vpc-endpoints --region $REGION --filters Name=vpc-id,Values=$VPC --query "VpcEndpoints[].VpcEndpointId" --output text
if ($vpce) { aws ec2 delete-vpc-endpoints --region $REGION --vpc-endpoint-ids $vpce | Out-Null }

# 4) NAT Gateways (delete + wait deleted)
$ngws = aws ec2 describe-nat-gateways --region $REGION --filter Name=vpc-id,Values=$VPC --query "NatGateways[].NatGatewayId" --output text
if ($ngws) {
  $ngws.Split() | % { aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id $_ | Out-Null }
  do {
    Start-Sleep -Seconds 10
    $states = aws ec2 describe-nat-gateways --region $REGION --filter Name=vpc-id,Values=$VPC --query "NatGateways[].State" --output text
  } while ($states -and ($states.Split() | Where-Object { $_ -ne "deleted" }).Count -gt 0)
}

# 5) EIP (désassocier + libérer)
$eips = aws ec2 describe-addresses --region $REGION --filters Name=domain,Values=vpc --query "Addresses[].{Alloc:AllocationId,Assoc:AssociationId}" --output json
if ($eips -and $eips -ne "[]") {
  (ConvertFrom-Json $eips) | % {
    if ($_.Assoc) { aws ec2 disassociate-address --region $REGION --association-id $_.Assoc | Out-Null }
    if ($_.Alloc) { aws ec2 release-address     --region $REGION --allocation-id  $_.Alloc | Out-Null }
  }
}

# 6) ENI disponibles
$eniAvail = aws ec2 describe-network-interfaces --region $REGION --filters Name=vpc-id,Values=$VPC --query "NetworkInterfaces[?Status=='available'].NetworkInterfaceId" --output text
if ($eniAvail) { $eniAvail.Split() | % { aws ec2 delete-network-interface --region $REGION --network-interface-id $_ } }

# 7) IGW
$igw = aws ec2 describe-internet-gateways --region $REGION --filters Name=attachment.vpc-id,Values=$VPC --query "InternetGateways[].InternetGatewayId" --output text
if ($igw) {
  aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id $igw --vpc-id $VPC
  aws ec2 delete-internet-gateway  --region $REGION --internet-gateway-id $igw
}

# 8) Subnets (désassocier RT non-main puis delete)
$rtAssoc = aws ec2 describe-route-tables --region $REGION --filters Name=vpc-id,Values=$VPC --query "RouteTables[?Associations[?Main!=\`true\`]].Associations[].RouteTableAssociationId" --output text
if ($rtAssoc) { $rtAssoc.Split() | % { aws ec2 disassociate-route-table --region $REGION --association-id $_ } }
$subs = aws ec2 describe-subnets --region $REGION --filters Name=vpc-id,Values=$VPC --query "Subnets[].SubnetId" --output text
if ($subs) { $subs.Split() | % { aws ec2 delete-subnet --region $REGION --subnet-id $_ } }

# 9) Route tables non-main
$rts = aws ec2 describe-route-tables --region $REGION --filters Name=vpc-id,Values=$VPC --query "RouteTables[?Associations[?Main!=\`true\`]].RouteTableId" --output text
if ($rts) { $rts.Split() | % { aws ec2 delete-route-table --region $REGION --route-table-id $_ } }

# 10) SG non-default
$sgs = aws ec2 describe-security-groups --region $REGION --filters Name=vpc-id,Values=$VPC --query "SecurityGroups[?GroupName!='default'].GroupId" --output text
if ($sgs) { $sgs.Split() | % { aws ec2 delete-security-group --region $REGION --group-id $_ } }

# 11) NACL non-default
$acls = aws ec2 describe-network-acls --region $REGION --filters Name=vpc-id,Values=$VPC --query "NetworkAcls[?IsDefault==\`false\`].NetworkAclId" --output text
if ($acls) { $acls.Split() | % { aws ec2 delete-network-acl --region $REGION --network-acl-id $_ } }

# 12) DHCP options -> default (sécurisé)
$dhcp = aws ec2 describe-vpcs --region $REGION --vpc-ids $VPC --query "Vpcs[0].DhcpOptionsId" --output text 2>$null
if ($dhcp -and $dhcp -ne "default" -and $dhcp -ne $null -and $dhcp -ne "") { aws ec2 associate-dhcp-options --region $REGION --dhcp-options-id default --vpc-id $VPC }

# 13) Delete VPC
aws ec2 delete-vpc --region $REGION --vpc-id $VPC
Write-Host "Suppression demandée pour $VPC dans $REGION."