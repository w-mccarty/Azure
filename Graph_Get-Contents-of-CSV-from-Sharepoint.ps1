#requires Sites.Read.All permission

function Get-GraphData {
# Based on https://danielchronlund.com/2018/11/19/fetch-data-from-microsoft-graph-with-powershell-paging-support/
# GET data from Microsoft Graph.
    param (
        [parameter(Mandatory = $true)]
        $AccessToken,

        [parameter(Mandatory = $true)]
        $Uri
    )

    # Check if authentication was successful.
    if ($AccessToken) {
    $Headers = @{
         'Content-Type'  = "application\json"
         'Authorization' = "Bearer $AccessToken" 
         'ConsistencyLevel' = "eventual"  }

        # Create an empty array to store the result.
        $QueryResults = @()

        # Invoke REST method and fetch data until there are no pages left.
        do {
            $Results = ""
            $StatusCode = ""

            do {
                try {
                    $Results = Invoke-RestMethod -Headers $Headers -Uri $Uri -UseBasicParsing -Method "GET" -ContentType "application/json"

                    $StatusCode = $Results.StatusCode
                } catch {
                    $StatusCode = $_.Exception.Response.StatusCode.value__

                    if ($StatusCode -eq 429) {
                        Write-Warning "Got throttled by Microsoft. Sleeping for 45 seconds..."
                        Start-Sleep -Seconds 45
                    }
                    else {
                        Write-Error $_.Exception
                    }
                }
            } while ($StatusCode -eq 429)

            if ($Results.value) {
                $QueryResults += $Results.value
            }
            else {
                $QueryResults += $Results
            }

            $uri = $Results.'@odata.nextlink'
        } until (!($uri))

        # Return the result.
        $QueryResults
    }
    else {
        Write-Error "No Access Token"
    }
}

$connection = Connect-AzAccount -Identity
$AppSecret = Get-AzKeyVaultSecret -VaultName "AutomationKeyVaul" -Name "Secret" -AsPlainText
$client_id = Get-AzKeyVaultSecret -VaultName "AutomationKeyVaul" -Name "ClientId" -AsPlainText
$tenant_id = Get-AzKeyVaultSecret -VaultName "AutomationKeyVaul" -Name "TenantId" -AsPlainText

$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" 
$restbody = @{
         grant_type    	= 'client_credentials'
         client_id     	= $applicationID 
         client_secret 	= $clientKey
         scope		= "https://graph.microsoft.com/.default"
}

$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $restbody -UseBasicParsing
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token
$headers = @{Authorization = "Bearer $token"}

#Sharepoint Variables
$sitenam = "Communication Site"
$drivename = "Documents"
$filename = "test.csv"

#find site id
$GraphUri = 'https://graph.microsoft.com/v1.0/sites/?$select=id,displayName'
[array]$GraphDatas = (Get-GraphData -Uri $GraphUri -AccessToken $Token)
$siteId = $GraphDatas | where {$_.displayName -eq $sitenam}
$siteId = ($siteId.id).split(",")
$siteId[1] 

#find drive id
$GraphUri = "https://graph.microsoft.com/v1.0/sites/$($siteId[1])/drives/"
[array]$GraphDatas = (Get-GraphData -Uri $GraphUri -AccessToken $Token)
$driveId = $GraphDatas | where {$_.name -eq $drivename}
$driveId = ($driveId.id)
$driveId 

#find file id
$GraphUri = "https://graph.microsoft.com/v1.0/sites/$($siteId[1])/drives/$($driveId)/root/children"
[array]$GraphDatas = (Get-GraphData -Uri $GraphUri -AccessToken $Token)
$fileId = $GraphDatas | where {$_.name -eq $filename}
$fileId = ($fileId.id)
$fileId

#get file contents
$GraphUri = "https://graph.microsoft.com/v1.0/sites/$($siteId[1])/drives/$($driveId)/items/$($fileId)/content"
[array]$FileData = (Get-GraphData -Uri $GraphUri -AccessToken $Token) | ConvertFrom-Csv
$FileData
