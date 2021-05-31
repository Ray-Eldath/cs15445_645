-- Q1
SELECT DISTINCT(type)
FROM titles
ORDER BY type;


-- Q2
WITH types(type, runtime_minutes) AS (
    SELECT type, MAX(runtime_minutes)
    FROM titles
    GROUP BY type
)
SELECT titles.type, titles.primary_title, titles.runtime_minutes
FROM titles
         JOIN types
              ON titles.runtime_minutes == types.runtime_minutes AND titles.type == types.type
ORDER BY titles.type, titles.primary_title;


-- Q3
SELECT type, COUNT(*) AS title_count
FROM titles
GROUP BY type
ORDER BY title_count ASC;


-- Q4
SELECT CAST(premiered / 10 * 10 AS TEXT) || 's' AS decade,
       COUNT(*)                                 AS num_movies
FROM titles
WHERE premiered IS NOT NULL
GROUP BY decade
ORDER BY num_movies DESC;


-- Q5
SELECT CAST(premiered / 10 * 10 AS TEXT) || 's'                                 AS decade,
       ROUND(CAST(COUNT(*) AS REAL) / (SELECT COUNT(*) FROM titles) * 100.0, 4) AS percentage
FROM titles
WHERE premiered IS NOT NULL
GROUP BY decade
ORDER BY percentage DESC, decade ASC;


-- Q6
WITH translations AS (
    SELECT title_id, COUNT(*) AS num_translations
    FROM akas
    GROUP BY title_id
    ORDER BY num_translations DESC, title_id
    LIMIT 10
    )
SELECT titles.primary_title, translations.num_translations
FROM translations
         JOIN titles
              ON titles.title_id == translations.title_id
ORDER BY translations.num_translations DESC;


-- Q7
WITH av(average_rating) AS (
    SELECT SUM(rating * votes) / SUM(votes)
    FROM ratings
             JOIN titles
                  ON titles.title_id
    == ratings.title_id AND titles.type == "movie"
    )
   , mn(min_rating) AS (
SELECT 25000.0)
SELECT primary_title,
       (votes / (votes + min_rating)) * rating + (min_rating / (votes + min_rating)) * average_rating AS weighed_rating
FROM ratings,
     av,
     mn
         JOIN titles
              ON titles.title_id == ratings.title_id AND titles.type == "movie"
ORDER BY weighed_rating DESC
    LIMIT 250;


-- Q8
WITH hamill_titles AS (
    SELECT DISTINCT(crew.title_id)
    FROM people
             JOIN crew
                  ON crew.person_id == people.person_id AND people.name == "Mark Hamill" AND people.born == 1951
    )
SELECT COUNT(DISTINCT (crew.person_id))
FROM crew
WHERE (crew.category == "actor" OR crew.category == "actress")
  AND crew.title_id IN hamill_titles;


-- Q9
WITH hamill_movies(title_id) AS (
    SELECT crew.title_id
    FROM crew
             JOIN people
                  ON crew.person_id == people.person_id AND people.name == "Mark Hamill" AND people.born == 1951
    )
SELECT titles.primary_title
FROM crew
         JOIN people
              ON crew.person_id == people.person_id AND people.name == "George Lucas" AND people.born == 1944 AND crew.title_id IN hamill_movies
  JOIN titles
ON crew.title_id == titles.title_id AND titles.type == "movie"
ORDER BY titles.primary_title;


-- Q10
WITH RECURSIVE split(genre, rest) AS (
    SELECT '', genres || ','
    FROM titles
    WHERE genres != "\N"
UNION ALL
SELECT substr(rest, 0, instr(rest, ',')),
       substr(rest, instr(rest, ',') + 1)
FROM split
WHERE rest != ''
)
SELECT genre, COUNT(*) AS genre_count
FROM split
WHERE genre != ''
GROUP BY genre
ORDER BY genre_count DESC;