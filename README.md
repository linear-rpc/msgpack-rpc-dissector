# MessagePack-RPC Dissector

Wireshark dissector for MessagePack-RPC.

## Install

  1. Update submodules.

    If you use '--recursive' option in 'git clone', skip this step.

    Call below commands.

    $ git submodule update --init --recursive

  2. Select port (default port is 9003, 37800 for example).

    If you want to change port, open msgpack_rpc.lua and modify line 6.

  3. Copy deps/lua-MessagePack/src/MessagePack.lua to Lua library directory.

    Lua library directory is like below (if not exist, please mkdir):

    * Windows
      C:\Programs Files\Wireshark\lua\
    * Unix
      /usr/local/share/lua/${WIRESHARK_LUA_VERSION}/

    You can confirm ${WIRESHARK_LUA_VERSION} from wireshark version dialog('About Wireshark').
    See wireshark_version.jpg. If this image, ${WIRESHARK_LUA_VERSION} is '5.2'.

    If your wireshark supports Lua 5.3, then use deps/lua-MessagePack/src5.3/MessagePack.lua, not deps/lua-MessagePack/src/MessagePack.lua.

  4. Copy msgpack_rpc.lua to Wireshark plugin directory

    Wireshark plugin directory is like below (if not exist, please mkdir):

    * Windows
      C:\Users\${USERNAME}\AppData\Roaming\Wireshark\plugins\
    * Unix
      ${HOME}/.wireshark/plugins

## Limitation

 A map whose type of key is number is shown as array value (key is disapperred).
 This is because Lua regards array and map as the same table container.
 So msgpack_rpc.lua shows it as array in which type of key is number,
 and shows it as map in which type of key is not number.

## Troubleshooting

### Cannot use this plugin in Ubuntu.

  If you run wireshark in root, this plugin cannot be used.
  Please run wireshark in common user, you can run wireshark in common user like below:

  $ sudo setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap

### Cannot use this plugin in CentOS.

  Wireshark installed from yum package does not support Lua.
  So, please uninstall the package and build wireshark from source code.

  If you installed, copy directory of MessagePack.lua might be changed /usr/local/share/lua/${WIRESHARK_LUA_VERSION}/ to /usr/share/lua/${WIRESHARK_LUA_VERSION}.

### Displays truncated text in protocol tree.

  Wireshark truncates text when it is too long.
  If you get whole text, right click on it, then choose Copy > Value.
  You can paste it in a text editor.

## Others

### MessagePack-RPC over WebSocket

  Experimental support for websocket becomes available if you replace msgpack_rpc.lua to msgpack_rpc_over_ws.lua.
  It cannot be supported msgpack_rpc.lua and msgpack_rpc_over_ws.lua load simultaneously.

### Display filter

  You can use display filter named "msgpack-rpc"

    * msgpack-rpc  # display MessagePack-RPC message only
    * msgpack-rpc.type == 0  # display Request message only
    * msgpack-rpc.msgid == 1  # display msgid = 1
    * msgpack-rpc.method == "echo"  # display method name is echo

## License

  The MIT License (MIT)  
  See LICENSE for details.  

  And see some submodule LICENSEs(exist at deps dir).
