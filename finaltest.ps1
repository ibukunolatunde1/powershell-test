function Get-KuduApiAuthorisationHeaderValue($userName, $password) {
    $creds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${userName}:${password}")));
    return $creds;
}

function Do-KuduZipFile($method, $url, $localPath, $username, $password) {
    $token = Get-KuduApiAuthorisationHeaderValue $username $password;
    Write-Host $env:TEMP;
    try
    {
        $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
        [Net.ServicePointManager]::SecurityProtocol = $AllProtocols;
        Invoke-RestMethod -Uri $url `
                        -Headers @{ Authorization = "Basic $token"; Accept = '*/*' } `
                        -Method $method `
                        -OutFile $localPath `
                        -ContentType 'multipart/form-data'
    } catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        if (-not ($_.Exception.Response.StatusCode.value__ -eq 404)) {
            throw $PSItem
        }
    }    
}

# function Put-KuduZipFile($method, $url, $localPath, $username, $password) {
#     $token = Get-KuduApiAuthorisationHeaderValue $username $password;
#     Write-Host $env:TEMP;
#     try
#     {
#         $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
#         [Net.ServicePointManager]::SecurityProtocol = $AllProtocols;
#         Invoke-RestMethod -Uri $url `
#                         -Headers @{ Authorization = "Basic $token" } `
#                         -Method $method `
#                         -InFile $localPath `
#                         -ContentType "multipart/form-data"
#     } catch {
#         Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
#         Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
#         if (-not ($_.Exception.Response.StatusCode.value__ -eq 404)) {
#             throw $PSItem
#         }
#     }    
# }

function Get-Credentials($app, $resourceName, $resourceGroupName) {
       $resourceType = "Microsoft.Web/sites/config";
       $publishingCredentials = Invoke-AzResourceAction `
                     -ResourceGroupName $app.ResourceGroup`
                     -ResourceType $resourceType `
                     -ResourceName $resourceName `
                     -Action list `
                     -Force;
       return $publishingCredentials;
}

# function Get-SlotCredentials($app, $resourceName, $resourceGroupName) {
#     $resourceType = "Microsoft.Web/sites/slots/config";
#     $publishingCredentials = Invoke-AzResourceAction `
#                   -ResourceGroupName $app.ResourceGroup`
#                   -ResourceType $resourceType `
#                   -ResourceName $resourceName `
#                   -Action list `
#                   -Force;
#     return $publishingCredentials;
# }


$localPath = "$Env:BUILD_STAGINGDIRECTORY";
# Write-Host "localPath: $localPath";

$resourceGroupName = "rg-eazyloan-dev";
$appname = "app-eazyloan-dev-weu";
$app = Get-AzWebApp -ResourceGroupName $resourcegroupname -Name $appname;
$resourceName = "$($app.Name)/publishingcredentials";
$resourceType = "Microsoft.Web/sites/config";

$publishingCredentials = Get-Credentials $app $resourceName $resourceGroupName;

$method = 'Get';
$productionUsername = $publishingCredentials.Properties.PublishingUserName;
$productionPassword = $publishingCredentials.Properties.PublishingPassword;
$productionUrl = "https://$($app.Name).scm.azurewebsites.net/api/zip/site/wwwroot/";

Do-KuduZipFile $method $productionUrl $localPath $productionUsername $productionPassword;

Get-ChildItem $Env:BUILD_STAGINGDIRECTORY;

# $stagingApp = Get-AzWebAppSlot -ResourceGroupName $resourceGroupName -Name $appname -Slot "staging";
# $stagingResourceName = "$($stagingApp.Name)/publishingcredentials";

# $publishingCredentials = Get-SlotCredentials $stagingApp $stagingResourceName $resourceGroupName;

# $stagingMethod = 'Put';
# $stagingUsername = $publishingCredentials.Properties.PublishingUserName;
# $stagingPassword = $publishingCredentials.Properties.PublishingPassword;
# $stagingUrl = "https://$($stagingApp.Name).scm.azurewebsites.net/api/zipdeploy";



# Put-KuduZipFile $stagingMethod $stagingUrl $localPath $stagingUsername $stagingPassword;