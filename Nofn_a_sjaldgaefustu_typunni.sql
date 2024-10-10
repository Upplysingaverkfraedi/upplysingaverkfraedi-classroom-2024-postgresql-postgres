WITH locations_outside_seven_kingdoms AS (
    SELECT l.name, l.type
    FROM atlas.locations l
    LEFT JOIN atlas.kingdoms k ON ST_DWithin(l.geog::geometry, k.geog::geometry, 0)
    WHERE k.name NOT IN ('The North', 'The Vale', 'The Westerlands', 'The Riverlands', 
                         'The Reach', 'The Stormlands', 'The Crownsland')
    or k.name IS NULL
    )
-- Fáum nöfnin á sjaldgæfustu staðsetningartýpunni
SELECT l.name, l.type
FROM locations_outside_seven_kingdoms l
WHERE l.type = 'Landmark';