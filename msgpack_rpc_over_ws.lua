--
-- The MIT License (MIT)
-- Copyright 2015 Sony Corporation
--

do
    local PORTS = {9003, 37800} -- if you want to change port, modify this variable.

    msgpack_rpc_proto = Proto("msgpack-rpc", "MessagePack-RPC")
    local f = msgpack_rpc_proto.fields
    f.type_field = ProtoField.uint8("msgpack-rpc.type", "Type")
    f.msgid_field = ProtoField.uint32("msgpack-rpc.msgid", "Msgid")
    f.method_field = ProtoField.string("msgpack-rpc.method", "Method")
    f.params_field = ProtoField.string("msgpack-rpc.params", "Params")
    f.error_field = ProtoField.string("msgpack-rpc.error", "Error")
    f.result_field = ProtoField.string("msgpack-rpc.result", "Result")
    
    local mp = require "MessagePack"

    function table_print(tt)
        local len = 0
        local is_array = true
        for key, value in pairs(tt) do
            if "number" ~= type(key) then
                is_array = false
            end
            len = len + 1
        end
    
        local sb = {}
        if is_array then
            table.insert(sb, "[")
        else
            table.insert(sb, "{")
        end
        local i = 1
        for key, value in pairs(tt) do
            if is_array then
                table.insert(sb, stringify(value))
            else
                table.insert(sb, stringify(key) .. ": " .. stringify(value))
            end
            if i < len then
                table.insert(sb, ", ")
            end
            i = i + 1
        end
        if is_array then
            table.insert(sb, "]")
        else
            table.insert(sb, "}")
        end
        return table.concat(sb)
    end
    
    function stringify(obj)
        if "nil" == type(obj) then
            return tostring(nil)
        elseif "table" == type(obj) then
            return table_print(obj)
        elseif "string" == type(obj) then
            return "\'" .. obj .. "\'"
        else
            return tostring(obj)
        end
    end

    function is_array(ar)
        local is_array = true
        if "table" == type(ar) then
            for key, value in pairs(ar) do
                if "number" ~= type(key) then
                    is_array = false
                end
            end
        else
            is_array = false
        end
        return is_array
    end

    function is_number(num)
        if "number" == type(num) then
            return true
        end
        return false
    end

    function is_string(str)
        if "string" == type(str) then
            return true
        end
        return false
    end

    function contains(port)
        for i, p in ipairs(PORTS) do
            if p == port then
                return true
            end
        end
        return false
    end
 
    local str
    local substr

    local tcp_srcport_field = Field.new("tcp.srcport")
    local tcp_dstport_field = Field.new("tcp.dstport")

    local ws_mask_field = Field.new("websocket.mask")
    local ws_payload_binary_field = Field.new("websocket.payload.binary")
    local ws_payload_binary_unmask_field = Field.new("websocket.payload.binary_unmask")
    
    function msgpack_rpc_proto.dissector(tvb, pinfo, tree)
        local proto_name = "MessagePack-RPC over WebSocket"

        local tcp_srcport = tcp_srcport_field()
        local tcp_dstport = tcp_dstport_field()
        if not tcp_srcport or not tcp_dstport then
            -- not exist
            return
        end
        if not contains(tcp_srcport.value) and not contains(tcp_dstport.value) then
            -- not specified port
            return
        end

        local ws_mask = ws_mask_field()
        if not ws_mask then
            -- not websocket
            return
        end

        local b
        if ws_mask.value then
            local ws_payload_binary_unmask = ws_payload_binary_unmask_field()
            if not ws_payload_binary_unmask then
                -- not exist
                return
            end
            b = ws_payload_binary_unmask.range:bytes()
        else
            local ws_payload_binary = ws_payload_binary_field()
            if not ws_payload_binary then
                -- not exist
                return
            end
            b = ws_payload_binary.range:bytes()
        end

        str = ""
        for i = 0, b:len() - 1 do
            str = str .. string.char(b:get_index(i))
        end

        substr = str:sub(1, 1)
        if substr ~= string.char(0x94) and substr ~= string.char(0x93) then
            return
        end

        local flag, ret = pcall(mp.unpack, str)
        if not flag then
            if ret:find("missing bytes$") then
                pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
                return
            else
                error(ret)
            end
        end

        substr = str:sub(2, str:len())

        local n = 1
        local pair = {}
        for csr, val in mp.unpacker(substr) do
            pair[n] = {csr, val}
            n = n + 1
        end

        local subtree = tree:add(msgpack_rpc_proto, tvb(), "MessagePack-RPC Protocol")
        -- type
        if pair[1][2] == 0 then            -- request
            subtree:add(f.type_field, tvb(pair[1][1], pair[2][1] - pair[1][1]), pair[1][2]):append_text(" (Request)")
            -- msgid
            if not is_number(pair[2][2]) then
                return
            end
            subtree:add(f.msgid_field, tvb(pair[2][1], pair[3][1] - pair[2][1]), pair[2][2])
            -- method
            if not is_string(pair[3][2]) then
                return
            end
            subtree:add(f.method_field, tvb(pair[3][1], pair[4][1] - pair[3][1]), pair[3][2], "Method: " .. stringify(pair[3][2]))
            -- params
            if not is_array(pair[4][2]) then
                proto_name = proto_name .. " (dirty)"
            end
            subtree:add(f.params_field, tvb(pair[4][1], tvb:len() - pair[4][1]), stringify(pair[4][2]))
        elseif pair[1][2] == 1 then    -- response
            subtree:add(f.type_field, tvb(pair[1][1], pair[2][1] - pair[1][1]), pair[1][2]):append_text(" (Response)")
            -- msgid
            if not is_number(pair[2][2]) then
                return
            end
            subtree:add(f.msgid_field, tvb(pair[2][1], pair[3][1] - pair[2][1]), pair[2][2])
            -- error
            subtree:add(f.error_field, tvb(pair[3][1], pair[4][1] - pair[3][1]), stringify(pair[3][2]))
            -- result
            subtree:add(f.result_field, tvb(pair[4][1], tvb:len() - pair[4][1]), stringify(pair[4][2]))
        elseif pair[1][2] == 2 then    -- notify
            subtree:add(f.type_field, tvb(pair[1][1], pair[2][1] - pair[1][1]), pair[1][2]):append_text(" (Notify)")
            -- method
            if not is_string(pair[2][2]) then
                return
            end
            subtree:add(f.method_field, tvb(pair[2][1], pair[3][1] - pair[2][1]), pair[2][2], "Method: " .. stringify(pair[2][2]))
            -- params
            if not is_array(pair[3][2]) then
                proto_name = proto_name .. " (dirty)"
            end
            subtree:add(f.params_field, tvb(pair[3][1], tvb:len() - pair[3][1]), stringify(pair[3][2]))
        else
            return
        end
        pinfo.cols.protocol = proto_name
    end
    
    register_postdissector(msgpack_rpc_proto)
end
