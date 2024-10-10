
-- ================================================
-- dæmi 2 liður 1: Creating View for POV Characters
-- ================================================

CREATE OR REPLACE VIEW greyjoy.v_pov_characters_human_readable AS
WITH pov_characters AS (
    SELECT DISTINCT
        cb.character_id
    FROM got.character_books cb
    WHERE cb.pov = TRUE
),
     character_details AS (
         SELECT
             c.id AS character_id,
             CASE
                 WHEN array_length(c.titles, 1) > 0 AND c.titles[1] IS NOT NULL AND c.titles[1] != ''
                     THEN c.titles[1] || ' ' || c.name
                 ELSE c.name
                 END AS full_name,
             CASE
                 WHEN c.gender ILIKE 'male' THEN 'M'
                 WHEN c.gender ILIKE 'female' THEN 'F'
                 ELSE NULL
                 END AS gender,
             c.father,
             c.mother,
             c.spouse,
             c.born,
             c.died
         FROM got.characters c
                  JOIN pov_characters pc
                       ON c.id = pc.character_id
     ),
     family_info AS (
         SELECT
             cd.*,
             father.name AS father_name,
             mother.name AS mother_name,
             spouse.name AS spouse_name
         FROM character_details cd
                  LEFT JOIN got.characters father
                            ON cd.father = father.id
                  LEFT JOIN got.characters mother
                            ON cd.mother = mother.id
                  LEFT JOIN got.characters spouse
                            ON cd.spouse = spouse.id
     ),
     character_years AS (
         SELECT
             fi.*,
             -- Extract numeric parts from 'born' field
             CASE
                 WHEN fi.born ~ '\d' THEN
                     CASE
                         WHEN fi.born ILIKE '%AC%' THEN
                             CAST(
                                     (regexp_match(fi.born, '(\d{1,4})'))[1] AS INTEGER
                             )
                         WHEN fi.born ILIKE '%BC%' THEN
                             -1 * CAST(
                                     (regexp_match(fi.born, '(\d{1,4})'))[1] AS INTEGER
                                  )
                         ELSE NULL
                         END
                 ELSE NULL
                 END AS born_year,
             -- Extract numeric parts from 'died' field
             CASE
                 WHEN fi.died ~ '\d' THEN
                     CASE
                         WHEN fi.died ILIKE '%AC%' THEN
                             CAST(
                                     (regexp_match(fi.died, '(\d{1,4})'))[1] AS INTEGER
                             )
                         WHEN fi.died ILIKE '%BC%' THEN
                             -1 * CAST(
                                     (regexp_match(fi.died, '(\d{1,4})'))[1] AS INTEGER
                                  )
                         ELSE NULL
                         END
                 ELSE NULL
                 END AS died_year
         FROM family_info fi
     ),
     character_age AS (
         SELECT
             cy.*,
             CASE
                 WHEN cy.born_year IS NOT NULL THEN
                     COALESCE(cy.died_year, 300) - cy.born_year
                 ELSE NULL
                 END AS age,
             CASE
                 WHEN cy.died_year IS NULL THEN TRUE
                 ELSE FALSE
                 END AS alive
         FROM character_years cy
     ),
     books_list AS (
         SELECT
             cb.character_id,
             b.name AS book_name,
             b.released
         FROM got.character_books cb
                  JOIN got.books b
                       ON cb.book_id = b.id
         WHERE cb.character_id IN (SELECT character_id FROM pov_characters)
     ),
     books_aggregated AS (
         SELECT
             bl.character_id,
             ARRAY_AGG(bl.book_name ORDER BY bl.released) AS books
         FROM books_list bl
         GROUP BY bl.character_id
     )
SELECT
    ca.character_id,
    ca.full_name,
    ca.gender,
    ca.father_name AS father,
    ca.mother_name AS mother,
    ca.spouse_name AS spouse,
    ca.born_year AS born,
    ca.died_year AS died,
    ca.age,
    ca.alive,
    ba.books
FROM character_age ca
         LEFT JOIN books_aggregated ba
                   ON ca.character_id = ba.character_id;


-- ================================================
-- dæmi 2 liður 2: Displaying POV Characters from the View
-- ================================================

SELECT
    full_name,
    gender,
    father,
    mother,
    spouse,
    born,
    died,
    age,
    alive,
    books
FROM
    greyjoy.v_pov_characters_human_readable
ORDER BY
    alive DESC,
    age DESC;
