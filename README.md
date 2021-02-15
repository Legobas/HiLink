# HiLink
Huawei HiLink 4G USB Modem Client

This Windows Commandline utility can be used to manage the Huawei 4G Modem.
It is meant to run in a command window (cmd.exe).

Tested with the E3372h-153 USB 4G Modem

## General information commands
Run the utility in a command window without any parameters to see the help:

    HiLink x64 1.0.0                                                                                                    
    Usage:                                                                                                              
    command (without other parameters)                                                                                  
    -c command (-c info)                                                                                                
       commands: info, status, net, sms, smscount, smslist, stats, monthstats, resetstats, reboot, con, hack, emptyinbox
    -h host, IP Address (default 192.168.8.1)                                                                           
    -d debuglevel (none=1, 0-2)                                                                                         
    -a api path (-a api/**/**)                                                                                          
    -x request XML (-x "<request>***</request>")                                                                        
                                                                                                                        
    Examples:                                                                                                           
    HiLink info                                                                                                         
    HiLink -c info                                                                                                      
    HiLink -d -c status                                                                                                 
    HiLink -d 2 -a api/device/information                                                                               
    HiLink -a api/monitoring/clear-traffic -x "<request><ClearTraffic>1</ClearTraffic></request>"                       

## Reboot
Use this command to reboot the device: `HiLink.exe reboot`.

## Empty the SMS Inbox
This command will remove all the SMS messages from the SMS Inbox: `HiLink.exe emptyinbox`.

## Auto Disconnect Interval Hack

The Huawei E3372 disconnects frequently from the LTE network. This is caused by the Auto Disconnect Interval, which has a maximum 120 minutes. This little hack sets the Interval to 24 hours, for the explanation see: 
[hacking-huawei-e3372-hilink](https://blog.idorobots.org/entries/hacking-huawei-e3372-hilink..html).

## Acknowledgements

* Thanks to [Kajetan Rzepecki 'Idorobots'](https://github.com/Idorobots) for research and the reconnect hack
* Thanks to [AutoIt](https://www.autoitscript.com)
* Thanks to Logan Hampton and Damien Smith for the [Visual Studio Code AutoIt Extension](https://github.com/loganch/AutoIt-VSCode)
