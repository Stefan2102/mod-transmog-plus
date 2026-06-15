SET
@Entry = 190012,
@Name = "Warpweaver";

DELETE FROM `creature_template` WHERE `entry` = @Entry;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `rank`, `dmgschool`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `AIName`, `MovementType`, `HoverHeight`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`) VALUES
(@Entry, @Name, "Transmogrifier", NULL, 0, 80, 80, 2, 35, 1, 0, 0, 2000, 0, 1, 0, 7, 138936390, 0, 0, 0, '', 0, 1, 0, 0, 1, 0, 0, 'npc_transmogrifier');

DELETE FROM `creature_template_model` WHERE `CreatureID` = @Entry;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(@Entry, 0, 19646, 1, 1, 0);

DELETE FROM `creature_template_locale` WHERE `entry` = @Entry;
INSERT INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`) VALUES
(@Entry, 'koKR', @Name, "변형기"),
(@Entry, 'frFR', @Name, "Transmogrificateur"),
(@Entry, 'deDE', @Name, "Transmogrifier"),
(@Entry, 'zhCN', @Name, "变形者"),
(@Entry, 'zhTW', @Name, "幻化大師"),
(@Entry, 'esES', @Name, "Transfigurador"),
(@Entry, 'esMX', @Name, "Transfigurador"),
(@Entry, 'ruRU', @Name, "Трансмогрификатор");

SET @GREETING := 601084;
DELETE FROM `npc_text` WHERE `ID` = @GREETING;
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES
(@GREETING, 'Greetings, $N. Do you wish to alter the appearance of your equipment?');

DELETE FROM `module_string` WHERE `module` = 'mod-transmog';
INSERT INTO `module_string` (`module`, `id`, `string`) VALUES
('mod-transmog', 1, 'Slot transmogrified.'),
('mod-transmog', 2, 'Equipment slot is empty.'),
('mod-transmog', 3, 'Invalid source item.'),
('mod-transmog', 4, 'All slot transmogs removed.'),
('mod-transmog', 5, 'Slot hidden.'),
('mod-transmog', 6, 'Slot transmog removed.'),
('mod-transmog', 7, 'You do not have enough money.'),
('mod-transmog', 8, 'Remove all transmogs'),
('mod-transmog', 9, 'Remove all slot transmogs?'),
('mod-transmog', 10, 'Back...'),
('mod-transmog', 11, 'Hide slot'),
('mod-transmog', 12, 'Remove transmog from slot'),
('mod-transmog', 13, 'Next Page'),
('mod-transmog', 14, 'Previous Page'),
('mod-transmog', 15, 'No valid appearances found for this slot.'),
('mod-transmog', 16, 'This item\'s appearance has been added to your collection.'),
('mod-transmog', 17, 'Free');

DELETE FROM `creature` WHERE (`id1` = 190012);
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9000000, 190012, 0, 0, 1, 0, 0, 1, 1, 0, 1542.61, -4372.89, 0.617466, 6.12055, 300, 0, 0, 12600, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9000001, 190012, 0, 0, 0, 0, 0, 1, 1, 0, -8805.33, 622.176, 94.8956, 2.27093, 300, 0, 0, 12600, 0, 0, 0, 0, 0, '', NULL, 0, NULL);