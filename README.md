# Overview

nz_util.sh is a shell script providing a collection of functions for common database operations on Netezza Performance Server (NPS). These utility functions facilitate tasks such as statistics gathering, table truncation, data loading from various file formats, command execution, CSV file writing, and more.

## Functions

- GatherStats: Gathers statistics for a specified table in a Netezza database.
- TruncateTable: Truncates a specified table in a Netezza database.
- LoadFromFixedFile: Loads data from a fixed-length file into a Netezza table.
- LoadFromDelimited: Loads data from a delimited file into a Netezza table.
- LoadFromSQL: Loads data into a Netezza table using an SQL insert script.
- ExecuteCommand: Executes a given command in a Netezza database.
- WriteCSV: Writes query results to a CSV file.
- GroomTable: Executes the GROOM TABLE command for a specified table.
- CreateLoadTable: Creates a table in Netezza for loading data.
- CreateLoadTableDelimited: Creates a delimited table in Netezza for loading data.
- TouchNZTable: Checks if a specified table exists in a database.
- NzEzLoader: A comprehensive function that automates the process of loading data into a Netezza table.

## Usage

To use these functions in your shell scripts, source nz_util.sh as follows:

```bash

source /path/to/nz_util.sh

GatherStats "my_table" "my_database"

TruncateTable "my_table" "my_database"

```

## Requirements

A Netezza Performance Server environment.
Appropriate permissions to execute database operations.

## Author

Tom McGeehan
