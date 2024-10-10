-- Liður 1
--Skrifið SQL fyrirspurn sem finnur samsvörun á milli ríkja í Game of Thrones heiminum (úr atlas.kingdoms) og húsum (úr got.houses) út frá því hvaða hús tilheyra hvaða ríki. Þið skuluð sýna öll ríki og öll hús, líka þau sem eru ekki með samsvörun. Upsertið möppunina í töfluna <teymi>.tables_mapping með dálkunum kingdom_id, house_id.

-- Finna samsvörun milli ríkja og húsa:
WITH KingdomHouseMapping AS (
    SELECT
        k.gid AS kingdom_id,
        h.id AS house_id
    FROM
        atlas.kingdoms k
    LEFT JOIN
        got.houses h
    ON
        REPLACE(k.name, 'Crownsland', 'Crownlands') ILIKE h.region  -- Ensure matching Crownlands
)
-- Upsert inn í stark.tables_mapping töfluna:
INSERT INTO stark.tables_mapping (kingdom_id, house_id)
SELECT
    kingdom_id,
    house_id
FROM
    KingdomHouseMapping
ON CONFLICT (house_id) DO NOTHING;  -- Skip insert if a duplicate is found

-- Athuga hvort öll hús sé tengd við ríki:
SELECT h.name
FROM got.houses h
LEFT JOIN stark.tables_mapping tm ON h.id = tm.house_id
WHERE tm.kingdom_id IS NULL;

-- Skoða töfluna til að sjá hvort allar upplýsingar séu komnar:
SELECT *
FROM stark.tables_mapping;

-- Athuga hvort einhver ríki séu ekki tengd húsi:
SELECT k.name
FROM atlas.kingdoms k
LEFT JOIN stark.tables_mapping tm ON k.gid = tm.kingdom_id
WHERE tm.house_id IS NULL;


-- Liður 2
    -- Skrifið SQL fyrirspurn með CTE sem finnur samsvörun á milli staða og húsa. Hér er markmiðið að finna gagntæka vörpun (one-to-one mapping), þar sem hver staður úr atlas.locations mappast á nákvæmlega eitt hús úr got.houses.
-- Upsertið niðurstöður fyrir allan heiminn í töfluna stark.tables_mapping með dálkunum house_id, location_id.
-- Sýnið svo niðurstöður fyrir Norðrið.

-- CTE til að finna samsvörun á milli staða og húsa:
WITH LocationHouseMapping AS (
    SELECT
        l.gid AS location_id,
        h.id AS house_id,
        l.name AS location_name,
        h.name AS house_name,
        l.summary
    FROM atlas.locations l
    LEFT JOIN got.houses h
    ON l.name ILIKE '%' || h.name || '%'
    OR l.summary ILIKE '%' || h.name || '%'
    OR h.name ILIKE '%' || split_part(l.summary, ' ', array_length(string_to_array(l.summary, ' '), 1)) || '%'
)

-- Setja niðurstöðurnar inn í Stark töfluna:
INSERT INTO stark.tables_mapping (house_id, location_id)
SELECT house_id, location_id
FROM LocationHouseMapping
WHERE house_id IS NOT NULL  -- Vera viss um að house_id sé ekki NULL
AND location_id IS NOT NULL  -- Vera viss um að location_id sé ekki NULL
AND NOT EXISTS (  -- Setja ekki inn duplicates
    SELECT 1
    FROM stark.tables_mapping tm
    WHERE tm.house_id = LocationHouseMapping.house_id
    OR tm.location_id = LocationHouseMapping.location_id
);

-- Sýna niðurstöður fyrir Norðrið:
SELECT *
FROM stark.tables_mapping tm
JOIN got.houses h ON tm.house_id = h.id
WHERE h.region = 'The North';



-- Liður 3
    -- Skrifið SQL fyrirspurn með CTE sem finnur stærstu ættir allra norðanmanna (þ.e. persónur sem eru hliðhollar húsinu The North). Einskorðið ykkur við ættir sem hafa fleiri en 5 hliðholla meðlimi. Úttakið ætti að vera raðað eftir fjölda meðlima (stærstu fyrst) og í stafrófsröð.

-- CTE til að finna stærstu ættir norðanmanna:
WITH SwornFamilies AS (
    SELECT
        h.id AS house_id,
        unnest(h.sworn_members) AS member_id  -- unnest() will break down the array of sworn_members into individual rows
    FROM
        got.houses h
    WHERE
        h.region = 'The North'  -- Filter to only get houses in The North
)
SELECT * FROM SwornFamilies;  -- Display the results to verify the extraction

-- CTE to extract character details and match them with their respective houses
WITH SwornFamilies AS (
    SELECT
        h.id AS house_id,
        unnest(h.sworn_members) AS member_id
    FROM
        got.houses h
    WHERE
        h.region = 'The North'
),
CharacterDetails AS (
    SELECT
        c.id AS character_id,
        c.name,
        split_part(c.name, ' ', array_length(string_to_array(c.name, ' '), 1)) AS family_name
    FROM
        got.characters c
)
-- Join SwornFamilies with CharacterDetails to get the character details for each sworn member
SELECT
    sf.house_id,
    cd.character_id,
    cd.name,
    cd.family_name
FROM
    SwornFamilies sf
JOIN
    CharacterDetails cd
ON
    sf.member_id = cd.character_id;


-- CTE til að telja fjölda manna í ættum og filtera frá þær ættir sem eru með fleiri en fimm meðlimi:
WITH SwornFamilies AS (
    SELECT
        h.id AS house_id,
        unnest(h.sworn_members) AS member_id
    FROM
        got.houses h
    WHERE
        h.region = 'The North'
),
CharacterDetails AS (
    SELECT
        c.id AS character_id,
        c.name,
        split_part(c.name, ' ', array_length(string_to_array(c.name, ' '), 1)) AS family_name
    FROM
        got.characters c
),
FamilyCount AS (
    -- Setja SwornFamilies saman við CharacterDetails til að fá character details fyrir hvern meðlim:
    SELECT
        cd.family_name,
        COUNT(cd.character_id) AS member_count
    FROM
        SwornFamilies sf
    JOIN
        CharacterDetails cd
    ON
        sf.member_id = cd.character_id
    GROUP BY
        cd.family_name
    HAVING
        COUNT(cd.character_id) > 5
)
-- Velja stærstu fjölskyldurnar, í talnaröð og svo eftir nafni:
SELECT
    family_name,
    member_count
FROM
    FamilyCount
ORDER BY
    member_count DESC,
    family_name ASC;


-- sýna stark töfluna:
SELECT *
FROM stark.tables_mapping;
