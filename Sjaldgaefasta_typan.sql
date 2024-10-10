WITH locations_outside_seven_kingdoms AS (
    SELECT l.name, l.type
    FROM atlas.locations l
    LEFT JOIN atlas.kingdoms k ON ST_DWithin(l.geog::geometry, k.geog::geometry, 0)
    WHERE k.name NOT IN ('The North', 'The Vale', 'The Westerlands', 'The Riverlands', 
                         'The Reach', 'The Stormlands', 'The Crownsland')
    OR k.name IS NULL  -- Til að taka með staði sem eru ekki í neinu konungsríki
), 
rare_location_type AS (
    -- Finna sjaldgæfustu tegundina
    SELECT type
    FROM locations_outside_seven_kingdoms
    GROUP BY type
    ORDER BY COUNT(*) ASC -- byrja á lægsta fjöldanum
    LIMIT 1 -- taka bara fyrsta valkostinn
)
-- Finna nöfnin á stöðunum með sjaldgæfustu tegundina
SELECT l.name, l.type
FROM locations_outside_seven_kingdoms l
JOIN rare_location_type rlt ON l.type = rlt.type;