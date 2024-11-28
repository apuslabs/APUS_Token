local Utils = {}

function Utils.getLatestMessage(limit)
    limit = limit or 1
    if limit == 1 then
        return ao.outbox.Messages[#ao.outbox.Messages]
    else
        local messages = {}
        for i = #ao.outbox.Messages, #ao.outbox.Messages - limit + 1, -1 do
            table.insert(messages, ao.outbox.Messages[i])
        end
        return messages
    end
end

function Utils.getValueFromTags(table, name)
    for _, v in ipairs(table) do
        if v.name == name then
            return v.value
        end
    end
    return nil
end

return Utils