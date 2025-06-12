local M = {}

function M:peek(job)
    local file = job.file
    local file_path = tostring(file.url)
    
    ya.dbg("DEBUG: Plugin called for file: " .. file_path)
    
    -- Check if it's a parquet file
    if not file_path:match("%.parquet$") then
        ya.dbg("DEBUG: Not a parquet file")
        return
    end
    
    ya.dbg("DEBUG: Processing parquet file")
    
    -- Try to get actual data from DuckDB
    local success, result = pcall(function()
        -- Get row count
        local count_cmd = Command("duckdb"):arg({"-cmd", 
            "SELECT COUNT(*) as row_count FROM read_parquet('" .. file_path .. "')"})
            :stdout(Command.PIPED):stderr(Command.PIPED)
        
        local count_output = count_cmd:output()
        if not count_output or not count_output.status.success then
            return "Error getting row count"
        end
        
        local row_count = count_output.stdout:match("(%d+)") or "unknown"
        
        -- Get column info
        local describe_cmd = Command("duckdb"):arg({"-cmd", 
            "DESCRIBE SELECT * FROM read_parquet('" .. file_path .. "')"})
            :stdout(Command.PIPED):stderr(Command.PIPED)
        
        local describe_output = describe_cmd:output()
        local column_info = ""
        if describe_output and describe_output.status.success then
            column_info = describe_output.stdout:sub(1, 500) -- Limit length
        end
        
        -- Get sample data
        local sample_cmd = Command("duckdb"):arg({"-cmd", 
            "SELECT * FROM read_parquet('" .. file_path .. "') LIMIT 10"})
            :stdout(Command.PIPED):stderr(Command.PIPED)
        
        local sample_output = sample_cmd:output()
        local sample_data = ""
        if sample_output and sample_output.status.success then
            sample_data = sample_output.stdout:sub(1, 1000) -- Limit length
        end
        
        return {
            row_count = row_count,
            column_info = column_info,
            sample_data = sample_data
        }
    end)
    
    if not success then
        ya.dbg("DEBUG: Error occurred: " .. tostring(result))
        ya.preview_widget(job, {
            ui.Text("Parquet File"):fg("cyan"):bold(),
            ui.Text("File: " .. file_path):fg("gray"),
            ui.Text(""),
            ui.Text("Error reading file: " .. tostring(result)):fg("red")
        })
        return
    end
    
    -- Create display
    local lines = {}
    table.insert(lines, ui.Text("🗂️  Parquet File Preview"):fg("cyan"):bold())
    table.insert(lines, ui.Text("📁 " .. file_path):fg("blue"))
    table.insert(lines, ui.Text(""))
    
    if type(result) == "table" then
        table.insert(lines, ui.Text("📊 Rows: " .. result.row_count):fg("yellow"))
        table.insert(lines, ui.Text(""))
        
        if result.column_info and result.column_info ~= "" then
            table.insert(lines, ui.Text("📋 Column Information:"):fg("green"))
            -- Split into lines and add first few
            local col_lines = {}
            for line in result.column_info:gmatch("[^\r\n]+") do
                table.insert(col_lines, line)
                if #col_lines >= 5 then break end
            end
            for _, line in ipairs(col_lines) do
                table.insert(lines, ui.Text(line):fg("white"))
            end
            table.insert(lines, ui.Text(""))
        end
        
        if result.sample_data and result.sample_data ~= "" then
            table.insert(lines, ui.Text("🔍 Sample Data:"):fg("green"))
            -- Split into lines and add first few
            local data_lines = {}
            for line in result.sample_data:gmatch("[^\r\n]+") do
                table.insert(data_lines, line)
                if #data_lines >= 8 then break end
            end
            for _, line in ipairs(data_lines) do
                if #line > 80 then
                    line = line:sub(1, 80) .. "..."
                end
                table.insert(lines, ui.Text(line):fg("white"))
            end
        end
    else
        table.insert(lines, ui.Text("⚠️  " .. tostring(result)):fg("yellow"))
    end
    
    ya.dbg("DEBUG: Displaying " .. #lines .. " widgets")
    ya.preview_widget(job, lines)
end

return M