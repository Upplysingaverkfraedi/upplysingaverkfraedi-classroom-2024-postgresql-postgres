-- Reiknar út flatarmál konungsríkis út frá landfræðilegum gögnum í ferkílómetrum með engum aukastöfum.
CREATE OR REPLACE FUNCTION lannister.get_kingdom_size(kingdom_id integer)
RETURNS integer AS $$
DECLARE
    area_km2 integer;

--Throwar villu ef það er ólöglegt gildi
BEGIN
    IF NOT EXISTS (SELECT 1 FROM atlas.kingdoms k WHERE k.gid = kingdom_id) THEN
        RAISE EXCEPTION 'Kingdom with id % not found', kingdom_id;
    END IF;

    SELECT ST_Area(geog)/1e6 INTO area_km2
    FROM atlas.kingdoms
    WHERE gid = kingdom_id;

    RETURN area_km2;
END;
$$ LANGUAGE plpgsql;

-- Þetta ætti að gefa villu, því þetta er ólöglegt kingdom_id
select lannister.get_kingdom_size(-1);

-- Þriðja stærsta konungsríkið
SELECT * FROM pg_tables WHERE schemaname IN ('atlas', 'got')
ORDER BY schemaname, tablename;

select name from atlas.kingdoms order by lannister.get_kingdom_size(gid) desc
OFFSET 2
LIMIT 1;

CREATE OR REPLACE FUNCTION lannister.get_kingdom_size(kingdom_id integer)
RETURNS integer AS $$
DECLARE
    area_km2 integer;
BEGIN
    SELECT ST_Area(geog)/1e6
    INTO area_km2
    FROM atlas.kingdoms
    WHERE gid = kingdom_id;

    RETURN area_km2;
END;
$$ LANGUAGE plpgsql;

-- Finnur sjaldgæfustu staðsetningategund (location_type) utan The Seven Kingdoms og heiti staðanna sem tilheyra þeirri tegund.

SELECT
    l.name,
    l.type
FROM atlas.locations l
WHERE l.type = (
    SELECT
        l.type
    FROM atlas.locations l
    LEFT JOIN atlas.kingdoms k on ST_DWithin(k.geog, l.geog, 0)
    WHERE k.name IS NULL OR k.name NOT IN ('Kingdom of the North', 'The Vale', 'The Riverlands', 'Iron Islands', 'The Westerlands', 'The Stormlands', 'The Reach', 'Dorne')
    GROUP BY l.type
    ORDER BY COUNT(*) ASC
    LIMIT 1
);
