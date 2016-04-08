# MessagePack-RPC Dissector

Wireshark dissector for MessagePack-RPC over TCP / WebSocket.

## Install

1. Update submodules.

  If you use '--recursive' option in 'git clone', skip this step.

  Call below commands:

        $ git submodule update --init --recursive

2. Copy `deps/lua-MessagePack/src/MessagePack.lua` to Lua library directory.

  Lua library directory is like below (if not exist, please mkdir):

  * Windows
    * `C:\Programs Files\Wireshark\lua`
  * Unix
    * `/usr/local/share/lua/${WIRESHARK\_LUA\_VERSION}`

  You can confirm lua version from wireshark version dialog('About Wireshark').  
  See wireshark\_version.jpg. If this image, `${WIRESHARK_LUA_VERSION}` is '5.2'.

3. Copy `msgpack_rpc.lua` to Wireshark plugin directory

  Wireshark plugin directory is like below (if not exist, please mkdir):

  * Windows
    * `C:\Users\${USERNAME}\AppData\Roaming\Wireshark\plugins`
  * Unix
    * `${HOME}/.wireshark/plugins`

## Limitation

A map whose type of key is number is shown as array value (key is disapperred).  
This is because Lua regards array and map as the same table container.

So `msgpack_rpc.lua` shows it as array in which type of key is number, and shows it as map in which type of key is not number.

## Troubleshooting

### Cannot use this plugin in Ubuntu.

If you run wireshark as root, this plugin cannot be used.  
Please run wireshark as common user after setting like below:

    $ sudo setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap

### Cannot use this plugin in CentOS.

Wireshark installed from yum package does not support Lua.  
So, please uninstall the package and build wireshark from source code.

If you installed, copy directory of `MessagePack.lua` might be changed `/usr/local/share/lua/${WIRESHARK_LUA_VERSION}` to `/usr/share/lua/${WIRESHARK_LUA_VERSION}`.

### Displays truncated text in protocol tree.

Wireshark truncates text when it is too long.  
If you want to get whole text, right click on it, then `Copy > Value`.  
You can paste it in a text editor.

## Others

### Supported versions

| Wireshark version | Support                           |
|:-----------------:|:---------------------------------:|
| 2.0               | TCP / WebSocket                   |
| 1.12              | TCP                               |
| 1.10              | TCP (with msgpack\_rpc\_1\_x.lua) |

WebSocket is supported with only Wireshark 2.0 or later.  
And if you want to use Wireshark 1.10, try to use `msgpack_rpc_1_x.lua`.

### Port setting

This plugin is enabled to select port numbers by `Preferences > Protocols > MSGPACK-RPC`.

### Display filter

This plugin registers display filter named 'msgpack-rpc'.

| Display filter sample        | Description                          |
|:-----------------------------|:-------------------------------------|
| msgpack-rpc                  | display MessagePack-RPC message only |
| msgpack-rpc.type == 0        | display Request message only         |
| msgpack-rpc.msgid == 1       | display msgid = 1                    |
| msgpack-rpc.method == "echo" | display method name is echo          |

## License

The MIT License (MIT)

For details, see LICENSE and some submodule LICENSEs(exist at deps dir).
