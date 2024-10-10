CREATE OR REPLACE FUNCTION tyrell.get_kingdom_size(kingdom_id INT)
RETURNS NUMERIC AS $$
DECLARE
    kingdom_area NUMERIC;
BEGIN
    -- Reiknum svæðið í ferkílómetrum með geog dálkinum í atlas.kingdoms
    SELECT ST_Area(geog) / 1000000 INTO kingdom_area  -- ST_Area skilar fermetrum, deilum með 1,000,000 (1000^2) fyrir ferkílómetra
    FROM atlas.kingdoms
    WHERE gid = kingdom_id; 

    -- Villuboð ef kingdom finnst ekki
    IF kingdom_area IS NULL THEN
        RAISE EXCEPTION 'Ekki rétt kingdom_id: %', kingdom_id;
    END IF;

    -- Skila flatarmálinu með enga aukastafi
    RETURN round(kingdom_area, 0);
END;
$$ LANGUAGE plpgsql;
