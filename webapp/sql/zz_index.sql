-- 計測 #01（BOTTLENECK_RESULT_01.md）で判明したボトルネックへの対処。
-- docker-entrypoint-initdb.d は名前順に実行されるため、dump.sql.bz2 の後に流れるよう zz_ で始めている。
USE `isuconp`;

-- DB 実行時間の 97.3% が comments への `WHERE post_id = ?` のフルスキャン（1回あたり 97,660 行走査）だった。
--   SELECT * FROM comments WHERE post_id = ? ORDER BY created_at DESC LIMIT 3  … 65.3%
--   SELECT COUNT(*) FROM comments WHERE post_id = ?                            … 25.9%
--   SELECT * FROM comments WHERE post_id = ? ORDER BY created_at DESC          …  6.1%
-- created_at を第2キーに含めることで ORDER BY のソートも省ける。
ALTER TABLE comments ADD INDEX idx_post_id_created_at (post_id, created_at);

-- 計測 #02 で残っていたフルスキャン。/@{accountName} が発行する
--   SELECT COUNT(*) AS count FROM comments WHERE user_id = ?   … DB 時間の 7.0%
-- が1回あたり 100,065 行（comments 全件）を走査していた。
-- COUNT だけなので created_at を足す必要はない。
ALTER TABLE comments ADD INDEX idx_user_id (user_id);
