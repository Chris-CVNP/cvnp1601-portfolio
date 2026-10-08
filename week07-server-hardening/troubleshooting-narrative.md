What went wrong or could have gone wrong

After reloading the sshd daemon for Task 2, i attempted to confirm a new login and was given Permission denied publickey. Initially, this seemed to suggest that the reload process had locked me out of my own server. I ran the exact same command once again, but still got the same result.

What evidence i checked first

Firstly, i looked at the prompt that was visible when entering the command, and saw that it contained the hostname of the vm, 1601. As such, it appeared that the SSH command had actually been executed from within the vm itself; the vm was attempting to connect to itself. Secondly, i viewed the output of sshd -T, and confirmed that pubkeyauthentication yes and passwordauthentication no.

What i tried

I did not close my original session. I did not make any modifications to the server. From my local desktop, the machine holding the key pair, i launched another PowerShell window and attempted to execute the SSH command from that point.

What fixed it

Executing the test from the proper client resolved the problem. Due to the fact that the public key associated with the vm was not included in authorized_keys, any login attempts from the vm to itself would have resulted in being rejected. There was nothing wrong with either the server or the key.

How i verified the result

The connection from my desktop successfully presented me with the Ubuntu banner without a password prompt, and correctly showed my desktop ip address under the Last login entry. In addition, my initial session remained intact throughout the duration of this process and therefore access to the server was never lost.

Security impact

The denial of login demonstrated that the hardening had functioned as desired. The server presented publickey as the sole possible method of logging in; additionally, the server rejected a key that had not been authorized. If this had truly represented an actual lockout of the server, the only means of regaining access to the server would have been via the Proxmox console; therefore, i maintained a live session on the server and verified a second login before closing it.
