Prerequisites
Before running the code, ensure that you have the following:

PostgreSQL installed (version 9.5 or higher recommended)
PostGIS extension installed and enabled in your PostgreSQL database
Access to the got and atlas schemas containing the necessary tables:
got schema tables:
houses
characters
character_books
books
atlas schema tables:
kingdoms
locations
Proper permissions to create functions, views, and insert data into the greyjoy schema (replace greyjoy with your schema name if different)
Setup Instructions
1. Install PostgreSQL
Download and install PostgreSQL from the official website: PostgreSQL Downloads
Ensure that the installed version is compatible with your operating system.
2. Install and Enable PostGIS Extension
PostGIS adds spatial capabilities to PostgreSQL and is required for spatial functions used in the code.

Install PostGIS:

On Linux (Ubuntu/Debian):
bash
Copy code
sudo apt-get update
sudo apt-get install postgis postgresql-14-postgis-3
On macOS Using Homebrew:
bash
Copy code
brew update
brew install postgis
On Windows:
Use the Stack Builder that comes with PostgreSQL to install PostGIS.
Enable PostGIS in Your Database:

Connect to your PostgreSQL database using a superuser account and run:

sql
Copy code
CREATE EXTENSION IF NOT EXISTS postgis;
3. Create and Populate the got and atlas Schemas
Create Schemas:

sql
Copy code
CREATE SCHEMA IF NOT EXISTS got;
CREATE SCHEMA IF NOT EXISTS atlas;
Import Data:

Load the data into the respective tables in the got and atlas schemas.
Ensure that the tables (houses, characters, character_books, books, kingdoms, locations) are populated with the correct data.
4. Create the greyjoy Schema
Replace greyjoy with your team name or preferred schema name if different.

sql
Copy code
CREATE SCHEMA IF NOT EXISTS greyjoy;
5. Set Search Path (Optional)
To simplify queries, set the search path:

sql
Copy code
SET search_path TO greyjoy, got, atlas, public;
Running the Code
Open Your SQL Client:

Use your preferred SQL client (e.g., psql, PgAdmin, DBeaver) to connect to your PostgreSQL database.

Execute the Code Sections in Order:

Run each section of the code provided in the SQL script, ensuring that you execute them in the order they appear.

Note: Some sections depend on the results of previous sections.
Check for Errors:

After executing each section, check for any error messages and resolve them before proceeding to the next section.

Verify the Results:

For SELECT queries, observe the output to ensure it meets expectations.
For functions and views, you can run test queries to verify they work correctly.
Explanation of Each Section
1. Matching Kingdoms and Houses
File Section:

sql
Copy code
-- dæmi 1 liður 1: Matching Kingdoms and Houses
Description:

Matches kingdoms from atlas.kingdoms with houses from got.houses based on matching names and regions.
Inserts the mapping into greyjoy.tables_mapping.
How to Run:

Execute the SELECT statement to view the matches.
Run the INSERT statement to upsert the mappings into greyjoy.tables_mapping.
2. One-to-One Mapping Between Houses and Locations
File Section:

sql
Copy code
-- dæmi 1 liður 2: One-to-One Mapping Between Houses and Locations
Description:

Unnests the seats array from got.houses to map each house to a location in atlas.locations.
Inserts unique mappings into greyjoy.tables_mapping, avoiding duplicates.
How to Run:

Execute the entire block, including the CTEs (WITH clauses) and the INSERT statement.
Ensure that the greyjoy.tables_mapping table exists and has the appropriate structure.
3. Largest Families Among Northerners
File Section:

sql
Copy code
-- dæmi 1 liður 3: Largest Families Among Northerners
Description:

Finds houses in "The North" region.
Unnests sworn members of these houses.
Extracts family names from character names.
Aggregates and displays families with more than 5 members.
How to Run:

Execute the entire query block, including the CTEs.
Observe the output showing family names and member counts.
4. Creating View for POV Characters
File Section:

sql
Copy code
-- dæmi 2 liður 1: Creating View for POV Characters
Description:

Creates a view greyjoy.v_pov_characters_human_readable.
The view includes detailed information about POV (Point of View) characters:
Full names with titles
Gender
Family relationships
Birth and death years
Age and alive status
Books they appear in
How to Run:

Execute the entire CREATE OR REPLACE VIEW statement.
Ensure that all referenced tables and columns exist.
5. Displaying POV Characters from the View
File Section:

sql
Copy code
-- dæmi 2 liður 2: Displaying POV Characters from the View
Description:

Selects and displays information from the view created in the previous section.
Orders characters by alive status and age.
How to Run:

Execute the SELECT statement.
Review the output to see the POV characters and their details.
6. Creating Function to Calculate Kingdom Area
File Section:

sql
Copy code
-- dæmi 3 liður 1 part a: Creating Function to Calculate Kingdom Area
Description:

Defines a function greyjoy.get_kingdom_size(kingdom_id INT) that calculates the area of a kingdom in square kilometers.
Uses the ST_Area spatial function provided by PostGIS.
Raises an exception if an invalid kingdom_id is provided.
How to Run:

Execute the CREATE OR REPLACE FUNCTION statement.
Ensure that PostGIS is enabled and that you have the necessary permissions.
7. Finding the Third Largest Kingdom
File Section:

sql
Copy code
-- dæmi 3 liður 1 part b: Finding the Third Largest Kingdom
Description:

Utilizes the function created in the previous section to calculate areas of all kingdoms.
Retrieves the third largest kingdom based on area.
How to Run:

Execute the query block, including the CTE.
The output will display the kingdom_id, name, and area_km2 of the third largest kingdom.
8. Finding the Rarest Location Type Outside The Seven Kingdoms
File Section:

sql
Copy code
-- dæmi 3 liður 2: Finding the Rarest Location Type Outside The Seven Kingdoms
Description:

Identifies locations that are outside The Seven Kingdoms.
Counts the frequency of each location type among these locations.
Finds the rarest location type(s) and lists the names of the locations that belong to it.
How to Run:

Execute the entire query block, including all CTEs.
Review the output to see the rarest location type and associated location names.
Notes
PostGIS Functions:

The code uses PostGIS functions like ST_Area and ST_Contains.
Ensure that the PostGIS extension is properly installed and enabled in your database.
You can enable PostGIS with:
sql
Copy code
CREATE EXTENSION IF NOT EXISTS postgis;
Permissions:

You need sufficient permissions to:
Create schemas (CREATE SCHEMA)
Create functions (CREATE FUNCTION)
Create views (CREATE VIEW)
Insert data into tables (INSERT)
Data Integrity:

The code assumes that the data in the tables is accurate and properly formatted.
Ensure that all required tables and columns exist and are populated with the correct data before running the code.
Error Handling:

The function greyjoy.get_kingdom_size includes error handling to raise an exception if an invalid kingdom_id is provided.
Pay attention to any error messages and resolve them accordingly.
Schema Names:

If your schema names differ from those used in the code, replace them accordingly.
For example, replace greyjoy with your own schema name.
Spatial Reference System (SRS):

Ensure that the geometries in your spatial tables have the correct Spatial Reference System Identifiers (SRIDs).
The code assumes that the SRIDs are consistent across the spatial tables.
Indexes:

For improved performance, consider adding spatial indexes to your geometry columns:
sql
Copy code
CREATE INDEX idx_locations_geog_geom ON atlas.locations USING GIST ((geog::geometry));
CREATE INDEX idx_kingdoms_geog_geom ON atlas.kingdoms USING GIST ((geog::geometry));


