--CREATE or replace VIEW martell.v_pov_characters_human_readable as
WITH characters as (SELECT c.id,
                           COALESCE(NULLIF(split_part(array_to_string(c.titles, ','), ',', 1), ''), c.name) || ' ' || c.name AS full_name,
                           --c.name,
                           substr(c.gender, 1, 1)                as gender,
                           mother.name                           as mother,
                           father.name                           as father,
                           spouse.name                           as spouse,
                           Regexp_match(c.born, '(\d+) (AC|BC)') as born,
                           Regexp_match(c.died, '(\d+) (AC|BC)') as died
                    --age
                    --alive
                    --books (tengja charcters.id við books(id) via character_books
                    FROM got.characters c -- Held þetta er fyrir titles

                             left join got.characters mother ON mother.id = c.mother -- Fyrir mother.name
                             left join got.characters father ON father.id = c.father -- Fyrir father.name
                             left join got.characters spouse ON spouse.id = c.spouse
                    where c.father is not null
                      and c.mother is not null
                      and c.spouse is not null
                    ),


characters_year as (
select *,
       case when born[2] = 'AC' then born[1]::int when born[2] = 'BC' then - born[1]::int end as year_born,
       case when died[2] = 'AC' then died[1]::int when died[2] = 'BC' then - died[1]::int end as year_died
            from characters),

book_appearances AS (

    Select cb.character_id,
           STRING_AGG(b.name,', ' ORDER BY b.released) AS book_titles
    FROM got.character_books cb
    JOIN got.books b
        ON b.id = cb.book_id
    GROUP BY cb.character_id
    )
select cy.id,
       cy.full_name,
       cy.gender,
       cy.mother,
       cy.father,
       cy.spouse,
       cy.year_born,
       cy.year_died,

       case when cy.year_died is not null and cy.year_born is not null then cy.year_died-cy.year_born
           ELSE 300-cy.year_born
           end as age, -- Ég sé að Princess Daena Targaryen er 155 ára gömull, er örugglega einhver villa í kóðanum
       case when cy.year_died IS NULL THEN TRUE else FALSE end as alive,

       -- List of book titles in correct order
       ba.book_titles
from characters_year cy
left join book_appearances ba ON ba.character_id = cy.id
ORDER BY alive DESC, age DESC;

-- cy = characters_year; ba = book_apperancecs