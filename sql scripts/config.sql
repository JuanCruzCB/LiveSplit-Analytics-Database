/* The date from which all data before it is ignored during the analysis. */
DROP TABLE IF EXISTS _cfg_limit_date;
CREATE TABLE _cfg_limit_date AS
SELECT 'limit-date'::DATE AS limit_date;

/* Default split names for the game. TODO: This needs to be customizable. */

DROP TABLE IF EXISTS _cfg_default_split_names;
CREATE TABLE _cfg_default_split_names(split_index SERIAL PRIMARY KEY, split_name TEXT);

INSERT INTO _cfg_default_split_names(split_name)
VALUES
    ('-Start'),
    ('-Village'),
    ('-Farm'),
    ('{1-1} Boulder'),
    ('-Canyon'),
    ('-Factory'),
    ('{1-2} Enter House'),
    ('-Exit House'),
    ('-Village 2'),
    ('-Underground'),
    ('-Graveyard'),
    ('-Crows'),
    ('-Swamp'),
    ('{1-3} Del Lago'),
    ('-Wake Up'),
    ('-Waterfall'),
    ('-Boat Ride'),
    ('-El Gigante'),
    ('-Dogs'),
    ('{2-1} Church'),
    ('-Ashley'),
    ('-Graveyard 2'),
    ('-Underground 2'),
    ('-Village 3'),
    ('-Farm 2'),
    ('{2-2} Cabin'),
    ('-Lever'),
    ('-El Gigante 2'),
    ('-Gondola'),
    ('-Mendez'),
    ('-Gondola 2'),
    ('{2-3} Truck'),
    ('-Enter Castle'),
    ('-Catapults'),
    ('-Swords Room'),
    ('-Castle Key'),
    ('-Garrador'),
    ('-Water Hall'),
    ('{3-1} Ceremony Room'),
    ('-Ceremony Room'),
    ('-Novistadors 1'),
    ('-Ceremony Room 2'),
    ('-Gallery'),
    ('-Fountain'),
    ('{3-2} Maze'),
    ('-Bedroom'),
    ('-Cage'),
    ('{3-3} Bridge'),
    ('-Save Ashley'),
    ('-Cranks'),
    ('-Puzzle'),
    ('{3-4} Exit'),
    ('-Reunited'),
    ('-Cart Room'),
    ('-Lava Room'),
    ('-Cart Room 2'),
    ('-Chimera Wall'),
    ('-Cart Room 3'),
    ('-Hallway'),
    ('-Queen''s Grail'),
    ('-Hallway 2'),
    ('-King''s Grail'),
    ('-Hallway 3'),
    ('-Novistadors 2'),
    ('-Catapults 2'),
    ('-Clock Tower'),
    ('-Bridge'),
    ('-Garradors'),
    ('-Striker'),
    ('{4-1} Verdugo'),
    ('-Merchant'),
    ('-Boulder'),
    ('-El Gigantes'),
    ('{4-2} Novistadors 3'),
    ('-Ruins'),
    ('-Enter Mines'),
    ('-Minecart'),
    ('{4-3} Emblem'),
    ('-Salazar Statue'),
    ('-Elevator'),
    ('-Salazar'),
    ('{4-4} Exit'),
    ('-Enter Island'),
    ('-Outside Facility'),
    ('-Oven Man'),
    ('-Monitor Room'),
    ('-Garage Door'),
    ('-Hallway 4'),
    ('-Regenerator'),
    ('-Hallway 5'),
    ('-Freezer'),
    ('-Hallway 6'),
    ('-Trash Room'),
    ('-Cell'),
    ('-Stairs Room'),
    ('-Iron Maiden'),
    ('-Stairs Room 2'),
    ('{5-1} Cell'),
    ('-Ashley''s Back'),
    ('-Observation Room'),
    ('-Iron Maidens'),
    ('-Wrecking Ball'),
    ('-Regenerators'),
    ('-Truck'),
    ('{5-2} Merchant'),
    ('-Ceremony Room 3'),
    ('-Krauser'),
    ('-Lasers'),
    ('-Cave'),
    ('-U-3'),
    ('-Tents'),
    ('{5-3} Krauser'),
    ('-Military Area'),
    ('-RIP Mike'),
    ('-Ruins 2'),
    ('-Jail'),
    ('-Key Card'),
    ('-Ashley Again'),
    ('{5-4} Plaga Removal'),
    ('-Exit'),
    ('-Construction Site'),
    ('-Saddler'),
    ('{6-1} Jetski');

DROP TABLE IF EXISTS _cfg_chapter_area_splits_from_to;
CREATE TABLE _cfg_chapter_area_splits_from_to(from_split_index INT, to_split_index INT, chapter TEXT, area TEXT);

INSERT INTO _cfg_chapter_area_splits_from_to(from_split_index, to_split_index, chapter, area)
VALUES
    (1, 4, '1-1', 'Village'),
    (5, 7, '1-2', 'Village'),
    (8, 14, '1-3', 'Village'),
    (15, 20, '2-1', 'Village'),
    (21, 26, '2-2', 'Village'),
    (27, 32, '2-3', 'Village'),
    (33, 39, '3-1', 'Castle'),
    (40, 45, '3-2', 'Castle'),
    (46, 48, '3-3', 'Castle'),
    (49, 52, '3-4', 'Castle'),
    (53, 70, '4-1', 'Castle'),
    (71, 74, '4-2', 'Castle'),
    (75, 78, '4-3', 'Castle'),
    (79, 82, '4-4', 'Castle'),
    (83, 98, '5-1', 'Island'),
    (99, 105, '5-2', 'Island'),
    (106, 112, '5-3', 'Island'),
    (113, 119, '5-4', 'Island'),
    (120, 123, '6-1', 'Island');


DROP TABLE IF EXISTS _cfg_splits_per_area;
CREATE TABLE _cfg_splits_per_area(sort INT, number_of_splits INT, area TEXT);

INSERT INTO _cfg_splits_per_area(sort, number_of_splits, area)
VALUES
	(1, 32, 'Village'),
	(2, 50, 'Castle'),
	(3, 41, 'Island');


DROP TABLE IF EXISTS _cfg_rng_pattern_rules;
CREATE TABLE _cfg_rng_pattern_rules(split_index INT, pattern_type TEXT, pattern_name TEXT, min_time INTERVAL, max_time INTERVAL);

INSERT INTO _cfg_rng_pattern_rules(split_index, pattern_type, pattern_name, min_time, max_time)
VALUES
    (14, 'Del Lago', '1. No Dive', '0'::INTERVAL, '1:36.0'::INTERVAL),
    (14, 'Del Lago', '2. Late Dive', '1:36.001'::INTERVAL, '1:42.0'::INTERVAL),
    (14, 'Del Lago', '3. Early Dive', '1:42.001'::INTERVAL, '999:59:59'::INTERVAL),

    (26, 'Cabin', '1. Great Cabin', '0'::INTERVAL, '1:53.0'::INTERVAL),
    (26, 'Cabin', '2. Good Cabin', '1:53.001'::INTERVAL, '1:58.0'::INTERVAL),
    (26, 'Cabin', '3. Average Cabin', '1:58.001'::INTERVAL, '2:03.0'::INTERVAL),
    (26, 'Cabin', '4. Bad Cabin', '2:03.001'::INTERVAL, '2:10.0'::INTERVAL),
    (26, 'Cabin', '5. Terrible Cabin', '2:10.001'::INTERVAL, '999:59:59'::INTERVAL),

    (30, 'Mendez', '1. Fast Mendez', '0'::INTERVAL, '54.5'::INTERVAL),
    (30, 'Mendez', '2. Medium Mendez', '54.501'::INTERVAL, '57'::INTERVAL),
    (30, 'Mendez', '3. Slow Mendez', '57.001'::INTERVAL, '999:59:59'::INTERVAL),

    (38, 'Water Hall', '1. Great Water Hall', '0'::INTERVAL, '3:16.0'::INTERVAL),
    (38, 'Water Hall', '2. Good Water Hall', '3:16.001'::INTERVAL, '3:19.0'::INTERVAL),
    (38, 'Water Hall', '3. Average Water Hall', '3:19.001'::INTERVAL, '3:22.0'::INTERVAL),
    (38, 'Water Hall', '4. Bad Water Hall', '3:22.001'::INTERVAL, '3:25.0'::INTERVAL),
    (38, 'Water Hall', '5. Terrible Water Hall', '3:25.001'::INTERVAL, '999:59:59'::INTERVAL),

    (41, 'Novis 1', '1. Great Novis 1', '0'::INTERVAL, '1:22.0'::INTERVAL),
    (41, 'Novis 1', '2. Good Novis 1', '1:22.001'::INTERVAL, '1:24.0'::INTERVAL),
    (41, 'Novis 1', '3. Average Novis 1', '1:24.001'::INTERVAL, '1:26.0'::INTERVAL),
    (41, 'Novis 1', '4. Bad Novis 1', '1:26.001'::INTERVAL, '1:28.0'::INTERVAL),
    (41, 'Novis 1', '5. Terrible Novis 1', '1:28.001'::INTERVAL, '999:59:59'::INTERVAL),

    (43, 'Gallery', '1. Great Gallery', '0'::INTERVAL, '1:42.0'::INTERVAL),
    (43, 'Gallery', '2. Good Gallery', '1:42.001'::INTERVAL, '1:45.0'::INTERVAL),
    (43, 'Gallery', '3. Average Gallery', '1:45.001'::INTERVAL, '1:48.0'::INTERVAL),
    (43, 'Gallery', '4. Bad Gallery', '1:48.001'::INTERVAL, '1:50.0'::INTERVAL),
    (43, 'Gallery', '5. Terrible Gallery', '1:50.001'::INTERVAL, '999:59:59'::INTERVAL),

    (64, 'Novis 2', '1. Great Novis 2', '0'::INTERVAL, '33.5'::INTERVAL),
    (64, 'Novis 2', '2. Good Novis 2', '33.501'::INTERVAL, '35'::INTERVAL),
    (64, 'Novis 2', '3. Average Novis 2', '35.001'::INTERVAL, '38'::INTERVAL),
    (64, 'Novis 2', '4. Bad Novis 2', '38.001'::INTERVAL, '40'::INTERVAL),
    (64, 'Novis 2', '5. Terrible Novis 2', '40.001'::INTERVAL, '999:59:59'::INTERVAL),

    (65, 'Catapult', '1. Perfect Catapult', '0'::INTERVAL, '31'::INTERVAL),
    (65, 'Catapult', '2. Stagger Catapult', '31.001'::INTERVAL, '33'::INTERVAL),
    (65, 'Catapult', '3. Hit Catapult', '33.001'::INTERVAL, '999:59:59'::INTERVAL),

    (74, 'Novis 3', '1. Great Novis 3', '0'::INTERVAL, '1:17.0'::INTERVAL),
    (74, 'Novis 3', '2. Good Novis 3', '1:17.001'::INTERVAL, '1:19.0'::INTERVAL),
    (74, 'Novis 3', '3. Average Novis 3', '1:19.001'::INTERVAL, '1:22.0'::INTERVAL),
    (74, 'Novis 3', '4. Bad Novis 3', '1:22.001'::INTERVAL, '1:25.0'::INTERVAL),
    (74, 'Novis 3', '5. Terrible Novis 3', '1:25.001'::INTERVAL, '999:59:59'::INTERVAL),

    (110, 'U3', '1. Great U3', '0'::INTERVAL, '1:35.5'::INTERVAL),
    (110, 'U3', '2. Good U3', '1:35.501'::INTERVAL, '1:39.0'::INTERVAL),
    (110, 'U3', '3. Average U3', '1:39.001'::INTERVAL, '1:41.0'::INTERVAL),
    (110, 'U3', '4. Bad U3', '1:41.001'::INTERVAL, '1:43.0'::INTERVAL),
    (110, 'U3', '5. Terrible U3', '1:43.001'::INTERVAL, '999:59:59'::INTERVAL),

    (112, 'Krauser', '1. Great Krauser', '0'::INTERVAL, '2:19.0'::INTERVAL),
    (112, 'Krauser', '2. Good Krauser', '2:19.001'::INTERVAL, '2:22.0'::INTERVAL),
    (112, 'Krauser', '3. Average Krauser', '2:22.001'::INTERVAL, '2:25.0'::INTERVAL),
    (112, 'Krauser', '4. Bad Krauser', '2:25.001'::INTERVAL, '2:28.0'::INTERVAL),
    (112, 'Krauser', '5. Terrible Krauser', '2:28.001'::INTERVAL, '999:59:59'::INTERVAL),

    (113, 'War Room', '1. Great War Room', '0'::INTERVAL, '1:51.0'::INTERVAL),
    (113, 'War Room', '2. Good War Room', '1:51.001'::INTERVAL, '1:54.0'::INTERVAL),
    (113, 'War Room', '3. Average War Room', '1:54.001'::INTERVAL, '1:57.0'::INTERVAL),
    (113, 'War Room', '4. Bad War Room', '1:57.001'::INTERVAL, '2:00.0'::INTERVAL),
    (113, 'War Room', '5. Terrible War Room', '2:00.001'::INTERVAL, '999:59:59'::INTERVAL),

    (117, 'Key Card', '1. Great Key Card', '0'::INTERVAL, '55'::INTERVAL),
    (117, 'Key Card', '2. Good Key Card', '55.001'::INTERVAL, '57'::INTERVAL),
    (117, 'Key Card', '3. Average Key Card', '57.001'::INTERVAL, '59'::INTERVAL),
    (117, 'Key Card', '4. Bad Key Card', '59.001'::INTERVAL, '1:01.0'::INTERVAL),
    (117, 'Key Card', '5. Terrible Key Card', '1:01.001'::INTERVAL, '999:59:59'::INTERVAL);


/* All the dates between 2000 and 2030. */

DROP TABLE IF EXISTS _cfg_dates;
CREATE TABLE _cfg_dates AS
SELECT GENERATE_SERIES(
    '2000-01-01'::DATE,
    '2030-12-31'::DATE,
    '1 day'::INTERVAL
)::DATE AS dt;