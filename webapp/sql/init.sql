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
    INSERT INTO user_statistics (user_id, reactions, comments, tips, viewers)
        VALUES (NEW.user_id, 1, 0, 0, 0) AS v
        ON DUPLICATE KEY UPDATE
            reactions = reactions + 1;

CREATE TRIGGER reactions_dec BEFORE DELETE ON reactions
  FOR EACH ROW
    UPDATE user_statistics SET reactions = reactions - 1;

CREATE TRIGGER viewers_inc BEFORE INSERT ON livestream_viewers_history
  FOR EACH ROW
    INSERT INTO user_statistics (user_id, reactions, comments, tips, viewers)
        VALUES (NEW.user_id, 0, 0, 0, 1) AS v
        ON DUPLICATE KEY UPDATE
            viewers = viewers + 1;

CREATE TRIGGER viewers_dec BEFORE DELETE ON livestream_viewers_history
  FOR EACH ROW
    UPDATE user_statistics SET viewers = viewers - 1;

CREATE TRIGGER comments_tips_inc BEFORE INSERT ON livecomments
  FOR EACH ROW
    INSERT INTO user_statistics (user_id, reactions, comments, tips, viewers)
        VALUES (NEW.user_id, 0, 1, NEW.tip, 0) AS v
        ON DUPLICATE KEY UPDATE
            comments = comments + 1,
            tips = tips + NEW.tip;

CREATE TRIGGER comments_tips_dec BEFORE DELETE ON livecomments
  FOR EACH ROW
    UPDATE user_statistics SET comments = comments - 1, tips = tips - OLD.tip;

-- added by hand
-- CREATE INDEX idx_icon_user ON icons (user_id);
-- CREATE INDEX idx_theme_user ON themes (user_id);
-- CREATE INDEX idx_livestream_user_id ON livestreams (user_id);
-- CREATE INDEX idx_reservation_slots ON reservation_slots (start_at, end_at);
-- CREATE INDEX idx_livestream_tags_stream ON livestream_tags (livestream_id);
-- CREATE INDEX idx_livecomments ON livecomments (livestream_id, created_at);
-- CREATE INDEX idx_ng_words ON ng_words (user_id, livestream_id);
-- CREATE INDEX idx_reactions ON reactions (livestream_id);
