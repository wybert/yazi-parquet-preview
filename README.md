# Yazi Parquet Preview Plugin

A Yazi plugin for previewing Parquet files using DuckDB as the backend engine.

## Features

- 📊 **Metadata Display**: Shows row count, column count, and data types
- 🔍 **Data Preview**: Displays first 20 rows with pagination support
- ⚡ **Fast Performance**: Uses DuckDB for efficient Parquet processing
- 🧭 **Navigation**: Arrow key support for scrolling through data pages
- 🔧 **Debug Support**: Comprehensive logging for troubleshooting

## Requirements

- [Yazi](https://github.com/sxyazi/yazi) file manager
- [DuckDB](https://duckdb.org/) CLI tool

## Installation

### Via Yazi Package Manager

```bash
ya pack -i wybert/yazi-parquet-preview
```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/wybert/yazi-parquet-preview.git
```

2. Copy to your Yazi plugins directory:
```bash
cp -r yazi-parquet-preview ~/.config/yazi/plugins/parquet.yazi
```

## Usage

Once installed, the plugin will automatically handle `.parquet` files when you navigate to them in Yazi.

### Navigation

- **← →**: Navigate between pages (20 rows per page)
- **↑ ↓**: Scroll within the current view

### Testing

You can test the plugin with the included sample data:

```bash
YAZI_LOG=debug timeout 5s yazi "test_data/sample.parquet" 2>/dev/null || echo "Test completed"
```

Check the logs for debugging information:
```bash
tail -f ~/.local/state/yazi/yazi.log
```

## Preview Display

The plugin shows:
- File path and basic statistics (rows, columns, current page)
- Column information with names and data types
- First 20 rows of data with pagination
- Navigation instructions

## Configuration

The plugin includes the following configurable options in `init.lua`:
- `ROWS_PER_PAGE`: Number of rows to display per page (default: 20)
- `MAX_COLUMN_WIDTH`: Maximum width for column display (default: 50)

## Development

To contribute to this plugin:

1. Fork the repository
2. Make your changes
3. Test with various Parquet files
4. Submit a pull request

### Creating Test Data

The repository includes a sample Parquet file. You can create additional test data using DuckDB:

```sql
CREATE TABLE test_data AS SELECT 
    i as id,
    'name_' || i as name,
    random() * 100 as score,
    CASE WHEN i % 3 = 0 THEN 'A' WHEN i % 3 = 1 THEN 'B' ELSE 'C' END as category,
    current_date + (i * interval '1 day') as date,
    random() > 0.5 as active
FROM range(1, 101) t(i);

COPY test_data TO 'test_data/sample.parquet' (FORMAT PARQUET);
```

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.