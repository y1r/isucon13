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
  `user_name` VARCHAR(255) NOT NULL,
  `reactions_total` BIGINT NOT NULL,
  `viewers` BIGINT NOT NULL,
  `comments` BIGINT NOT NULL,
  `tips` BIGINT NOT NULL
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_bin; -- おまじない

-- added by hand
-- CREATE INDEX idx_user_statistics ON user_statistics (user_name);
TRUNCATE TABLE user_statistics;

-- ユーザー追加時に統計情報のテーブルも作る
CREATE TRIGGER IF NOT EXISTS add_users_to_statistics BEFORE INSERT ON users
  FOR EACH ROW
    INSERT INTO user_statistics (user_id, user_name, reactions_total, comments, tips, viewers)
        VALUES (NEW.id, NEW.name, 0, 0, 0, 0);

CREATE TRIGGER IF NOT EXISTS reactions_inc BEFORE INSERT ON reactions
  FOR EACH ROW
    UPDATE user_statistics
      SET reactions_total = reactions_total + 1
      WHERE user_id IN (SELECT user_id FROM livestreams WHERE id = NEW.livestream_id);

CREATE TRIGGER IF NOT EXISTS reactions_dec BEFORE DELETE ON reactions
  FOR EACH ROW
    UPDATE user_statistics
      SET reactions_total = reactions_total - 1
      WHERE user_id IN (SELECT user_id FROM livestreams WHERE id = OLD.livestream_id);

CREATE TRIGGER IF NOT EXISTS viewers_inc BEFORE INSERT ON livestream_viewers_history
  FOR EACH ROW
    UPDATE user_statistics
      SET viewers = viewers + 1
      WHERE user_id IN (SELECT user_id FROM livestreams WHERE id = NEW.livestream_id);

CREATE TRIGGER IF NOT EXISTS viewers_dec BEFORE DELETE ON livestream_viewers_history
  FOR EACH ROW
    UPDATE user_statistics
      SET viewers = viewers - 1
      WHERE user_id IN (SELECT user_id FROM livestreams WHERE id = OLD.livestream_id);

CREATE TRIGGER IF NOT EXISTS comments_tips_inc BEFORE INSERT ON livecomments
  FOR EACH ROW
    UPDATE user_statistics
      SET comments = comments + 1, tips = tips + NEW.tip
      WHERE user_id IN (SELECT user_id FROM livestreams WHERE id = NEW.livestream_id);

CREATE TRIGGER IF NOT EXISTS comments_tips_dec BEFORE DELETE ON livecomments
  FOR EACH ROW
    UPDATE user_statistics
      SET comments = comments - 1, tips = tips - OLD.tip
      WHERE user_id IN (SELECT user_id FROM livestreams WHERE id = OLD.livestream_id);

-- added by hand
-- CREATE INDEX idx_icon_user ON icons (user_id);
-- CREATE INDEX idx_theme_user ON themes (user_id);
-- CREATE INDEX idx_livestream_user_id ON livestreams (user_id);
-- CREATE INDEX idx_reservation_slots ON reservation_slots (start_at, end_at);
-- CREATE INDEX idx_livestream_tags_stream ON livestream_tags (livestream_id);
-- CREATE INDEX idx_livecomments ON livecomments (livestream_id, created_at);
-- CREATE INDEX idx_ng_words ON ng_words (user_id, livestream_id);
-- CREATE INDEX idx_reactions ON reactions (livestream_id);
