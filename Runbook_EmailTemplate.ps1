$connection = Connect-AzAccount -Identity
$AppSecret = Get-AzKeyVaultSecret -VaultName "AutomationKeyVaul" -Name "Secret" -AsPlainText
$client_id = Get-AzKeyVaultSecret -VaultName "AutomationKeyVaul" -Name "ClientId" -AsPlainText
$tenant_id = Get-AzKeyVaultSecret -VaultName "AutomationKeyVaul" -Name "TenantId" -AsPlainText
$fromAddress = Get-AzKeyVaultSecret -VaultName "AutomationKeyVaul" -Name "Sender" -AsPlainText
$toAddress = 'name@domain.com'
$mailSubject = 'This is a test message from Azure via Microsoft Graph API'
$mailMessage = 'This is a test message from Azure via Microsoft Graph API'

$uri = "https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token"
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $client_id
    client_secret = $AppSecret
    }
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token

$params = @{
  "URI"         = "https://graph.microsoft.com/v1.0/users/$fromAddress/sendMail"
  "Headers"     = @{
    "Authorization" = ("Bearer {0}" -F $token)
  }
  "Method"      = "POST"
  "ContentType" = 'application/json'
  "Body" = (@{
    "message" = @{
      "subject" = $mailSubject
      "body"    = @{
        "contentType" = 'Text'
        "content"     = $mailMessage
      }
      "toRecipients" = @(
        @{
          "emailAddress" = @{
            "address" = $toAddress
          }
        }
      )
    }
  }) | ConvertTo-JSON -Depth 10
}

Invoke-RestMethod @params -Verbose
