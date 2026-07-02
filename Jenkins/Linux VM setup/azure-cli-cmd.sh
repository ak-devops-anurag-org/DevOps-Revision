$RESOURCE_GROUP = "Jenkins-RG"
$LOCATION = "centralindia"
$VM_NAME = "Jenkins-VM"
$ADMIN_USER = "ak"
$ADMIN_PASSWORD = "Hello@123456"
$VM_SIZE = "Standard_B2s"
$IMAGE = "Ubuntu2204"
$DISK_SIZE = 30


# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION
# Create VM with password authentication
az vm create `
  --resource-group $RESOURCE_GROUP `
  --name $VM_NAME `
  --image $IMAGE `
  --size $VM_SIZE `
  --admin-username $ADMIN_USER `
  --admin-password $ADMIN_PASSWORD `
  --authentication-type password `
  --os-disk-size-gb $DISK_SIZE `
  --custom-data ./init.sh `
  --nsg-rule SSH

# Open Jenkins port 8080
az vm open-port --resource-group $RESOURCE_GROUP --name $VM_NAME --port 8080 --priority 1001

# Get VM public IP
$PUBLIC_IP = az vm show -d -g $RESOURCE_GROUP -n $VM_NAME --query publicIps -o tsv








Write-Host "========================================" -ForegroundColor Green
Write-Host "Jenkins VM Deployed Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "VM Details:"
Write-Host "  Username: $ADMIN_USER"
Write-Host "  Password: $ADMIN_PASSWORD"
Write-Host "  Public IP: $PUBLIC_IP"
Write-Host ""
Write-Host "SSH Connection:"
Write-Host "  ssh $ADMIN_USER@$PUBLIC_IP"
Write-Host "  (Password: $ADMIN_PASSWORD)"
Write-Host ""
Write-Host "Jenkins URL:"
Write-Host "  http://${PUBLIC_IP}:8080"
Write-Host ""
Write-Host "To get Jenkins initial admin password:"
Write-Host "  ssh $ADMIN_USER@$PUBLIC_IP"
Write-Host "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"