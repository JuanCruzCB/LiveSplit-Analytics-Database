/* Default split names for the game. TODO: This needs to be customizable. */

DROP TABLE IF EXISTS cfg_default_split_names;
CREATE TABLE cfg_default_split_names(split_index INT, split_name TEXT);

INSERT INTO cfg_default_split_names(split_index, split_name)
VALUES
	(1, '-Start'),
	(2, '-Village'),
	(3, '-Farm'),
	(4, '{1-1} Boulder'),
	(5, '-Canyon'),
	(6, '-Factory'),
	(7, '{1-2} Enter House'),
	(8, '-Exit House'),
	(9, '-Village 2'),
	(10, '-Underground'),
	(11, '-Graveyard'),
	(12, '-Crows'),
	(13, '-Swamp'),
	(14, '{1-3} Del Lago'),
	(15, '-Wake Up'),
	(16, '-Waterfall'),
	(17, '-Boat Ride'),
	(18, '-El Gigante'),
	(19, '-Dogs'),
	(20, '{2-1} Church'),
	(21, '-Ashley'),
	(22, '-Graveyard 2'),
	(23, '-Underground 2'),
	(24, '-Village 3'),
	(25, '-Farm 2'),
	(26, '{2-2} Cabin'),
	(27, '-Lever'),
	(28, '-El Gigante 2'),
	(29, '-Gondola'),
	(30, '-Mendez'),
	(31, '-Gondola 2'),
	(32, '{2-3} Truck'),
	(33, '-Enter Castle'),
	(34, '-Catapults'),
	(35, '-Swords Room'),
	(36, '-Castle Key'),
	(37, '-Garrador'),
	(38, '-Water Hall'),
	(39, '{3-1} Ceremony Room'),
	(40, '-Ceremony Room'),
	(41, '-Novistadors 1'),
	(42, '-Ceremony Room 2'),
	(43, '-Gallery'),
	(44, '-Fountain'),
	(45, '{3-2} Maze'),
	(46, '-Bedroom'),
	(47, '-Cage'),
	(48, '{3-3} Bridge'),
	(49, '-Save Ashley'),
	(50, '-Cranks'),
	(51, '-Puzzle'),
	(52, '{3-4} Exit'),
	(53, '-Reunited'),
	(54, '-Cart Room'),
	(55, '-Lava Room'),
	(56, '-Cart Room 2'),
	(57, '-Chimera Wall'),
	(58, '-Cart Room 3'),
	(59, '-Hallway'),
	(60, '-Queen''s Grail'),
	(61, '-Hallway 2'),
	(62, '-King''s Grail'),
	(63, '-Hallway 3'),
	(64, '-Novistadors 2'),
	(65, '-Catapults 2'),
	(66, '-Clock Tower'),
	(67, '-Bridge'),
	(68, '-Garradors'),
	(69, '-Striker'),
	(70, '{4-1} Verdugo'),
	(71, '-Merchant'),
	(72, '-Boulder'),
	(73, '-El Gigantes'),
	(74, '{4-2} Novistadors 3'),
	(75, '-Ruins'),
	(76, '-Enter Mines'),
	(77, '-Minecart'),
	(78, '{4-3} Emblem'),
	(79, '-Salazar Statue'),
	(80, '-Elevator'),
	(81, '-Salazar'),
	(82, '{4-4} Exit'),
	(83, '-Enter Island'),
	(84, '-Outside Facility'),
	(85, '-Oven Man'),
	(86, '-Monitor Room'),
	(87, '-Garage Door'),
	(88, '-Hallway 4'),
	(89, '-Regenerator'),
	(90, '-Hallway 5'),
	(91, '-Freezer'),
	(92, '-Hallway 6'),
	(93, '-Trash Room'),
	(94, '-Cell'),
	(95, '-Stairs Room'),
	(96, '-Iron Maiden'),
	(97, '-Stairs Room 2'),
	(98, '{5-1} Cell'),
	(99, '-Ashley''s Back'),
	(100, '-Observation Room'),
	(101, '-Iron Maidens'),
	(102, '-Wrecking Ball'),
	(103, '-Regenerators'),
	(104, '-Truck'),
	(105, '{5-2} Merchant'),
	(106, '-Ceremony Room 3'),
	(107, '-Krauser'),
	(108, '-Lasers'),
	(109, '-Cave'),
	(110, '-U-3'),
	(111, '-Tents'),
	(112, '{5-3} Krauser'),
	(113, '-Military Area'),
	(114, '-RIP Mike'),
	(115, '-Ruins 2'),
	(116, '-Jail'),
	(117, '-Key Card'),
	(118, '-Ashley Again'),
	(119, '{5-4} Plaga Removal'),
	(120, '-Exit'),
	(121, '-Construction Site'),
	(122, '-Saddler'),
	(123, '{End} Jetski');


DROP TABLE IF EXISTS cfg_chapter_area_splits_from_to;
CREATE TABLE cfg_chapter_area_splits_from_to(from_split_index INT, to_split_index INT, chapter TEXT, area TEXT);

INSERT INTO cfg_chapter_area_splits_from_to(from_split_index, to_split_index, chapter, area)
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


DROP TABLE IF EXISTS cfg_splits_per_area;
CREATE TABLE cfg_splits_per_area(sort INT, number_of_splits INT, area TEXT);

INSERT INTO cfg_splits_per_area(sort, number_of_splits, area)
VALUES
	(1, 32, 'Village'),
	(2, 50, 'Castle'),
	(3, 41, 'Island');


DROP TABLE IF EXISTS cfg_rng_pattern_rules;
CREATE TABLE cfg_rng_pattern_rules(split_index INT, pattern_type TEXT, pattern_name TEXT, min_time INTERVAL, max_time INTERVAL);

INSERT INTO cfg_rng_pattern_rules(split_index, pattern_type, pattern_name, min_time, max_time)
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

DROP TABLE IF EXISTS cfg_dates;
CREATE TABLE cfg_dates AS
SELECT(GENERATE_SERIES(DATE '2000-01-01', DATE '2030-12-31', INTERVAL '1 day'))::DATE AS dt;