az login
az account set --subscription <SUBSCRIPTION-NAME>

ngrok http 7071
Start-Sleep -Seconds 4

$tunnels = (curl http://localhost:4040/api/tunnels | ConvertFrom-Json).tunnels

$ngrokUrl = $tunnels[0].public_url
if (!$ngrokUrl.Contains("https")) {
  $ngrokUrl = $ngrokUrl -replace "http", "https"
}

Write-Host ""
Write-Host "Using ngrok url: $ngrokUrl"
Write-Host ""

$subscriptions = (Get-Content -Path "parameters.json" | ConvertFrom-Json).parameters.subscriptions.value
$eventGridTopicResourceId = "<TOPIC-RESOURCE-ID>"

foreach ($subscription in $subscriptions) {
  $subscriptionName = $subscription.name
  $functionName = $subscription.functionName

  az eventgrid event-subscription <create/update> `
    --name "LOCALHOST-$subscriptionName" `
    --source-resource-id $eventGridTopicResourceId `
    --delivery-identity-endpoint-type webhook `
    --endpoint "$ngrokUrl/runtime/webhooks/eventgrid?functionName=$functionName" `
    --included-event-types $subscription.eventTypes
}
