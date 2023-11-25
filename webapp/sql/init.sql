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
  `reactions_total` BIGINT NOT NULL,
  `viewers` BIGINT NOT NULL,
  `comments` BIGINT NOT NULL,
  `tips` BIGINT NOT NULL
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_bin; -- おまじない

TRUNCATE TABLE user_statistics;

-- ユーザー追加時に統計情報のテーブルも作る
CREATE TRIGGER IF NOT EXISTS add_users_to_statistics BEFORE INSERT ON users
  FOR EACH ROW
    INSERT INTO user_statistics (user_id, reactions_total, comments, tips, viewers)
        VALUES (NEW.user_id, 0, 0, 0, 0);

CREATE TRIGGER IF NOT EXISTS reactions_inc BEFORE INSERT ON reactions
  FOR EACH ROW
    UPDATE
      SET US.reactions_total = US.reactions_total + 1
      FROM livestreams AS L
           INNER JOIN user_statistics AS US
           ON L.user_id = US.user_id
      WHERE L.id = NEW.livestream_id;

CREATE TRIGGER IF NOT EXISTS reactions_dec BEFORE DELETE ON reactions
  FOR EACH ROW
    UPDATE
      SET US.reactions_total = US.reactions_total - 1
      FROM livestreams AS L
           INNER JOIN user_statistics AS US
           ON L.user_id = US.user_id
      WHERE L.id = OLD.livestream_id;

CREATE TRIGGER IF NOT EXISTS viewers_inc BEFORE INSERT ON livestream_viewers_history
  FOR EACH ROW
    UPDATE
      SET US.viewers = US.viewers + 1
      FROM livestreams AS L
           INNER JOIN user_statistics AS US
           ON L.user_id = US.user_id
      WHERE L.id = NEW.livestream_id;

CREATE TRIGGER IF NOT EXISTS viewers_dec BEFORE DELETE ON livestream_viewers_history
  FOR EACH ROW
    UPDATE
      SET US.viewers = US.viewers - 1
      FROM livestreams AS L
           INNER JOIN user_statistics AS US
           ON L.user_id = US.user_id
      WHERE L.id = OLD.livestream_id;

CREATE TRIGGER IF NOT EXISTS comments_tips_inc BEFORE INSERT ON livecomments
  FOR EACH ROW
    UPDATE
      SET US.comments = US.comments + 1,
          US.tips = US.tips + NEW.tip
      FROM livestreams AS L
           INNER JOIN user_statistics AS US
           ON L.user_id = US.user_id
      WHERE L.id = NEW.livestream_id;

CREATE TRIGGER IF NOT EXISTS comments_tips_dec BEFORE DELETE ON livecomments
  FOR EACH ROW
    UPDATE
      SET US.comments = US.comments - 1,
          US.tips = US.tips - OLD.tip
      FROM livestreams AS L
           INNER JOIN user_statistics AS US
           ON L.user_id = US.user_id
      WHERE L.id = OLD.livestream_id;

-- added by hand
-- CREATE INDEX idx_icon_user ON icons (user_id);
-- CREATE INDEX idx_theme_user ON themes (user_id);
-- CREATE INDEX idx_livestream_user_id ON livestreams (user_id);
-- CREATE INDEX idx_reservation_slots ON reservation_slots (start_at, end_at);
-- CREATE INDEX idx_livestream_tags_stream ON livestream_tags (livestream_id);
-- CREATE INDEX idx_livecomments ON livecomments (livestream_id, created_at);
-- CREATE INDEX idx_ng_words ON ng_words (user_id, livestream_id);
-- CREATE INDEX idx_reactions ON reactions (livestream_id);
