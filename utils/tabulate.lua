-- tabulate.lua
-- Formats input data with HTML table elements

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local html_format = function(str, element, class)
    str = str or ""
    element = element or "td"
    local open = class == nil and "<"..element..">" or "<"..element.." class=\""..class.."\">"
    local close = "</"..element..">"
    return open..str..close
end

local _M = function(table_data) -- table to HTML
    local table_string
    local classes = {}

    -- table HTML class?
    if table_data.class then
        table_string = "<table class=\""..table_data.class.."\">\n"
    else
        table_string = "<table>\n"
    end

    -- format th row
    if #table_data.headers > 0 then
        local header_row = "<tr>"
        for _, header in pairs(table_data.headers) do
            table.insert(classes, header[1]) -- populate classes data
            local th = html_format(header[2], "th", header[1])
            header_row = header_row..th
        end
        header_row = header_row.."</tr>\n"
        table_string = table_string..header_row
    end

    -- rows with td
    if #table_data.rows > 0 then
        for _, row in pairs(table_data.rows) do
            local row_html = "<tr>"
            for i, data in pairs(row) do
                local class = classes[i]
                local td = html_format(data, "td", class)
                row_html = row_html..td
            end
            local row_html = row_html.."</tr>\n"
            table_string = table_string..row_html
        end
    end

    table_string = table_string.."</table>\n"

    return table_string
end

return _M
