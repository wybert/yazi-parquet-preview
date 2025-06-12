# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Yazi plugin for previewing Parquet files using DuckDB as the backend. The plugin allows users to preview Parquet data directly in the Yazi file manager with pagination support and detailed metadata display.

## Development Commands

### Testing the Plugin
```bash
# Test the plugin with debug logging
YAZI_LOG=debug timeout 5s yazi "/Users/kang/Downloads/Demand Data.parquet" 2>/dev/null || echo "Test completed"

# View debug logs
tail -f /Users/kang/.local/state/yazi/yazi.log
```

### Plugin Installation
```bash
# Install plugin via Yazi package manager
ya pack -i wybert/yazi-parquet-preview

# Install locally during development
ya pack -i .
```

### Repository Management
```bash
# Create and manage GitHub repository
gh repo create wybert/yazi-parquet-preview --public
```

## Plugin Architecture

### Core Components
- **init.lua**: Main plugin entry point that handles Parquet file preview
- **DuckDB Integration**: Uses DuckDB CLI/library for efficient Parquet processing
- **Preview Display**: Shows file metadata (rows, columns, data types) and paginated data view
- **Navigation**: Arrow key support for scrolling through data pages

### Key Features
- Display row/column count and data types
- Show first 20 rows with pagination support
- Efficient handling of large Parquet files via DuckDB
- Debug logging for troubleshooting

### File Structure
```
├── init.lua           # Main plugin file
├── README.md          # Plugin documentation
└── test_data/         # Simple test datasets
```

## Development Guidelines

### Plugin Development
- Follow Yazi plugin conventions: https://yazi-rs.github.io/docs/plugins/overview
- Reference existing plugins like pdf.lua: https://github.com/sxyazi/yazi/blob/shipped/yazi-plugin/preset/plugins/pdf.lua
- Keep implementation minimal and fast
- Use DuckDB functions directly when possible

### Testing Strategy
- Create simple test Parquet files for development
- Test with various file sizes and schemas
- Verify navigation and pagination functionality
- Monitor performance with large files

### Debug Information
- Add comprehensive logging to track plugin execution
- Log DuckDB query results and errors
- Include timing information for performance analysis
- Use YAZI_LOG=debug for detailed debugging

## External Resources

- Yazi Plugin Documentation: https://yazi-rs.github.io/docs/plugins/overview
- Yazi Package Manager: https://yazi-rs.github.io/docs/cli/#pm
- Example Plugin Reference: https://github.com/sxyazi/yazi/blob/shipped/yazi-plugin/preset/plugins/pdf.lua