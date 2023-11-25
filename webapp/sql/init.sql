TRUNCATE TABLE themes;
TRUNCATE TABLE icons;
TRUNCATE TABLE reservation_slots;
TRUNCATE TABLE livestream_viewers_history;
TRUNCATE TABLE livecomment_reports;
TRUNCATE TABLE ng_words;
TRUNCATE TABLE reactions;
TRUNCATE TABLE tags;
TRUNCATE TABLE livestream_tags;
TRUNCATE TABLE livecomments;
TRUNCATE TABLE livestreams;
TRUNCATE TABLE users;

ALTER TABLE `themes` auto_increment = 1;
ALTER TABLE `icons` auto_increment = 1;
ALTER TABLE `reservation_slots` auto_increment = 1;
ALTER TABLE `livestream_tags` auto_increment = 1;
ALTER TABLE `livestream_viewers_history` auto_increment = 1;
ALTER TABLE `livecomment_reports` auto_increment = 1;
ALTER TABLE `ng_words` auto_increment = 1;
ALTER TABLE `reactions` auto_increment = 1;
ALTER TABLE `tags` auto_increment = 1;
ALTER TABLE `livecomments` auto_increment = 1;
ALTER TABLE `livestreams` auto_increment = 1;
ALTER TABLE `users` auto_increment = 1;


-- ユーザーの統計情報
CREATE TABLE IF NOT EXISTS `user_statistics` (
  `user_id` BIGINT NOT NULL PRIMARY KEY,
  `reactions` BIGINT NOT NULL,
  `viewers` BIGINT NOT NULL,
  `comments` BIGINT NOT NULL,
  `tips` BIGINT NOT NULL
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_bin; -- おまじない


CREATE TRIGGER reactions_inc BEFORE INSERT ON reactions
  FOR EACH ROW
  BEGIN
    INSERT INTO user_statistics (user_id, reactions, comments, tips, views)
        VALUES (NEW.user_id, 1, 0, 0, 0) AS v
        ON DUPLICATE KEY UPDATE
            reactions = reactions + 1;
  END;

CREATE TRIGGER reactions_dec BEFORE DELETE ON reactions
  FOR EACH ROW
  BEGIN
    UPDATE user_statistics SET reactions = reactions - 1;
  END;

CREATE TRIGGER viewers_inc BEFORE INSERT ON livestream_viewers_history
  FOR EACH ROW
  BEGIN
    INSERT INTO user_statistics (user_id, reactions, comments, tips, views)
        VALUES (NEW.user_id, 0, 0, 0, 1) AS v
        ON DUPLICATE KEY UPDATE
            viewers = viewers + 1;
  END;

CREATE TRIGGER viewers_dec BEFORE DELETE ON livestream_viewers_history
  FOR EACH ROW
  BEGIN
    UPDATE user_statistics SET viewers = viewers - 1;
  END;

CREATE TRIGGER comments_tips_inc BEFORE INSERT ON livecomments
  FOR EACH ROW
  BEGIN
    INSERT INTO user_statistics (user_id, reactions, comments, tips, views)
        VALUES (NEW.user_id, 0, 1, NEW.tip, 0) AS v
        ON DUPLICATE KEY UPDATE
            comments = comments + 1,
            tips = tips + NEW.tip;
  END;

CREATE TRIGGER comments_tips_dec BEFORE DELETE ON livecomments
  FOR EACH ROW
  BEGIN
    UPDATE user_statistics SET comments = comments - 1, tips = tips - NEW.tip;
  END;

