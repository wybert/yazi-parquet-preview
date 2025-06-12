local M = {}

-- Plugin configuration
local ROWS_PER_PAGE = 20
local MAX_COLUMN_WIDTH = 50

-- State management
local current_page = 1
local total_rows = 0
local total_columns = 0
local column_info = {}
local cached_data = {}

-- Helper function to execute DuckDB command
local function exec_duckdb(sql, file_path)
	ya.dbg("Executing DuckDB SQL: " .. sql)
	ya.dbg("File path: " .. file_path)
	
	local cmd = string.format('duckdb -c "%s" "%s"', sql, file_path)
	local output, err = Command(cmd):output()
	
	if not output then
		ya.err("DuckDB command failed: " .. (err or "unknown error"))
		return nil
	end
	
	if output.status.success then
		ya.dbg("DuckDB output: " .. output.stdout)
		return output.stdout
	else
		ya.err("DuckDB execution failed: " .. output.stderr)
		return nil
	end
end

-- Get metadata about the Parquet file
local function get_metadata(file_path)
	ya.dbg("Getting metadata for: " .. file_path)
	
	-- Get row count
	local count_sql = "SELECT COUNT(*) FROM read_parquet('" .. file_path .. "')"
	local count_result = exec_duckdb(count_sql, "")
	if count_result then
		total_rows = tonumber(count_result:match("%d+")) or 0
		ya.dbg("Total rows: " .. total_rows)
	end
	
	-- Get column information
	local describe_sql = "DESCRIBE SELECT * FROM read_parquet('" .. file_path .. "')"
	local describe_result = exec_duckdb(describe_sql, "")
	if describe_result then
		column_info = {}
		total_columns = 0
		for line in describe_result:gmatch("[^\r\n]+") do
			if not line:match("column_name") then -- Skip header
				local col_name, col_type = line:match("([^|]+)|([^|]+)")
				if col_name and col_type then
					col_name = col_name:gsub("%s+", "")
					col_type = col_type:gsub("%s+", "")
					table.insert(column_info, {name = col_name, type = col_type})
					total_columns = total_columns + 1
				end
			end
		end
		ya.dbg("Total columns: " .. total_columns)
	end
end

-- Get data for a specific page
local function get_page_data(file_path, page)
	ya.dbg("Getting page data for page: " .. page)
	
	local offset = (page - 1) * ROWS_PER_PAGE
	local limit_sql = string.format(
		"SELECT * FROM read_parquet('%s') LIMIT %d OFFSET %d",
		file_path, ROWS_PER_PAGE, offset
	)
	
	local result = exec_duckdb(limit_sql, "")
	if result then
		local lines = {}
		for line in result:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
		cached_data[page] = lines
		return lines
	end
	
	return {}
end

-- Format data for display
local function format_display(file_path)
	ya.dbg("Formatting display for file: " .. file_path)
	
	local lines = {}
	
	-- Header with file info
	table.insert(lines, "Parquet File: " .. file_path)
	table.insert(lines, string.format("Rows: %d | Columns: %d | Page: %d/%d", 
		total_rows, total_columns, current_page, math.max(1, math.ceil(total_rows / ROWS_PER_PAGE))))
	table.insert(lines, "")
	
	-- Column headers
	if #column_info > 0 then
		table.insert(lines, "Column Information:")
		for i, col in ipairs(column_info) do
			table.insert(lines, string.format("  %d. %s (%s)", i, col.name, col.type))
		end
		table.insert(lines, "")
	end
	
	-- Data preview
	table.insert(lines, "Data Preview:")
	local page_data = cached_data[current_page] or get_page_data(file_path, current_page)
	
	if #page_data > 0 then
		for _, row in ipairs(page_data) do
			-- Truncate long rows
			if #row > 200 then
				row = row:sub(1, 200) .. "..."
			end
			table.insert(lines, row)
		end
	else
		table.insert(lines, "No data available")
	end
	
	-- Navigation hint
	table.insert(lines, "")
	table.insert(lines, "Navigation: ← → for pages, ↑ ↓ for rows")
	
	return table.concat(lines, "\n")
end

-- Main preview function
function M.peek(job)
	ya.dbg("peek() called for: " .. tostring(job.file.url))
	
	local file_path = tostring(job.file.url)
	
	-- Check if file exists and is a parquet file
	if not file_path:match("%.parquet$") then
		ya.err("Not a parquet file: " .. file_path)
		return 1
	end
	
	-- Initialize if needed
	if total_rows == 0 then
		get_metadata(file_path)
	end
	
	-- Format and display
	local content = format_display(file_path)
	ya.preview_widgets(job, {
		ui.Paragraph(job.area, {
			ui.Line(content)
		})
	})
	
	return 0
end

-- Navigation function
function M.seek(job)
	ya.dbg("seek() called with units: " .. tostring(job.units))
	
	local file_path = tostring(job.file.url)
	local max_pages = math.max(1, math.ceil(total_rows / ROWS_PER_PAGE))
	
	-- Update current page
	current_page = current_page + job.units
	if current_page < 1 then
		current_page = 1
	elseif current_page > max_pages then
		current_page = max_pages
	end
	
	ya.dbg("Navigated to page: " .. current_page)
	
	-- Clear cache for new page if needed
	if not cached_data[current_page] then
		get_page_data(file_path, current_page)
	end
	
	-- Refresh preview
	M.peek(job)
	
	return 0
end

-- Preload function
function M.preload(job)
	ya.dbg("preload() called for: " .. tostring(job.file.url))
	
	local file_path = tostring(job.file.url)
	
	-- Reset state for new file
	current_page = 1
	total_rows = 0
	total_columns = 0
	column_info = {}
	cached_data = {}
	
	-- Load metadata
	get_metadata(file_path)
	
	-- Preload first page
	get_page_data(file_path, 1)
	
	return 0
end

return M