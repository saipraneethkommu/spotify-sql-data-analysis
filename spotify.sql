-- Advanced Spotify SQL Project

-- create table
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);
select * from spotify;


-- 1. Data Exploration

SELECT COUNT(*) FROM spotify;

SELECT COUNT(DISTINCT artist) FROM spotify;

SELECT DISTINCT album FROM spotify;

DELETE FROM spotify
WHERE duration_min = 0;
SELECT * FROM spotify
WHERE duration_min = 0;

SELECT DISTINCT channel FROM spotify;

SELECT DISTINCT most_played_on FROM spotify;


-- 2. Querying the Data

-- Easy Level Queries

-- 1. Retrieve the names of all tracks that have more than 1 billion streams.
SELECT DISTINCT track, stream
FROM spotify 
WHERE stream >= 1000000000

-- 2. List all albums along with their respective artists.
SELECT DISTINCT artist, album
FROM spotify;

-- 3. Get the total number of comments for tracks where licensed = TRUE
SELECT SUM(comments) AS total_comments
FROM spotify
WHERE licensed = TRUE;

-- 4. Find all tracks that belong to the album type single
SELECT *
FROM spotify
WHERE album_type = 'single';

-- 5. Count the total number of tracks by each artist.
SELECT artist, COUNT(track) AS total_tracks
FROM spotify
GROUP BY artist
ORDER BY 2 DESC;


-- Medium Level Queries

-- 1. Calculate the average danceability of tracks in each album.
SELECT album, AVG(danceability) AS average_danceability
FROM spotify
GROUP BY album
ORDER BY 2 DESC;

-- 2. Find the top 5 tracks with the highest energy values.
SELECT track, energy
FROM spotify
order by 2 desc
limit 5

-- 3.  List all tracks along with their views and likes where official_video = TRUE.
SELECT track, views, likes
FROM spotify
WHERE official_video = TRUE;

-- 4. For each album, calculate the total views of all associated tracks.
SELECT track, album, SUM(views) AS total_views
FROM spotify
GROUP BY 1, 2
ORDER BY 3 DESC;

-- 5. Retrieve the track names that have been streamed on Spotify more than YouTube.
SELECT track, streamed_on_spotify, streamed_on_youtube
FROM (
    SELECT track, 
        COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END), 0) AS streamed_on_youtube,
        COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END), 0) AS streamed_on_spotify
    FROM spotify
    GROUP BY track
) AS t1
WHERE t1.streamed_on_spotify > t1.streamed_on_youtube
AND t1.streamed_on_youtube <> 0;


-- Advanced Level Queries

-- 1. Find the top 3 most-viewed tracks for each artist using window functions.
WITH RankedTracks AS (
    SELECT artist, track, SUM(views) AS total_view,
           DENSE_RANK() OVER (PARTITION BY artist ORDER BY SUM(views) DESC) AS d_rnk
    FROM spotify
    GROUP BY artist, track
)
SELECT *
FROM RankedTracks
WHERE d_rnk <= 3;

-- 2. Write a query to find tracks where the liveness score is above the average.
select track, artist, liveness
from spotify
where liveness > (select avg(liveness) from spotify)

-- 3. Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.
with cte as
	(select album, max(energy) as highest_energy, min(energy) as lowest_energy
	from spotify
	group by 1)

select album, highest_energy - lowest_energy as energy_diff
from cte
order by 2 desc

-- 4. Find tracks where the energy-to-liveness ratio is greater than 1.2.
SELECT track, energy, liveness, (energy / liveness) AS energy_liveness_ratio
FROM spotify
WHERE (energy / liveness) > 1.2
ORDER BY 4 DESC;

-- 5. Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.
SELECT 
    artist, 
    track, 
    views, 
    likes, 
    SUM(likes) OVER w AS cumulative_likes
FROM 
    spotify
WINDOW w AS (ORDER BY views DESC)
ORDER BY views;


-- Query Optimization

CREATE INDEX idx_artist ON spotify (artist);

EXPLAIN ANALYZE 
SELECT artist, track, views
FROM spotify
WHERE artist = 'Gorillaz' AND most_played_on = 'Youtube'
ORDER BY stream DESC 
LIMIT 25;
