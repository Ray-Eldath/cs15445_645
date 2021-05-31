--  Q1
SELECT DISTINCT type
FROM titles
ORDER BY type;

--  Q2
SELECT type, primary_title, MAX(runtime_minutes)
FROM titles
GROUP BY type
ORDER BY type, primary_title;

--  Q3
SELECT type, COUNT(title_id) AS COUNT
FROM titles
GROUP BY TYPE
ORDER BY COUNT;

--  Q4
SELECT CAST(premiered / 10 * 10 AS text) || 's' AS decade,
       COUNT(*) AS COUNT
FROM titles
WHERE premiered IS NOT NULL
GROUP BY decade
ORDER BY COUNT DESC;

--  Q5
SELECT CAST(premiered / 10 * 10 AS text) || 's'                                   AS decade,
       ROUND((CAST(COUNT(*) AS REAL) / (SELECT COUNT(*) FROM titles)) * 100.0, 4) AS percentage
FROM titles
WHERE premiered IS NOT NULL
GROUP BY decade
ORDER BY percentage DESC, decade ASC;

--  Q6
-- SELECT primary_title, COUNT(*) AS COUNT
-- FROM akas
--     LEFT JOIN titles t
-- ON akas.title_id = t.title_id
-- GROUP BY akas.title_id
-- ORDER BY COUNT DESC
--     LIMIT 10;
SELECT (SELECT primary_title FROM titles WHERE title_id = akas.title_id), COUNT(*) AS COUNT
FROM akas
GROUP BY title_id
ORDER BY COUNT DESC
    LIMIT 10;

--  Q7
SELECT primary_title,
       (CAST(r.votes AS float) / (r.votes + 25000.0)) * r.rating +
       (25000.0 / (r.votes + 25000.0)) * (SELECT SUM(votes * rating) / SUM(votes) FROM ratings) AS weighted_rating
FROM titles
         LEFT JOIN ratings r ON titles.title_id = r.title_id
ORDER BY weighted_rating DESC LIMIT 250;

--  Q8
SELECT COUNT(DISTINCT person_id)
FROM crew
WHERE (category == 'actor' OR category == 'actress')
  AND title_id IN (
    SELECT title_id
    FROM crew
    WHERE person_id = (SELECT person_id FROM people WHERE NAME = 'Mark Hamill' AND born = 1951)
);

--  Q9
SELECT primary_title
FROM titles
WHERE type = 'movie'
  AND title_id IN (
    SELECT title_id
    FROM crew
    WHERE title_id IN (SELECT title_id
                       FROM crew
                       WHERE person_id =
                             (SELECT person_id FROM people WHERE name = 'Mark Hamill' AND born = 1951))
      AND person_id = (SELECT person_id FROM people WHERE name = 'George Lucas' AND born = 1944));

--  Q10
WITH RECURSIVE splitter(genre, genres) AS (
    SELECT '', titles.genres
    FROM titles
    UNION ALL
    SELECT substr(genres, 1, CASE WHEN instr(genres, ',') <> 0 THEN instr(genres, ',') - 1 ELSE length(genres) END),
           CASE WHEN instr(genres, ',') THEN substr(genres, instr(genres, ',') + 1, length(genres)) ELSE '' END
    FROM splitter
    WHERE genres <> ''
)
SELECT genre, COUNT(*) AS num
FROM splitter
WHERE genre <> ''
  AND genre <> '\N'
GROUP BY genre
ORDER BY num DESC;