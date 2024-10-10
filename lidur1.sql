-- ================================================
-- Hluti 1 liður 1: Samsvörun konungsríkja og húsa
-- ================================================

-- Skref 1:Finna samsvörun milli konungsríkja og húsa
SELECT
    k.gid AS kingdom_id,
    k.name AS kingdom_name,
    h.id AS house_id,
    h.name AS house_name
FROM atlas.kingdoms k
         FULL OUTER JOIN got.houses h
                         ON k.name = h.region;

-- Skref 2: Setjum kortlagninguna í greyjoy.tables_mapping

INSERT INTO greyjoy.tables_mapping (kingdom_id, house_id)
SELECT
    k.gid AS kingdom_id,
    h.id AS house_id
FROM atlas.kingdoms k
         FULL OUTER JOIN got.houses h
                         ON k.name = h.region
WHERE k.gid IS NOT NULL AND h.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM greyjoy.tables_mapping tm
    WHERE tm.kingdom_id = k.gid AND tm.house_id = h.id
);


-- ================================================
-- Hluti 1 liður 2: Gagntæk vörpun til að finna samsvörun milli húsa og staðsetningu
-- ================================================

-- Skref 1: Búa til CTE til að afhreiðra sæti og kortlagningu
WITH house_seats AS (
    SELECT
        h.id AS house_id,
        h.name AS house_name,
        UNNEST(h.seats) AS seat_name,
        h.region
    FROM got.houses h
),
     unique_mappings AS (
         SELECT DISTINCT ON (hs.house_id)
             hs.house_id,
             hs.house_name,
             l.gid AS location_id,
             l.name AS location_name
         FROM house_seats hs
                  JOIN atlas.locations l
                       ON hs.seat_name = l.name
         WHERE l.name IS NOT NULL
         ORDER BY hs.house_id, l.gid
     )

-- Skref 2: Setja nýja kortlagningu inn í greyjoy.tables_mapping
INSERT INTO greyjoy.tables_mapping (house_id, location_id)
SELECT
    um.house_id,
    um.location_id
FROM unique_mappings um
WHERE NOT EXISTS (
    SELECT 1
    FROM greyjoy.tables_mapping tm
    WHERE tm.house_id = um.house_id
       OR tm.location_id = um.location_id
);

-- Skref 3: Sýna niðurstöður fyrir norður
WITH house_seats AS (
    SELECT
        h.id AS house_id,
        h.name AS house_name,
        UNNEST(h.seats) AS seat_name,
        h.region
    FROM got.houses h
),
     unique_mappings AS (
         SELECT DISTINCT ON (hs.house_id)
             hs.house_id,
             hs.house_name,
             l.gid AS location_id,
             l.name AS location_name
         FROM house_seats hs
                  JOIN atlas.locations l
                       ON hs.seat_name = l.name
         WHERE l.name IS NOT NULL
         ORDER BY hs.house_id, l.gid
     )
SELECT
    um.house_id,
    um.house_name,
    um.location_id,
    um.location_name
FROM unique_mappings um
         JOIN got.houses h
              ON um.house_id = h.id
WHERE h.region = 'The North';

-- ================================================
-- Hluti 1 liður 3: Stærstu fjölskyldur meðal norðurmanna
-- ================================================


-- Skref 1: Finna hús í 'The North' og afhreiðra sworn_members
WITH north_houses AS (
    SELECT
        h.id AS house_id,
        UNNEST(h.sworn_members) AS sworn_member_id
    FROM got.houses h
    WHERE h.region = 'The North'
),

-- Skref 2: Ná í nöfn og draga út fjölskyldu nöfn
     characters_with_family AS (
         SELECT
             c.id AS character_id,
             c.name AS character_name,
             SPLIT_PART(c.name, ' ', -1) AS family_name
         FROM north_houses nh
                  JOIN got.characters c
                       ON c.id = nh.sworn_member_id
         WHERE c.name IS NOT NULL
     )

-- Skref 3:
SELECT
    cwf.family_name,
    COUNT(*) AS member_count
FROM characters_with_family cwf
GROUP BY cwf.family_name
HAVING COUNT(*) > 5
ORDER BY member_count DESC, family_name ASC;