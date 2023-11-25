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

-- added by hand
-- CREATE INDEX idx_icon_user ON icons (user_id);
-- CREATE INDEX idx_theme_user ON themes (user_id);
-- CREATE INDEX idx_livestream_user_id ON livestreams (user_id);
-- CREATE INDEX idx_reservation_slots ON reservation_slots (start_at, end_at);
-- CREATE INDEX idx_livestream_tags_stream ON livestream_tags (livestream_id);
-- CREATE INDEX idx_livecomments ON livecomments (livestream_id, created_at);
-- CREATE INDEX idx_reactions ON reactions (livestream_id);