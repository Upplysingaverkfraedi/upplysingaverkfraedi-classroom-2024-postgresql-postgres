-- Step 1: Identify the geometries of The Seven Kingdoms
WITH seven_kingdoms AS (
    SELECT * FROM atlas.kingdoms
    WHERE name IN (
        'The North', 'The Vale of Arryn', 'The Riverlands', 
        'The Iron Islands', 'The Westerlands', 'The Reach', 
        'The Stormlands', 'Dorne'
    )
),

-- Step 2: Combine their geometries into a single geometry
seven_kingdoms_geog AS (
    SELECT ST_Union(geog::geometry) AS geom FROM seven_kingdoms
),

-- Step 3: Find locations outside The Seven Kingdoms
locations_outside AS (
    SELECT l.*
    FROM atlas.locations l, seven_kingdoms_geog skg
    WHERE NOT ST_Contains(skg.geom, l.geog::geometry)
),

-- Step 4: Count the occurrences of each type outside The Seven Kingdoms
location_type_counts AS (
    SELECT l.type, COUNT(*) AS count
    FROM locations_outside l
    GROUP BY l.type
),

-- Step 5: Find the minimum count (i.e., the rarest type)
min_count AS (
    SELECT MIN(count) AS min_count FROM location_type_counts
),

-- Step 6: Identify the rarest type(s)
rarest_types AS (
    SELECT type FROM location_type_counts WHERE count = (SELECT min_count FROM min_count)
)

-- Step 7: Retrieve the names of locations that belong to the rarest type(s)
SELECT l.name, l.type
FROM locations_outside l
WHERE l.type IN (SELECT type FROM rarest_types);
