# HiLink
Huawei HiLink 4G Modem Client

This Windows Commandline utility can be used to manage the Huawei 4G Modem, offering extended functionality.
It is meant to run in a command window (cmd.exe).

Tested with the E3372h-153 USB 4G Modem

## Empty the SMS Inbox
This command will remove all the SMS messages from the SMS Inbox: `HiLink.exe emptyinbox`.

## Reconnect Hack

The Huawei E3372 disconnects frequently from the LTE network. This is caused by the Auto Disconnect Interval, which has a maximum 120 minutes. This little hack sets the Interval to 24 hours, for the explanation see: 
[hacking-huawei-e3372-hilink](https://blog.idorobots.org/entries/hacking-huawei-e3372-hilink..html).

## Acknowledgements

* Thanks to [Kajetan Rzepecki 'Idorobots'](https://github.com/Idorobots) for research and the reconnect hack
* Thanks to [AutoIt](https://www.autoitscript.com)
* Thanks to Logan Hampton and Damien Smith for the [Visual Studio Code AutoIt Extension](https://github.com/loganch/AutoIt-VSCode)
