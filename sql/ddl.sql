-- We are declaring the return type to be queue_classic_jobs.
-- This is ok since I am assuming that all of the users added queues will
-- have identical columns to queue_classic_jobs.
-- When QC supports queues with columns other than the default, we will have to change this.

CREATE OR REPLACE FUNCTION lock_head(queue_name varchar)
RETURNS SETOF queue_classic_jobs AS $$
BEGIN
  RETURN QUERY EXECUTE 'UPDATE queue_classic_jobs '
    || 'SET locked_at = now(), '
    || 'locked_by = pg_backend_pid() '
    || 'WHERE id IN ( '
      || 'SELECT id FROM queue_classic_jobs '
      || 'WHERE locked_at IS NULL AND q_name = $1 AND  scheduled_at <= now() '
      || 'LIMIT 1 '
      || 'FOR NO KEY UPDATE SKIP LOCKED '
    || ') RETURNING *;' USING queue_name;
END
$$ LANGUAGE plpgsql;

-- queue_classic_notify function and trigger
CREATE FUNCTION queue_classic_notify() RETURNS TRIGGER AS $$ BEGIN
  perform pg_notify(new.q_name, ''); RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER queue_classic_notify
AFTER INSERT ON queue_classic_jobs FOR EACH ROW
EXECUTE PROCEDURE queue_classic_notify();
