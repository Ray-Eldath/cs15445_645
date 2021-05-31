WITH RECURSIVE split(word, str) AS (
    SELECT '', 'A,B,C'
    UNION ALL
    SELECT substr(str, 1, CASE WHEN INSTR(str, ',') <> 0 THEN INSTR(str, ',') - 1 ELSE length(str) END),
           CASE WHEN instr(str, ',') THEN substr(str, instr(str, ',') + 1, length(str)) ELSE '' END
    FROM split
    WHERE str <> ''
)
SELECT *
FROM split;


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


SELECT '', titles.genres
FROM titles;


SELECT substr('abc', 1, 2);


SELECT instr('abc', 'b');


WITH RECURSIVE "1to10"(v) AS (
    SELECT 1
    UNION ALL
    SELECT v + 1
    FROM "1to10"
    WHERE v < 10
)
SELECT *
FROM "1to10";