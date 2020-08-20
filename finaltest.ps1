function Get-KuduApiAuthorisationHeaderValue($userName, $password) {
    $creds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${userName}:${password}")));
    return $creds;
}

function Do-KuduZipFile($method, $url, $localPath, $username, $password) {
    $token = Get-KuduApiAuthorisationHeaderValue $username $password;
    Write-Host $myheader;
    try
    {
        Invoke-RestMethod -Uri $url `
                        -Headers @{ Authorization = "Basic $token" } `
                        -Method $method `
                        -OutFile $env:TEMP\output.zip `
                        -ContentType "multipart/form-data"
    } catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        if (-not ($_.Exception.Response.StatusCode.value__ -eq 404)) {
            throw $PSItem
        }
    }    
}

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

# $localPath = $env:TEMP\output.zip
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

# $stagingAppname = "my-staging-app";
# $stagingApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $stagingAppname;
# $stagingResourceName = "$($stagingApp.Name)/publishingcredentials";

# $publishingCredentials = Get-Credentials $stagingResourceName $resourceGroupName;

# $method = 'Put';
# $stagingUsername = $publishingCredentials.Properties.PublishingUserName;
# $stagingPassword = $publishingCredentials.Properties.PublishingPassword;
# $stagingUrl = "https://$($app.Name).scm.azurewebsites.net/api/zip/site/wwwroot/Downloads/?recursive=true";



# Do-KuduZipFile $method $stagingUrl $localPath $stagingUsername $stagingPassword;
