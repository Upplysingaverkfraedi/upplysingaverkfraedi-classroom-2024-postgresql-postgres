CREATE OR REPLACE VIEW stark.v_pov_characters_human_readable AS
WITH pov_info AS (
    SELECT
        c.id,
        -- Sækjum titilinn ef hann er til staðar, annars er nafnið bara sýnt.
        CONCAT(COALESCE(c.titles[1], ''), ' ', c.name) AS full_name,
        -- Sækjum upplýsingar um foreldra og maka.
        c.gender AS gender,
        c.father AS father_id,
        c.mother AS mother_id,
        c.spouse AS spouse_id,
        -- Reiknum fæðingarár úr `born` dálki með regexp_match() föllunum.
        COALESCE(
            NULLIF((regexp_match(c.born, '(\d+) AC'))[1], '')::INTEGER,
            -NULLIF((regexp_match(c.born, '(\d+) BC'))[1], '')::INTEGER
        ) AS born_year,
        -- Reiknum dánarár úr `died` dálki með sömu aðferð.
        COALESCE(
            NULLIF((regexp_match(c.died, '(\d+) AC'))[1], '')::INTEGER,
            -NULLIF((regexp_match(c.died, '(\d+) BC'))[1], '')::INTEGER
        ) AS died_year,
        -- Reiknum út aldur persónunnar með því að nota 300 AC sem viðmið ef viðkomandi er á lífi.
        CASE
            WHEN c.died IS NOT NULL THEN
                COALESCE(
                    NULLIF((regexp_match(c.died, '(\d+) AC'))[1], '')::INTEGER,
                    -NULLIF((regexp_match(c.died, '(\d+) BC'))[1], '')::INTEGER
                ) - COALESCE(
                    NULLIF((regexp_match(c.born, '(\d+) AC'))[1], '')::INTEGER,
                    -NULLIF((regexp_match(c.born, '(\d+) BC'))[1], '')::INTEGER
                )
            ELSE
                300 - COALESCE(
                    NULLIF((regexp_match(c.born, '(\d+) AC'))[1], '')::INTEGER,
                    -NULLIF((regexp_match(c.born, '(\d+) BC'))[1], '')::INTEGER
                )
        END AS age,
        -- Flag sem gefur til kynna hvort persónan sé á lífi.
        CASE WHEN c.died IS NULL THEN TRUE ELSE FALSE END AS alive,
        -- Bækur sem persónan kemur fyrir í, geymdar sem listi.
        (
            SELECT ARRAY_AGG(sorted_books.name)
            FROM (
                SELECT b.name
                FROM got.books b
                JOIN got.character_books cb ON b.id = cb.book_id
                WHERE cb.character_id = c.id AND cb.pov = TRUE
                GROUP BY b.name, b.released
                ORDER BY b.released ASC
            ) AS sorted_books
        ) AS book_titles
    FROM
        got.characters c
    -- Tengjum við character_books töfluna til að sækja POV-persónur.
    JOIN
        got.character_books cb ON c.id = cb.character_id
    WHERE
        cb.pov = TRUE
    GROUP BY
        c.id, c.titles, c.name, c.gender, c.father, c.mother, c.spouse, c.born, c.died
)
SELECT
    id,
    full_name,
    gender,
    (SELECT name FROM got.characters WHERE id = father_id) AS father,
    (SELECT name FROM got.characters WHERE id = mother_id) AS mother,
    (SELECT name FROM got.characters WHERE id = spouse_id) AS spouse,
    born_year,
    died_year,
    age,
    alive,
    book_titles
FROM
    pov_info;
